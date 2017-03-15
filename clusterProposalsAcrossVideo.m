function [ proposalsAcrossVideo ] = clusterProposalsAcrossVideo(classIndex, fileSettings,parameterSettings)
%CLUSTERPROPOSALSACROSSVIDEO Summary of this function goes here
%   Detailed explanation goes here

dataPath=fileSettings.dataPath;
segmentsFile=fileSettings.segmentsFile;
temporalSuperPixelsFile=fileSettings.temporalSuperPixelsFile;
opticalFlowFile=fileSettings.opticalFlowFile;
frameType=fileSettings.frameType;
ppMapsPath=fileSettings.ppMapsPath;
proposalsPath=fileSettings.proposalsPath;
proposalsFile=fileSettings.proposalsFile;
clusterOfProposalsFile=fileSettings.clusterOfProposalsFile;

temporalInterval=parameterSettings.temporalInterval;
partsNum=parameterSettings.partsNum;
partsRelaxation=parameterSettings.partsRelaxation;
degeneratedClusterPenalty=parameterSettings.degeneratedClusterPenalty;
degeneratedClusterCriteria=parameterSettings.degeneratedClusterCriteria;

%%

classes=dir(dataPath);
classes=classes(~ismember({classes.name},{'.','..'}));      % Remove . and ..
classPath=strcat(dataPath ,'/' , classes(classIndex).name);

sequences=dir(classPath);
sequences=sequences(~ismember({sequences.name},{'.','..'}));     % Remove . and ..

proposalsAcrossVideo=[];
for sequenceIndex=1:length(sequences)
    sequencePath=strcat(classPath,'/',sequences(sequenceIndex).name);

    %startFrame=1;
    %endFrame=220;

    load(strcat(sequencePath,'/',segmentsFile));
    load(strcat(sequencePath,'/',temporalSuperPixelsFile));
    load(strcat(sequencePath,'/',opticalFlowFile));

    frames=dir([sequencePath strcat('/',frameType)]);


    for frameIndex=temporalInterval+1:length(frames)-temporalInterval-1
    %for frameIndex=startFrame:endFrame
        framePath=strcat(sequencePath,'/',frames(frameIndex).name);
        disp(framePath);

        [partsProposal,partsProposalMap]=clusterSuperpixelsInFrame( flow,temporalSP,segments, frameIndex,temporalInterval,partsNum );
        %partsProposal=rand(10,4);
        %partsProposalMap=rand(10,10);
        proposalsAcrossVideo=cat(1,proposalsAcrossVideo,partsProposal);

        imagesc(partsProposalMap);
        outputPath=strcat(ppMapsPath,'/',int2str(classIndex),int2str(sequenceIndex),int2str(frameIndex),'.fig');
        savefig(outputPath);
    end
end

outputPath=strcat(proposalsPath,'/',int2str(classIndex),'/',proposalsFile);
save(outputPath,'proposalsAcrossVideo');


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
    disp(kmeansIndex);
end



%Normalize clusterEnergy
for clusterIndex=1:length(clusterEnergy)
    clusterSize=numel(find(clusterResult==clusterIndex));
    clusterEnergy(clusterIndex)=clusterEnergy(clusterIndex)/clusterSize;
    
    if clusterSize<=ceil(size(proposalsAcrossVideo,1)/(degeneratedClusterCriteria*clusterNum))
        clusterEnergy(clusterIndex)=clusterEnergy(clusterIndex)+degeneratedClusterPenalty;
    end
end

clusterOfProposals.clusterResult=clusterResult;
clusterOfProposals.clusterEnergy=clusterEnergy;
clusterOfProposals.clusterCentroids=clusterCentroids;

outputPath=strcat(proposalsPath,'/',int2str(classIndex),'/',clusterOfProposalsFile);
save(outputPath,'clusterOfProposals');

end

