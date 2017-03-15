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
fileSettings.clusterOfProposalsFile='clusterOfProposals.mat';
fileSettings.ppMapsPath='./ppMaps';

parameterSettings.frameHeight=225;
parameterSettings.frameWidth=400;

parameterSettings.temporalInterval=2;
parameterSettings.partsNum=10;
parameterSettings.quantizedSpace=500;
parameterSettings.partsRelaxation=2.5;
parameterSettings.degeneratedClusterPenalty=10;
parameterSettings.degeneratedClusterCriteria=25;
parameterSettings.softMaskFactor=2;
parameterSettings.backgroundProbFactor=0.2;

%%

% for classIndex=1:4
%     clusterProposalsAcrossVideo(classIndex, fileSettings,parameterSettings)
% end


%%

[ locationProbMap,occurrenceCount ]=estimateLocationModel(1, fileSettings,parameterSettings);
