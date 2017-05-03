function [ partsSegmentation ] = ...
    videoSegmentParts( fileSettings, parameterSettings, ...
                       classIndex,sequenceIndex)
%   Get parts segmentation using optimization method
%--Input--
%   fileSettings: ...
%   parameterSettings: ...
%   classIndex: For which class to compute parts segmentation
%   sequenceIndex: For which sequence to compute parts segmentation
%--Output--
%   partsSegmentation: Parts segmentation result. (Saved to file)

%% Get Settings

dataPath = fileSettings.dataPath;
segmentsFile=fileSettings.segmentsFile;
superPixelsFile=fileSettings.superPixelsFile;
partsSegmentationFile=fileSettings.partsSegmentationFile;
partsSegmentationPath=fileSettings.partsSegmentationPath;
locationModelPath=fileSettings.locationModelPath;
locationModelFile=fileSettings.locationModelFile;
opticalFlowFile=fileSettings.opticalFlowFile;

optimizationSolverPath=fileSettings.optimizationSolverPath;
fastSegUtilPath=fileSettings.fastSegUtilPath;

partsNum=parameterSettings.partsNum;
foregroundSPCriteria=parameterSettings.foregroundSPCriteria;

%% Load data

tic;
classes=dir(dataPath);
classes=classes(~ismember({classes.name},{'.','..'}));      % Remove . and ..
classPath=fullfile(dataPath, classes(classIndex).name);

sequences=dir(classPath);
sequences=sequences(~ismember({sequences.name},{'.','..'}));     % Remove . and ..
sequencePath=fullfile(classPath,sequences(sequenceIndex).name);

load(fullfile(sequencePath,superPixelsFile),'superPixels');
load(fullfile(sequencePath,segmentsFile),'segments');
load(fullfile(sequencePath,opticalFlowFile),'flow');
locationModel=load(fullfile(locationModelPath,...
                int2str(classIndex),locationModelFile),'locationProbMap');
locationModel=locationModel.locationProbMap;

addpath(optimizationSolverPath);
addpath(fastSegUtilPath);


%% Extract foreground superpixels

foregroundSuperPixels=cell(length(superPixels),1);
for frame=1:length(superPixels)
    
    foregroundSPIndex=2;
    foregroundMask=segments{frame};
    foregroundMask=bwareafilt(foregroundMask,1);
    SPs=unique(superPixels{frame});
    
    temp=superPixels{frame};
    
    for sp=SPs'
        spMap=superPixels{frame};
        spMap(spMap~=sp)=0;
        
        if nnz(and(spMap,foregroundMask))>nnz(spMap)*foregroundSPCriteria
            temp(superPixels{frame}==sp)=foregroundSPIndex;
            foregroundSPIndex=foregroundSPIndex+1;
        else
            temp(superPixels{frame}==sp)=1;
        end
    end
    
    foregroundSuperPixels{frame}=temp;
end

fprintf('Foreground superpixels extracted... ');toc
tic; 


%% Computed unary term (Location term)

[ uniqueSuperPixels, superpixelFrameIDs, ~, superpixelsNum ] = ...
    makeSuperpixelIndexUnique( foregroundSuperPixels );

unaryTerm=zeros(partsNum+1,superpixelsNum);
for frame=1:length(uniqueSuperPixels)
    
    SPs=unique(uniqueSuperPixels{frame});
    
    foregroundMask=segments{frame};
    if nnz(foregroundMask)==0 
        unaryTerm(1:partsNum,SPs)=1;
        unaryTerm(partsNum+1,SPs)=0;
        continue;
    end
    
    foregroundMask=bwareafilt(foregroundMask,1);
    prop=regionprops(foregroundMask);
    foregroundBB=prop.BoundingBox;
    foregroundBB=ceil(foregroundBB);
    
    bbX1=foregroundBB(1);
    bbY1=foregroundBB(2);
    bbX2=foregroundBB(1)+foregroundBB(3);
    bbY2=foregroundBB(2)+foregroundBB(4);
    bbX1=min(bbX1,size(foregroundMask,2));bbX1=max(bbX1,0);
    bbX2=min(bbX2,size(foregroundMask,2));bbX2=max(bbX2,0);
    bbY1=min(bbY1,size(foregroundMask,1));bbY1=max(bbY1,0);
    bbY2=min(bbY2,size(foregroundMask,1));bbY2=max(bbY2,0);

    resizedLocationModel=...
        imresize(locationModel,[bbY2-bbY1+1 bbX2-bbX1+1]);
    extendedLocationModel=zeros([size(foregroundMask) partsNum+1]);
    extendedLocationModel(:,:,partsNum+1)=1;

    extendedLocationModel(bbY1:bbY2,bbX1:bbX2,:)=resizedLocationModel;
    
    for sp=SPs'
        spsMap=uniqueSuperPixels{frame};
        spsMap=(spsMap==sp);
        areaSize=bwarea(spsMap);
        spProbs=extendedLocationModel.*repmat(double(spsMap),1,1,partsNum+1);
        unaryTerm(:,sp)=reshape(sum(sum(spProbs))./areaSize,[partsNum+1 1]);
        unaryTerm(:,sp)=1-unaryTerm(:,sp);
    end
end

fprintf('Unary term computed... ');toc
tic; 

%% Load imaged and shape data

imgs=readFrames( fileSettings,classIndex,sequenceIndex);
[~,cutsMask]=loadShapeData(fileSettings,segments,classIndex,sequenceIndex);

fprintf('Shape cuts data loaded... ');toc
tic; 

%% Compute pairwise terms (Shape term & Temporal term & Spatial term)

[ colours, centres, ~ ] = ...
    getSuperpixelStats( imgs, uniqueSuperPixels, superpixelsNum );

pairPotentials = computePairwisePotentials( parameterSettings,...
          uniqueSuperPixels,flow, colours, centres, superpixelsNum,...
          superpixelFrameIDs,cutsMask);
pairPotentials.source=pairPotentials.source+1;
pairPotentials.destination=pairPotentials.destination+1;

edgeCoefficients=sparse(double(pairPotentials.source),...
        double(pairPotentials.destination),double(pairPotentials.value),...
        superpixelsNum,superpixelsNum);
    
labelDependencies=ones(partsNum+1,partsNum+1);
labelDependencies=labelDependencies-diag(ones(1,partsNum+1));
    
fprintf('Energy function constructed... ');toc
tic;   
      
[spLabels, ~]=mrfMinimizeMex(unaryTerm,edgeCoefficients,labelDependencies);


%% Format result and save

partsSegmentation=cell(length(uniqueSuperPixels),1);
for frame=1:length(uniqueSuperPixels)
    SPs=unique(uniqueSuperPixels{frame});
    temp=uniqueSuperPixels{frame};
    for sp=SPs'
        temp(uniqueSuperPixels{frame}==sp)=spLabels(sp);
    end
    partsSegmentation{frame}=temp;
end

fprintf('Parts segmentation generated for sequence %d class %d... ',...
        sequenceIndex,classIndex);
toc

outputPath=fullfile(partsSegmentationPath,int2str(classIndex),...
                    int2str(sequenceIndex),partsSegmentationFile);
save(outputPath,'partsSegmentation');


end