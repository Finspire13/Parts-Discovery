%%
fileSettings.dataPath = './data';
fileSettings.frameType='*.jpg';     
fileSettings.gtLabelsFile='gtLabels.mat';
fileSettings.segmentsFile='segments.mat';
fileSettings.superPixelsFile='superPixels.mat';
fileSettings.temporalSuperPixelsFile='temporalSuperPixels.mat';
fileSettings.opticalFlowFile='opticalFlow.mat';

fileSettings.proposalsFile='proposalsAcrossVideo.mat';
fileSettings.proposalsMapFile='ppMapsAcrossVideo.mat';
fileSettings.clusterOfProposalsFile='clusterOfProposals.mat';
fileSettings.partsSegmentationFile='partsSegmentation.mat';
fileSettings.clusterResultMapsPath='./output/clusterResultMaps';
fileSettings.partsSegmentationPath='./output/partSegments';
fileSettings.proposalsPath='./output/pp';
fileSettings.visualizationPath='./output/visualization';
fileSettings.visualizationFile='visualization.avi';

parameterSettings.frameHeight=225;
parameterSettings.frameWidth=400;

parameterSettings.temporalInterval=2;
parameterSettings.partsNum=10;
parameterSettings.quantizedSpace=500;
parameterSettings.partsRelaxation=2;
parameterSettings.degeneratedClusterPenalty=Inf;
parameterSettings.degeneratedClusterCriteria=80;
parameterSettings.softMaskFactor=2;
parameterSettings.foregroundSPCriteria=0.75;
parameterSettings.partStrictness=0.7;

%%

for classIndex=3:3
     clusterProposalsAcrossVideo(fileSettings,parameterSettings,classIndex);
end


%%

 [locationProbMap,occurrenceCount]=...
     estimateLocationModel(fileSettings,parameterSettings,3);

%%
for i=1:8
    [ partsSegmentation ]=...
        videoSegmentParts(fileSettings,parameterSettings,...
                          4, i, locationProbMap );
end

%%
[ avgOverlapRatio, overlapRatio ] = ...
    evaluate( fileSettings,parameterSettings, classIndex, sequenceIndices);

%%

for i=1:8
    visualizeSegments( fileSettings,parameterSettings, 1, i );
end