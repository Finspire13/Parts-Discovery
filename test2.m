%%
dataPath = './data';
frameType='*.jpg';     
%gtLabelsFile='gtLabels.mat';
segmentsFile='segments.mat';
%superPixelsFile='superPixels.mat';
temporalSuperPixelsFile='temporalSuperPixels.mat';
opticalFlowFile='opticalFlow.mat';

% outputProposalsPath='./pp';
% outputProposalsFile='proposalsAcrossVideo.mat';
% outputClusterResultFile='clusterResult.mat';
% outputMaxClustersFile='maxClusters.mat';
ourputPPMapsPath='./ppMapsTest';

frameHeight=225;
frameWidth=400;

temporalInterval=2;
partsNum=10;
quantizedSpace=500;
partsRelaxation=2.5;
degeneratedClusterPenalty=Inf;
softMaskFactor=2;
backgroundProbFactor=0.2;
degeneratedClusterCriteria=10;

%%
parameterSettings.temporalInterval=2;
parameterSettings.partsNum=10;
parameterSettings.quantizedSpace=500;
%%

sequencePath='./data/tigerLeft/4';

startFrame=100;
endFrame=250;

load(strcat(sequencePath,'/',segmentsFile));
load(strcat(sequencePath,'/',temporalSuperPixelsFile));
load(strcat(sequencePath,'/',opticalFlowFile));

frames=dir([sequencePath strcat('/',frameType)]);

proposalsAcrossVideo=[];
ppMapsAcrossVideo=[];
%for frameIndex=temporalInterval+1:length(frames)-temporalInterval-1
for frameIndex=startFrame:endFrame
    framePath=strcat(sequencePath,'/',frames(frameIndex).name);
    disp(framePath);

    [partsProposal,partsProposalMap,clusterResultMap]=clusterSuperpixelsInFrame( flow,temporalSP,segments, frameIndex,parameterSettings );
    proposalsAcrossVideo=cat(1,proposalsAcrossVideo,partsProposal);
    ppMapsAcrossVideo=cat(3,ppMapsAcrossVideo,partsProposalMap);

    imagesc(clusterResultMap);
    outputPath=strcat(ourputPPMapsPath,'/',int2str(3),int2str(4),int2str(frameIndex),'.fig');
    savefig(outputPath);
end



%clusterNum=round(partsNum*partsRelaxation);
clusterNum=partsNum;
totalClusterEnergy=Inf;
for kmeansIndex=1:1000
    [tempClusterResult,tempClusterCentroids,tempClusterEnergy]=kmeans(proposalsAcrossVideo,clusterNum);
    if sum(tempClusterEnergy)<totalClusterEnergy
        clusterResult=tempClusterResult;
        clusterEnergy=tempClusterEnergy;
        clusterCentroids=tempClusterCentroids;
        totalClusterEnergy=sum(tempClusterEnergy);
    end
end



%Normalize clusterEnergy
for clusterIndex=1:length(clusterEnergy)
    clusterSize=numel(find(clusterResult==clusterIndex));
    clusterEnergy(clusterIndex)=clusterEnergy(clusterIndex)/clusterSize;
    
    if clusterSize<=degeneratedClusterCriteria
        clusterEnergy(clusterIndex)=clusterEnergy(clusterIndex)+degeneratedClusterPenalty;
    end
end


%% estimate location model   !! so ugly
%for background  
occurrenceCount=zeros(quantizedSpace,quantizedSpace,clusterNum+1);
for frameIndex=startFrame:endFrame
    
    prop=regionprops(segments{frameIndex});
    foregroundBB=prop.BoundingBox;

    softMask=imgaussfilt(double(segments{frameIndex}),softMaskFactor);
    croppedSoftMask=imcrop(softMask,foregroundBB);
    resizedSoftMask=imresize(croppedSoftMask,[quantizedSpace quantizedSpace]);
    occurrenceCount(:,:,clusterNum+1)=occurrenceCount(:,:,clusterNum+1)+resizedSoftMask;
    
    disp(frameIndex);
end
occurrenceCount(:,:,clusterNum+1)=max(max(occurrenceCount(:,:,clusterNum+1)))-occurrenceCount(:,:,clusterNum+1)+0.01;

for l=1:clusterNum
    occurrenceCount(:,:,l)=sum(ppMapsAcrossVideo(:,:,clusterResult==l),3);
end

for l=1:clusterNum+1    % normalize
    occurrenceCountSum=sum(sum(occurrenceCount(:,:,l)));
    if occurrenceCountSum==0
        occurrenceCount(:,:,l)=0;
    else
        occurrenceCount(:,:,l)=occurrenceCount(:,:,l)/sum(sum(occurrenceCount(:,:,l)));
    end
end

%[~,sortedClusters]=sort(clusterEnergy,'ascend');
% 
% % unitedPartsMask=zeros(quantizedSpace,quantizedSpace);
% % for clusterIndex=1:clusterNum
% %     foregroundMask=occurrenceCount(:,:,clusterNum+1)<0.5;
% %     unitedPartsMask=or(unitedPartsMask,occurrenceCount(:,:,clusterIndex)>0.5);
% %     
% %     
% %     foregroundMaskArea=bwarea(foregroundMask);
% %     overlapArea=bwarea(and(unitedPartsMask,foregroundMask));
% %     
% %     if(overlapArea>0.75*foregroundMaskArea)
% %         break;
% %     end
% % end
% 
%maxClusters=sortedClusters(1:partsNum);
%occurrenceCount=occurrenceCount(:,:,[maxClusters;clusterNum+1]);


locationProbMap=zeros(quantizedSpace,quantizedSpace,partsNum+1);
for l=1:partsNum+1

     if l==partsNum+1
         occurrenceCount(:,:,l)=occurrenceCount(:,:,l)*75;
     end
    
    locationProbMap(:,:,l)=occurrenceCount(:,:,l)./sum(occurrenceCount,3);
end


[~,maxLabel]=max(locationProbMap,[],3);
figure;imagesc(maxLabel);