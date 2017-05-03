%% File Settings

% Dataset related
fileSettings.dataPath = './data';
fileSettings.shapeDataPath='./shapeData';
fileSettings.frameType='*.jpg';     
fileSettings.gtLabelsFile='gtLabels.mat';
fileSettings.segmentsFile='segments_OSVOS.mat';     % segments_OSVOS.mat or segments.mat
fileSettings.superPixelsFile='superPixels.mat';
fileSettings.temporalSuperPixelsFile='temporalSuperPixels.mat';     
fileSettings.opticalFlowFile='opticalFlow.mat';     % opticalFlow.mat or flow_flownet.mat

% Output related
fileSettings.proposalsFile='proposalsAcrossVideo.mat';
fileSettings.proposalsMapFile='ppMapsAcrossVideo.mat';
fileSettings.clusterOfProposalsFile='clusterOfProposals.mat';
fileSettings.partsSegmentationFile='partsSegmentation.mat';
fileSettings.clusterResultMapsPath='./output/clusterResultMaps';
fileSettings.partsSegmentationPath='./output/partSegments';
fileSettings.proposalsPath='./output/pp';
fileSettings.visualizationPath='./output/visualization';
fileSettings.visualizationFile='visualization.avi';
fileSettings.locationModelPath='./output/locationModel';
fileSettings.locationModelFile='locationProbMap.mat';

% Util related
fileSettings.optimizationSolverPath='./external/optimization/TRW-S/';
fileSettings.fastSegUtilPath='./external/fromFastSeg';


%% Parameter Settings

parameterSettings.temporalInterval=2;
parameterSettings.partsNum=10;
parameterSettings.quantizedSpace=500;
parameterSettings.partsRelaxation=2;
parameterSettings.degeneratedClusterPenalty=Inf;
parameterSettings.degeneratedClusterCriteria=80;
parameterSettings.softMaskFactor=2;
parameterSettings.foregroundSPCriteria=0.3;
parameterSettings.partStrictness=0.7;

parameterSettings.spatialWeight=0;
parameterSettings.temporalWeight=1.2;
parameterSettings.shapeWeight=-0.05;

%% Compile Util Mex

compileFastSegUtil( fileSettings );

%% Estimate Location Models

for classIndex=1:4
    
    clusterProposalsAcrossVideo(fileSettings,parameterSettings,classIndex);
    
    estimateLocationModel(fileSettings,parameterSettings,classIndex);
    
end

%% Segmentation and Visulization
for classIndex=1:4
    for sequenceIndex=1:8
        videoSegmentParts( fileSettings,parameterSettings,classIndex,sequenceIndex);
        visualizeSegments( fileSettings,parameterSettings,classIndex,sequenceIndex);
    end
end

%% Evaluation
% [ avgOverlapRatio, overlapRatio ] = ...
%     evaluate( fileSettings,parameterSettings, classIndex, sequenceIndices);

