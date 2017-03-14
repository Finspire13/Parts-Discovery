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
degeneratedClusterPenalty=10;
softMaskFactor=2;
backgroundProbFactor=0.2;
%%

sequencePath='./data/tigerLeft/4';

startFrame=120;
endFrame=220;

load(strcat(sequencePath,'/',segmentsFile));
load(strcat(sequencePath,'/',temporalSuperPixelsFile));
load(strcat(sequencePath,'/',opticalFlowFile));

frames=dir([sequencePath strcat('/',frameType)]);

proposalsAcrossVideo=[];
%for frameIndex=temporalInterval+1:length(frames)-temporalInterval-1
for frameIndex=startFrame:endFrame
    framePath=strcat(sequencePath,'/',frames(frameIndex).name);
    disp(framePath);

    [partsProposal,partsProposalMap]=clusterSuperpixelsInFrame( flow,temporalSP,segments, frameIndex,temporalInterval,partsNum );
    proposalsAcrossVideo=cat(1,proposalsAcrossVideo,partsProposal);

    imagesc(partsProposalMap);
    outputPath=strcat(ourputPPMapsPath,'/',int2str(3),int2str(4),int2str(frameIndex),'.fig');
    savefig(outputPath);
end



clusterNum=round(partsNum*partsRelaxation);
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
    if clusterSize<=size(proposalsAcrossVideo,1)/(10*clusterNum)
        clusterEnergy(clusterIndex)=degeneratedClusterPenalty;
    else
        clusterEnergy(clusterIndex)=clusterEnergy(clusterIndex)/clusterSize;
    end
end


%% estimate location model   !! so ugly
%for background  
occurrenceCount=zeros(quantizedSpace,quantizedSpace,clusterNum+1);
for frameIndex=startFrame:endFrame
    
    prop=regionprops(segments{frameIndex});
    boundingBox=prop.BoundingBox;
    centroid=prop.Centroid;
    scale=sqrt(boundingBox(3)^2+boundingBox(4)^2);

    softMask=imgaussfilt(double(segments{frameIndex}),softMaskFactor);
    
    
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
    disp(frameIndex);
end
occurrenceCount(:,:,clusterNum+1)=occurrenceCount(:,:,clusterNum+1);
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
for l=1:clusterNum+1
    occurrenceCount(:,:,l)=occurrenceCount(:,:,l)/sum(sum(occurrenceCount(:,:,l)));
end


[~,sortedClusters]=sort(clusterEnergy,'ascend');

% unitedPartsMask=zeros(quantizedSpace,quantizedSpace);
% for clusterIndex=1:clusterNum
%     foregroundMask=occurrenceCount(:,:,clusterNum+1)<0.5;
%     unitedPartsMask=or(unitedPartsMask,occurrenceCount(:,:,clusterIndex)>0.5);
%     
%     
%     foregroundMaskArea=bwarea(foregroundMask);
%     overlapArea=bwarea(and(unitedPartsMask,foregroundMask));
%     
%     if(overlapArea>0.75*foregroundMaskArea)
%         break;
%     end
% end

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