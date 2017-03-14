%%
fileSettings.dataPath = './data';
fileSettings.frameType='*.jpg';     
%fileSettings.gtLabelsFile='gtLabels.mat';
fileSettings.segmentsFile='segments.mat';
%fileSettings.superPixelsFile='superPixels.mat';
fileSettings.temporalSuperPixelsFile='temporalSuperPixels.mat';
fileSettings.opticalFlowFile='opticalFlow.mat';

fileSettings.outputProposalsPath='./pp';
fileSettings.outputProposalsFile='proposalsAcrossVideo.mat';
fileSettings.outputClusterResultFile='clusterResult.mat';
fileSettings.outputMaxClustersFile='maxClusters.mat';
fileSettings.ourputPPMapsPath='./ppMaps';

parameterSettings.frameHeight=225;
parameterSettings.frameWidth=400;

parameterSettings.temporalInterval=2;
parameterSettings.partsNum=10;
parameterSettings.quantizedSpace=500;
parameterSettings.partsRelaxation=2.5;
parameterSettings.degeneratedClusterPenalty=10;
parameterSettings.softMaskFactor=2;
parameterSettings.backgroundProbFactor=0.2;

%%

% for classIndex=1:4
%     clusterProposalsAcrossVideo(classIndex, fileSettings,parameterSettings)
% end


%%

%[ locationProbMap,occurrenceCount ]=estimateLocationModel(1, fileSettings,parameterSettings);
