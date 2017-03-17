%%
fileSettings.dataPath = './data';
fileSettings.frameType='*.jpg';     
%fileSettings.gtLabelsFile='gtLabels.mat';
fileSettings.segmentsFile='segments.mat';
%fileSettings.superPixelsFile='superPixels.mat';
fileSettings.temporalSuperPixelsFile='temporalSuperPixels.mat';
fileSettings.opticalFlowFile='opticalFlow.mat';

fileSettings.proposalsPath='./pp';
fileSettings.proposalsFile='proposalsAcrossVideo.mat';
fileSettings.proposalsMapFile='ppMapsAcrossVideo.mat';
fileSettings.clusterOfProposalsFile='clusterOfProposals.mat';
fileSettings.clusterResultMapsPath='./clusterResultMaps';

parameterSettings.frameHeight=225;
parameterSettings.frameWidth=400;

parameterSettings.temporalInterval=2;
parameterSettings.partsNum=10;
parameterSettings.quantizedSpace=500;
parameterSettings.partsRelaxation=2;
parameterSettings.degeneratedClusterPenalty=Inf;
parameterSettings.degeneratedClusterCriteria=80;
parameterSettings.softMaskFactor=2;

%%

for classIndex=3:3
     clusterProposalsAcrossVideo(classIndex, fileSettings,parameterSettings);
end


%%

%[ locationProbMap,occurrenceCount ]=estimateLocationModel(1, fileSettings,parameterSettings);
