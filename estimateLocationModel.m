function [ locationProbMap,occurrenceCount ] = estimateLocationModel(classIndex, fileSettings,parameterSettings)
%ESTIMATELOCATIONMODEL Summary of this function goes here
%   Detailed explanation goes here

dataPath=fileSettings.dataPath;
segmentsFile=fileSettings.segmentsFile;
frameType=fileSettings.frameType;

proposalsPath=fileSettings.proposalsPath;
proposalsFile=fileSettings.proposalsFile;
clusterOfProposalsFile=fileSettings.clusterOfProposalsFile;

temporalInterval=parameterSettings.temporalInterval;
partsNum=parameterSettings.partsNum;
partsRelaxation=parameterSettings.partsRelaxation;
frameHeight=parameterSettings.frameHeight;
frameWidth=parameterSettings.frameWidth;
softMaskFactor=parameterSettings.softMaskFactor;
quantizedSpace=parameterSettings.quantizedSpace;
backgroundProbFactor=parameterSettings.backgroundProbFactor;

%%

inputPath=strcat(proposalsPath,'/',int2str(classIndex),'/',proposalsFile);
load(inputPath);
inputPath=strcat(proposalsPath,'/',int2str(classIndex),'/',clusterOfProposalsFile);
load(inputPath);

clusterResult=clusterOfProposals.clusterResult;
clusterEnergy=clusterOfProposals.clusterEnergy;
clusterCentroids=clusterOfProposals.clusterCentroids;

clusterNum=round(partsNum*partsRelaxation);

occurrenceCount=zeros(quantizedSpace,quantizedSpace,clusterNum+1);

%for background
classes=dir(dataPath);
classes=classes(~ismember({classes.name},{'.','..'}));      % Remove . and ..
classPath=strcat(dataPath ,'/' , classes(classIndex).name);

sequences=dir(classPath);
sequences=sequences(~ismember({sequences.name},{'.','..'}));     % Remove . and ..

for sequenceIndex=1:length(sequences)
    sequencePath=strcat(classPath,'/',sequences(sequenceIndex).name);
    
    load(strcat(sequencePath,'/',segmentsFile));
    
    frames=dir([sequencePath strcat('/',frameType)]);
    for frameIndex=temporalInterval+1:length(frames)-temporalInterval-1
        framePath=strcat(sequencePath,'/',frames(frameIndex).name);
        
        softMask=imgaussfilt(double(segments{frameIndex}),softMaskFactor);
        
        prop=regionprops(segments{frameIndex});
        boundingBox=prop.BoundingBox;
        centroid=prop.Centroid;
        scale=sqrt(boundingBox(3)^2+boundingBox(4)^2);
        for x=1:quantizedSpace
            for y=1:quantizedSpace
                disquantizedX = x*3/quantizedSpace-1.5;
                disquantizedY = y*2/quantizedSpace-1;                 %!! may be wrong
                originalXY=round([disquantizedX disquantizedY].*scale+centroid);

                if originalXY(1)<1 ||originalXY(2)<1||originalXY(1)>frameWidth||originalXY(2)>frameHeight

                else
                    occurrenceCount(y,x,clusterNum+1)=occurrenceCount(y,x,clusterNum+1)+softMask(originalXY(2),originalXY(1));
                end
            end
        end
        disp(framePath);
    end
end
occurrenceCount(:,:,clusterNum+1)=max(max(occurrenceCount(:,:,clusterNum+1)))-occurrenceCount(:,:,clusterNum+1)+0.01;


for x=1:quantizedSpace
    for y=1:quantizedSpace
        for proposalIndex=1:size(proposalsAcrossVideo,1)
                
            % -1.5~1.5 -1~1 -> 1 ~ 500 quantized mapping
            disquantizedX = x*3/quantizedSpace-1.5;
            disquantizedY = y*2/quantizedSpace-1;                 %!! may be wrong
            ppX=proposalsAcrossVideo(proposalIndex,1);
            ppY=proposalsAcrossVideo(proposalIndex,2);
            ppW=proposalsAcrossVideo(proposalIndex,3);
            ppH=proposalsAcrossVideo(proposalIndex,4);

            % check if in proposal
            if abs(disquantizedX-ppX) <= 0.5*ppW && abs(disquantizedY-ppY) <=0.5*ppH
                occurrenceCount(y,x,clusterResult(proposalIndex))=occurrenceCount(y,x,clusterResult(proposalIndex))+1;     %y,x not x,y
            end
        end
    end
    disp(x);
end

for l=1:clusterNum+1    % normalize
    occurrenceCountSum=sum(sum(occurrenceCount(:,:,l)));
    if occurrenceCountSum==0
        occurrenceCount(:,:,l)=0;
    else
        occurrenceCount(:,:,l)=occurrenceCount(:,:,l)/sum(sum(occurrenceCount(:,:,l)));
    end
end

[~,sortedClusters]=sort(clusterEnergy,'ascend');
maxClusters=sortedClusters(1:partsNum);
occurrenceCount=occurrenceCount(:,:,[maxClusters;clusterNum+1]);


locationProbMap=zeros(quantizedSpace,quantizedSpace,partsNum+1);
for l=1:partsNum+1

%     if l==partsNum+1
%         occurrenceCount(:,:,l)=occurrenceCount(:,:,l)*backgroundProbFactor;
%     end
    
    locationProbMap(:,:,l)=occurrenceCount(:,:,l)./sum(occurrenceCount,3);
end


[~,maxLabel]=max(locationProbMap,[],3);
figure;imagesc(maxLabel);



end