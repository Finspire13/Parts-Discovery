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

totalClusterEnergy=Inf;
for kmeansIndex=1:1000
    [tempClusterResult,~,tempClusterEnergy]=kmeans(proposalsAcrossVideo,round(partsNum*partsRelaxation));
    if sum(tempClusterEnergy)<totalClusterEnergy
        clusterResult=tempClusterResult;
        clusterEnergy=tempClusterEnergy;
        totalClusterEnergy=sum(tempClusterEnergy);
    end
end



%Normalize clusterEnergy
for clusterIndex=1:length(clusterEnergy)
    clusterSize=numel(find(clusterResult==clusterIndex));
    if clusterSize<=size(proposalsAcrossVideo,1)/20
        clusterEnergy(clusterIndex)=degeneratedClusterPenalty;
    else
        clusterEnergy(clusterIndex)=clusterEnergy(clusterIndex)/clusterSize;
    end
end

[~,sortedClusters]=sort(clusterEnergy,'ascend');
maxClusters=sortedClusters(1:partsNum);

%% estimate location model   !! so ugly

occurrenceCount=zeros(quantizedSpace,quantizedSpace,partsNum+1);
for x=1:quantizedSpace
    for y=1:quantizedSpace
        for proposalIndex=1:size(proposalsAcrossVideo,1)
            if any(clusterResult(proposalIndex)==maxClusters)

                % -1.5~1.5 -1~1 -> 1 ~ 500 quantized mapping
                disquantizedX = x*3/quantizedSpace-1.5;
                disquantizedY = y*2/quantizedSpace-1;                 %!! may be wrong
                ppX=proposalsAcrossVideo(proposalIndex,1);
                ppY=proposalsAcrossVideo(proposalIndex,2);
                ppW=proposalsAcrossVideo(proposalIndex,3);
                ppH=proposalsAcrossVideo(proposalIndex,4);

                % check if in proposal
                if disquantizedX-ppX >=0 && disquantizedX-ppX <=ppW && disquantizedY-ppY >=0 && disquantizedY-ppY <=ppH
                    partLabel=find(maxClusters==clusterResult(proposalIndex));
                    occurrenceCount(y,x,partLabel)=occurrenceCount(y,x,partLabel)+1;     %y,x not x,y
                end
 
            end
        end
    end
    disp(x);
end

%for background  

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
                occurrenceCount(y,x,partsNum+1)=occurrenceCount(y,x,partsNum+1)+softMask(originalXY(2),originalXY(1));
            end
        end
    end
    disp(frameIndex);
end
occurrenceCount(:,:,partsNum+1)=occurrenceCount(:,:,partsNum+1);
occurrenceCount(:,:,partsNum+1)=max(max(occurrenceCount(:,:,partsNum+1)))-occurrenceCount(:,:,partsNum+1)+0.01;



locationProbMap=zeros(quantizedSpace,quantizedSpace,partsNum+1);
for l=1:partsNum+1
    occurrenceCount(:,:,l)=occurrenceCount(:,:,l)/max(max(occurrenceCount(:,:,l)));%normalize
    
    %occurrenceCount(:,:,l)=occurrenceCount(:,:,l)-0.5*max(max(occurrenceCount(:,:,l)));
    %occurrenceCount(:,:,l)=(1+exp(-1*occurrenceCount(:,:,l))).^-1; %sigmoid
%     
%     if l==partsNum+1
%         occurrenceCount(:,:,l)=occurrenceCount(:,:,l)*backgroundProbFactor;
%     end
    
    
    locationProbMap(:,:,l)=occurrenceCount(:,:,l)./sum(occurrenceCount,3);
end


% locationProbMap=zeros(quantizedSpace,quantizedSpace,partsNum+1);
% for x=1:quantizedSpace
%     for y=1:quantizedSpace
%         for l=1:partsNum+1
%             if sum(occurrenceCount(x,y,:))==0
%                 locationProbMap(x,y,l)=0;
%             else
%                 locationProbMap(x,y,l)=occurrenceCount(x,y,l)/sum(occurrenceCount(x,y,:));
%             end
%         end
%     end
% end


[~,maxLabel]=max(locationProbMap,[],3);
figure;imagesc(maxLabel);