function [ proposalsAcrossVideo ] = ...
    clusterProposalsAcrossVideo(fileSettings,parameterSettings,classIndex)
%CLUSTERPROPOSALSACROSSVIDEO Summary of this function goes here
%   Detailed explanation goes here

dataPath=fileSettings.dataPath;
segmentsFile=fileSettings.segmentsFile;
temporalSuperPixelsFile=fileSettings.temporalSuperPixelsFile;
opticalFlowFile=fileSettings.opticalFlowFile;
frameType=fileSettings.frameType;
clusterResultMapsPath=fileSettings.clusterResultMapsPath;
proposalsPath=fileSettings.proposalsPath;
proposalsFile=fileSettings.proposalsFile;
proposalsMapFile=fileSettings.proposalsMapFile;
clusterOfProposalsFile=fileSettings.clusterOfProposalsFile;

temporalInterval=parameterSettings.temporalInterval;
partsNum=parameterSettings.partsNum;
partsRelaxation=parameterSettings.partsRelaxation;
degeneratedClusterPenalty=parameterSettings.degeneratedClusterPenalty;
degeneratedClusterCriteria=parameterSettings.degeneratedClusterCriteria;

%%

classes=dir(dataPath);
classes=classes(~ismember({classes.name},{'.','..'}));      % Remove . and ..
classPath=fullfile(dataPath, classes(classIndex).name);

sequences=dir(classPath);
sequences=sequences(~ismember({sequences.name},{'.','..'}));     % Remove . and ..

proposalsAcrossVideo=[];
ppMapsAcrossVideo=[];
for sequenceIndex=1:length(sequences)
    sequencePath=fullfile(classPath,sequences(sequenceIndex).name);

    load(fullfile(sequencePath,segmentsFile),'segments');
    load(fullfile(sequencePath,temporalSuperPixelsFile),'temporalSP');
    load(fullfile(sequencePath,opticalFlowFile),'flow');
    
    frames=dir([sequencePath strcat('/',frameType)]);

    for frameIndex=temporalInterval+1:length(frames)-temporalInterval-1
        %framePath=fullfile(sequencePath,frames(frameIndex).name);
        tic;
        [partsProposal,partsProposalMap,clusterResultMap]=...
            clusterSuperpixelsInFrame(flow,temporalSP,segments,...
                                      frameIndex,parameterSettings);

        proposalsAcrossVideo=cat(1,proposalsAcrossVideo,partsProposal);
        ppMapsAcrossVideo=cat(3,ppMapsAcrossVideo,partsProposalMap);

        imagesc(clusterResultMap);
        
        outputPath=strcat(clusterResultMapsPath,'/',int2str(classIndex),...
                   int2str(sequenceIndex),int2str(frameIndex),'.fig'); 
        savefig(outputPath); 
        
        framePath=fullfile(sequencePath,frames(frameIndex).name);
        fprintf(strcat('Foreground superpixels clustered in frame ',...
                        framePath,'... '));
        toc
    end
    
    fprintf('All frames clustered for sequence: %d... \n',sequenceIndex);
end
fprintf('All frames clustered for class: %d... \n',classIndex);

outputPath=fullfile(proposalsPath,int2str(classIndex),proposalsFile);
save(outputPath,'proposalsAcrossVideo');
outputPath=fullfile(proposalsPath,int2str(classIndex),proposalsMapFile);
save(outputPath,'ppMapsAcrossVideo','-v7.3');

%%
tic;
clusterNum=round(partsNum*partsRelaxation);

totalClusterEnergy=Inf;
for kmeansIndex=1:1000
    
    [tempClusterResult,tempClusterCentroids,tempClusterEnergy]=...
        kmeans(proposalsAcrossVideo,clusterNum);

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
        clusterEnergy(clusterIndex)=...
            clusterEnergy(clusterIndex)+degeneratedClusterPenalty;
    end
end
fprintf('Parts proposals clustered for class: %d... ',classIndex);
toc

clusterOfProposals.clusterResult=clusterResult;
clusterOfProposals.clusterEnergy=clusterEnergy;
clusterOfProposals.clusterCentroids=clusterCentroids;

outputPath=fullfile(proposalsPath,int2str(classIndex),...
                    clusterOfProposalsFile);
save(outputPath,'clusterOfProposals');
end

