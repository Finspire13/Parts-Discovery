function [ partsSegmentation ] = ...
    videoSegmentParts( fileSettings, parameterSettings, ...
                       classIndex,sequenceIndex)
%VIDEOSEGMENTPARTS Summary of this function goes here
%   Detailed explanation goes here
dataPath = fileSettings.dataPath;
segmentsFile=fileSettings.segmentsFile;
temporalSuperPixelsFile=fileSettings.temporalSuperPixelsFile;
partsSegmentationFile=fileSettings.partsSegmentationFile;
partsSegmentationPath=fileSettings.partsSegmentationPath;
locationModelPath=fileSettings.locationModelPath;
locationModelFile=fileSettings.locationModelFile;

partsNum=parameterSettings.partsNum;
foregroundSPCriteria=parameterSettings.foregroundSPCriteria;
%%
tic;
classes=dir(dataPath);
classes=classes(~ismember({classes.name},{'.','..'}));      % Remove . and ..
classPath=fullfile(dataPath, classes(classIndex).name);

sequences=dir(classPath);
sequences=sequences(~ismember({sequences.name},{'.','..'}));     % Remove . and ..
sequencePath=fullfile(classPath,sequences(sequenceIndex).name);

load(fullfile(sequencePath,segmentsFile),'segments');
load(fullfile(sequencePath,temporalSuperPixelsFile),'temporalSP');
locationModel=load(fullfile(locationModelPath,...
                int2str(classIndex),locationModelFile),'locationProbMap');
locationModel=locationModel.locationProbMap;
%%
for frame=1:length(temporalSP)
    temporalSP{frame}=temporalSP{frame}+partsNum+1;
end

%%
partsSegmentation={};
for frame=1:length(segments)
    
    foregroundMask=segments{frame};
    
    if nnz(foregroundMask)==0 
        frameResult=ones(size(foregroundMask))*(partsNum+1);
        partsSegmentation{frame}=frameResult;
        continue;
    end
    
    foregroundMask=bwareafilt(foregroundMask,1);

    superpixels=unique(temporalSP{frame});
    foregroundSPMap=uint32(zeros(size(temporalSP{frame})));
    for spIndex=1:length(superpixels)
        spMap=temporalSP{frame};
        spMap(spMap~=superpixels(spIndex))=0;
        if nnz(and(spMap,foregroundMask))>nnz(spMap)*foregroundSPCriteria
            foregroundSPMap=foregroundSPMap+spMap;
        else
            superpixels(spIndex)=0;
        end
    end

    foregroundSP=superpixels(superpixels~=0);
    foregroundSP=foregroundSP';
    
    if isempty(foregroundSP)
        frameResult=ones(size(foregroundMask))*(partsNum+1);
        partsSegmentation{frame}=frameResult;
        continue;
    end

    prop=regionprops(foregroundMask);
    foregroundBB=prop.BoundingBox;
    foregroundBB=ceil(foregroundBB);

    croppedForegroundSPMap=imcrop(foregroundSPMap,foregroundBB);
    resizedLocationModel=...
        imresize(locationModel,size(croppedForegroundSPMap));

    frameResult=zeros(size(foregroundMask));
    
    bbX1=foregroundBB(1);
    bbY1=foregroundBB(2);
    bbX2=foregroundBB(1)+foregroundBB(3);
    bbY2=foregroundBB(2)+foregroundBB(4);
    bbX1=min(bbX1,size(foregroundMask,2));bbX1=max(bbX1,0);
    bbX2=min(bbX2,size(foregroundMask,2));bbX2=max(bbX2,0);
    bbY1=min(bbY1,size(foregroundMask,1));bbY1=max(bbY1,0);
    bbY2=min(bbY2,size(foregroundMask,1));bbY2=max(bbY2,0);
    frameResult(bbY1:bbY2,bbX1:bbX2)=double(croppedForegroundSPMap);
    
    for sp=foregroundSP
        spMap=croppedForegroundSPMap;
        spMap=(spMap==sp);
        spProbs=resizedLocationModel.*repmat(double(spMap),1,1,partsNum+1);
        [~,maxLabel]=max(sum(sum(spProbs)));
        frameResult(frameResult==sp)=maxLabel;
    end
    frameResult(frameResult==0)=partsNum+1;
    partsSegmentation{frame}=frameResult;
end

fprintf('Parts segmentation generated for sequence %d class %d... ',...
        sequenceIndex,classIndex);
toc

outputPath=fullfile(partsSegmentationPath,int2str(classIndex),...
                    int2str(sequenceIndex),partsSegmentationFile);
save(outputPath,'partsSegmentation');


end