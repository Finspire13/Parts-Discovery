function [ partsSegmentation ] = videoSegmentParts( fileSettings, parameterSettings, classIndex, sequenceIndex, locationModel )
%VIDEOSEGMENTPARTS Summary of this function goes here
%   Detailed explanation goes here

dataPath = fileSettings.dataPath;
segmentsFile=fileSettings.segmentsFile;
temporalSuperPixelsFile=fileSettings.temporalSuperPixelsFile;
partsSegmentationFile=fileSettings.partsSegmentationFile;
partsSegmentationPath=fileSettings.partsSegmentationPath;

partsNum=parameterSettings.partsNum;


%%

classes=dir(dataPath);
classes=classes(~ismember({classes.name},{'.','..'}));      % Remove . and ..
classPath=strcat(dataPath ,'/' , classes(classIndex).name);

sequences=dir(classPath);
sequences=sequences(~ismember({sequences.name},{'.','..'}));     % Remove . and ..
sequencePath=strcat(classPath,'/',sequences(sequenceIndex).name);

load(strcat(sequencePath,'/',segmentsFile),'segments');
load(strcat(sequencePath,'/',temporalSuperPixelsFile),'temporalSP');

%%
for frame=1:length(temporalSP)
    temporalSP{frame}=temporalSP{frame}+partsNum+1;
end

%%
partsSegmentation={};
for frame=1:length(segments)
    
    foregroundMask=segments{frame};
    
    if nnz(foregroundMask)==0 
        frameResult=zeros(size(foregroundMask));
        partsSegmentation{frame}=frameResult;
        continue;
    end
    
    foregroundMask=bwareafilt(foregroundMask,1);

    superpixels=unique(temporalSP{frame});
    foregroundSPMap=uint32(zeros(size(temporalSP{frame})));
    for spIndex=1:length(superpixels)
        spMap=temporalSP{frame};
        spMap(spMap~=superpixels(spIndex))=0;
        if nnz(and(spMap,foregroundMask))>nnz(spMap)*0.5
            foregroundSPMap=foregroundSPMap+spMap;
        else
            superpixels(spIndex)=0;
        end
    end

    foregroundSP=superpixels(superpixels~=0);
    foregroundSP=foregroundSP';
    
    if isempty(foregroundSP)
        frameResult=zeros(size(foregroundMask));
        partsSegmentation{frame}=frameResult;
        continue;
    end


    prop=regionprops(foregroundMask);
    foregroundBB=prop.BoundingBox;
    foregroundBB=ceil(foregroundBB);

    croppedMask=imcrop(foregroundMask,foregroundBB);
    croppedForegroundSPMap=imcrop(foregroundSPMap,foregroundBB);
    resizedLocationModel=imresize(locationModel,size(croppedMask));

    frameResult=zeros(size(segments{frame}));
    
    bbX1=foregroundBB(1);
    bbY1=foregroundBB(2);
    bbX2=foregroundBB(1)+foregroundBB(3);
    bbY2=foregroundBB(2)+foregroundBB(4);
    bbX1=min(bbX1,size(segments{frame},2));bbX1=max(bbX1,0);
    bbX2=min(bbX2,size(segments{frame},2));bbX2=max(bbX2,0);
    bbY1=min(bbY1,size(segments{frame},1));bbY1=max(bbY1,0);
    bbY2=min(bbY2,size(segments{frame},1));bbY2=max(bbY2,0);

    frameResult(bbY1:bbY2,bbX1:bbX2)=double(croppedForegroundSPMap);
    for sp=foregroundSP
        spMap=croppedForegroundSPMap;
        spMap(spMap~=sp)=0;
        spProbs=resizedLocationModel.*repmat(double(spMap),1,1,partsNum+1);
        [~,maxLabel]=max(sum(sum(spProbs)));
        frameResult(frameResult==sp)=maxLabel;
    end
    frameResult(frameResult==0)=partsNum+1;
    partsSegmentation{frame}=frameResult;
    disp(frame);
%     figure;imagesc(croppedMask);
%     figure;imagesc(croppedForegroundSPMap);
%     figure;imagesc(maxLabel);
%     figure;imagesc(result);

end

outputPath=strcat(partsSegmentationPath,'/',int2str(classIndex),'/',int2str(sequenceIndex),'/',partsSegmentationFile);
save(outputPath,'partsSegmentation');


end