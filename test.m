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

%%

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
% load(fullfile(sequencePath,temporalSuperPixelsFile),'temporalSP');
locationModel=load(fullfile(locationModelPath,...
                int2str(classIndex),locationModelFile),'locationProbMap');
locationModel=locationModel.locationProbMap;

addpath(optimizationSolverPath);
addpath(fastSegUtilPath);

%%

[ uniqueSuperPixels, ~, ~, superpixelsNum ] = ...
    makeSuperpixelIndexUnique( superPixels );

unaryTerm=zeros(partsNum+1,superpixelsNum);
for frame=1:length(uniqueSuperPixels)
    
    SPs=unique(uniqueSuperPixels{frame});
    
    foregroundMask=segments{frame};
    if nnz(foregroundMask)==0 
        unaryTerm(1:partsNum,SPs)=1;
        unaryTerm(partsNum+1,SPs)=0;
        continue;
    end
    
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
    disp(frame);
end

%%

imgs=readFrames( fileSettings,classIndex,sequenceIndex);

[ colours, centres, ~ ] = ...
    getSuperpixelStats( imgs, uniqueSuperPixels, superpixelsNum );

pairPotentials = computePairwisePotentials( parameterSettings,...
          uniqueSuperPixels,flow, colours, centres, superpixelsNum);


edgeCoefficients=sparse(double(pairPotentials.source),...
        double(pairPotentials.destination),double(pairPotentials.value),...
        superpixelsNum,superpixelsNum);
    
labelDependencies=ones(partsNum+1,partsNum+1);
labelDependencies=labelDependencies-diag(ones(1,partsNum+1));
    
fprintf('Energy function constructed... ');toc
tic;   
      
[spLabels, ~]=mrfMinimizeMex(unaryTerm,edgeCoefficients,labelDependencies);

%%

partsSegmentation={};
for frame=1:length(uniqueSuperPixels)
    SPs=unique(uniqueSuperPixels{frame});
    spsMap=uniqueSuperPixels{frame};
    for sp=SPs'
        spsMap(spsMap==sp)=spLabels(sp);
    end
    partsSegmentation{frame}=spsMap;
end

fprintf('Parts segmentation generated for sequence %d class %d... ',...
        sequenceIndex,classIndex);
toc

outputPath=fullfile(partsSegmentationPath,int2str(classIndex),...
                    int2str(sequenceIndex),partsSegmentationFile);
save(outputPath,'partsSegmentation');
