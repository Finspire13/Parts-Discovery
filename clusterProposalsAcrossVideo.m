function [ proposalsAcrossVideo ] = clusterProposalsAcrossVideo(classIndex, fileSettings,parameterSettings)
%CLUSTERPROPOSALSACROSSVIDEO Summary of this function goes here
%   Detailed explanation goes here

dataPath=fileSettings.dataPath;
segmentsFile=fileSettings.segmentsFile;
temporalSuperPixelsFile=fileSettings.temporalSuperPixelsFile;
opticalFlowFile=fileSettings.opticalFlowFile;
frameType=fileSettings.frameType;
ourputPPMapsPath=fileSettings.ourputPPMapsPath;
outputProposalsPath=fileSettings.outputProposalsPath;
outputProposalsFile=fileSettings.outputProposalsFile;
outputClusterResultFile=fileSettings.outputClusterResultFile;
outputMaxClustersFile=fileSettings.outputMaxClustersFile;

temporalInterval=parameterSettings.temporalInterval;
partsNum=parameterSettings.partsNum;
partsRelaxation=parameterSettings.partsRelaxation;
degeneratedClusterPenalty=parameterSettings.degeneratedClusterPenalty;

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
        outputPath=strcat(ourputPPMapsPath,'/',int2str(classIndex),int2str(sequenceIndex),int2str(frameIndex),'.fig');
        savefig(outputPath);
    end
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
    if clusterSize<=size(proposalsAcrossVideo,1)/200
        clusterEnergy(clusterIndex)=degeneratedClusterPenalty;
    else
        clusterEnergy(clusterIndex)=clusterEnergy(clusterIndex)/clusterSize;
    end
end

[~,sortedClusters]=sort(clusterEnergy,'ascend');
maxClusters=sortedClusters(1:partsNum);


outputPath=strcat(outputProposalsPath,'/',int2str(classIndex),'/',outputProposalsFile);
save(outputPath,'proposalsAcrossVideo');
outputPath=strcat(outputProposalsPath,'/',int2str(classIndex),'/',outputClusterResultFile);
save(outputPath,'clusterResult');
outputPath=strcat(outputProposalsPath,'/',int2str(classIndex),'/',outputMaxClustersFile);
save(outputPath,'maxClusters');

end

