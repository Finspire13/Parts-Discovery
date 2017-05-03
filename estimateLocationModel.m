function [ locationProbMap,occurrenceCount ] = ...
    estimateLocationModel(fileSettings,parameterSettings,classIndex)
%   Estimate location model using clusters of part proposals
%--Inupt--
%   fileSettings:...
%   parameterSettings:...
%   classIndex: For which class to estimate location model
%--Output--
%   locationProbMap: Location model. Saved to file
%   occurrenceCount: Unnormolized location model
%   result.png: Visulization of location model. Saved to file

%% Get Settings

dataPath=fileSettings.dataPath;
segmentsFile=fileSettings.segmentsFile;
frameType=fileSettings.frameType;
proposalsPath=fileSettings.proposalsPath;
proposalsMapFile=fileSettings.proposalsMapFile;
clusterOfProposalsFile=fileSettings.clusterOfProposalsFile;
locationModelPath=fileSettings.locationModelPath;
locationModelFile=fileSettings.locationModelFile;

temporalInterval=parameterSettings.temporalInterval;
partsNum=parameterSettings.partsNum;
partsRelaxation=parameterSettings.partsRelaxation;
softMaskFactor=parameterSettings.softMaskFactor;
quantizedSpace=parameterSettings.quantizedSpace;

%% Load data and initialization

tic;
inputPath=fullfile(proposalsPath,int2str(classIndex),proposalsMapFile);
load(inputPath);
inputPath=fullfile(proposalsPath,int2str(classIndex),clusterOfProposalsFile);
load(inputPath);

clusterResult=clusterOfProposals.clusterResult;
clusterEnergy=clusterOfProposals.clusterEnergy;
clusterCentroids=clusterOfProposals.clusterCentroids;

clusterNum=round(partsNum*partsRelaxation);

occurrenceCount=zeros(quantizedSpace,quantizedSpace,clusterNum+1);


%% Estimate location model for background
classes=dir(dataPath);
classes=classes(~ismember({classes.name},{'.','..'}));      % Remove . and ..
classPath=fullfile(dataPath, classes(classIndex).name);

sequences=dir(classPath);
sequences=sequences(~ismember({sequences.name},{'.','..'}));     % Remove . and ..

for sequenceIndex=1:length(sequences)
    sequencePath=fullfile(classPath,sequences(sequenceIndex).name);
    
    load(fullfile(sequencePath,segmentsFile),'segments');
    
    frames=dir([sequencePath strcat('/',frameType)]);
    for frameIndex=temporalInterval+1:length(frames)-temporalInterval-1
        framePath=fullfile(sequencePath,frames(frameIndex).name);
        
        foregroundMask=segments{frameIndex};
        foregroundMask=bwareafilt(foregroundMask,1);
        if sum(sum(foregroundMask))==0 % Empty mask
            continue;
        end
        
        prop=regionprops(foregroundMask);
        foregroundBB=prop.BoundingBox;

        softMask=imgaussfilt(double(foregroundMask),softMaskFactor);
        croppedSoftMask=imcrop(softMask,foregroundBB);
        resizedSoftMask=imresize(croppedSoftMask,...
                                 [quantizedSpace quantizedSpace]);
        occurrenceCount(:,:,clusterNum+1)=...
            occurrenceCount(:,:,clusterNum+1)+resizedSoftMask;
    end
end
occurrenceCount(:,:,clusterNum+1)=...
    max(max(occurrenceCount(:,:,clusterNum+1)))-...
    occurrenceCount(:,:,clusterNum+1)+0.01;


%% Estimate location model for foreground parts

for l=1:clusterNum
    occurrenceCount(:,:,l)=sum(ppMapsAcrossVideo(:,:,clusterResult==l),3);
end

% Normalize by size
for l=1:clusterNum+1    
    occurrenceCountSum=sum(sum(occurrenceCount(:,:,l)));
    if occurrenceCountSum==0
        occurrenceCount(:,:,l)=0;
    else
        occurrenceCount(:,:,l)=...
            occurrenceCount(:,:,l)/sum(sum(occurrenceCount(:,:,l)));
    end
end

%% Tricky selection of parts

% First select a body part
bodyClusterIndex=0;
minBodyClusterEnergy=Inf;
for i=1:clusterNum
    mask=occurrenceCount(:,:,i)>0.5*max(max(occurrenceCount(:,:,i)));
    area=bwarea(mask);
    if area>quantizedSpace*quantizedSpace*0.25&&...
            clusterEnergy(i)<minBodyClusterEnergy
        if bodyClusterIndex~=0
            clusterEnergy(bodyClusterIndex)=Inf;
        end
        minBodyClusterEnergy=clusterEnergy(i);
        bodyClusterIndex=i;
    end
end
if bodyClusterIndex~=0
    clusterEnergy(bodyClusterIndex)=0;
end

% Remove overlapping parts
for i=1:clusterNum
    for j=i+1:clusterNum
        maskI=occurrenceCount(:,:,i)>0.5*max(max(occurrenceCount(:,:,i)));
        maskJ=occurrenceCount(:,:,j)>0.5*max(max(occurrenceCount(:,:,j)));
        areaI=bwarea(maskI);
        areaJ=bwarea(maskJ);
        if areaI>=areaJ 
            overlapratio=bwarea(and(maskI,maskJ))/areaJ;
            if overlapratio>0.85 && clusterEnergy(i)~=Inf
                clusterEnergy(j)=Inf;
            end
        else
            overlapratio=bwarea(and(maskI,maskJ))/areaI;
            if overlapratio>0.85 && clusterEnergy(j)~=Inf
                clusterEnergy(i)=Inf;
            end
        end
    end
end

%% Compute probability (Final location model)

% !! Here may require manual selection
[~,sortedClusters]=sort(clusterEnergy,'ascend');
maxClusters=sortedClusters(1:partsNum);
occurrenceCount=occurrenceCount(:,:,[maxClusters;clusterNum+1]);

locationProbMap=zeros(quantizedSpace,quantizedSpace,partsNum+1);
for l=1:partsNum+1

     if l==partsNum+1
         occurrenceCount(:,:,l)=occurrenceCount(:,:,l);
     end
    
    locationProbMap(:,:,l)=occurrenceCount(:,:,l)./sum(occurrenceCount,3);
end

[~,maxLabel]=max(locationProbMap,[],3);
imagesc(maxLabel);


%% Save result
fprintf('Location model estimated for class: %d... ',classIndex);
toc

savePath=fullfile(locationModelPath,int2str(classIndex),locationModelFile);
save(savePath,'locationProbMap');

figPath=strcat(locationModelPath,'/',int2str(classIndex),'/',...
               'result.png');
print('-dpng',figPath);
end