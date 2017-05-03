function [  ] =...
    visualizeSegments( fileSettings,parameterSettings,...
                       classIndex,sequenceIndex)
%   Visualize parts segmentation
%--Input--
%   fileSettings: ...
%   parameterSettings: ...
%   classIndex: For which class to visualize
%   sequenceIndex: For which sequence to visualize
%--Output--
%   outputVideo: Visualization of parts segmentation. (Saved to file)

%% Get Settings

partsSegmentationFile=fileSettings.partsSegmentationFile;
partsSegmentationPath=fileSettings.partsSegmentationPath;
visualizationPath=fileSettings.visualizationPath;
visualizationFile=fileSettings.visualizationFile;

partsNum=parameterSettings.partsNum;

%% Color Set

colors=[255 0 0;
    101 255 0;
    0 255 101;
    0 203 255;
    0 0 255;
    255 0 203;
    255 204 0;
    255 0 102;
    102 0 255;
    203 0 255;
    0 0 0;
    ];


%% Visualize parts segmentation

tic;
load(fullfile(partsSegmentationPath,int2str(classIndex),...
              int2str(sequenceIndex),partsSegmentationFile),...
              'partsSegmentation');
frameCells = readFrames( fileSettings,classIndex,sequenceIndex);

outputPath=fullfile(visualizationPath,int2str(classIndex),...
                    int2str(sequenceIndex),visualizationFile);
outputVideo=VideoWriter(outputPath);
open(outputVideo);

for frameIndex=1:length(frameCells)
    frame=frameCells{frameIndex};
    frame=uint16(frame);
    frameR=frame(:,:,1);
    frameG=frame(:,:,2);
    frameB=frame(:,:,3);
    partsSegmentationInFrame=partsSegmentation{frameIndex};
    
    for partIndex=1:partsNum+1
        
        frameR(partsSegmentationInFrame==partIndex)=...
            frameR(partsSegmentationInFrame==partIndex)+0.5*colors(partIndex,1);
        frameR(frameR>255)=255;
        frameR(frameR<0)=0;
        
        frameG(partsSegmentationInFrame==partIndex)=...
            frameG(partsSegmentationInFrame==partIndex)+0.5*colors(partIndex,2);
        frameG(frameG>255)=255;
        frameG(frameG<0)=0;
        
        frameB(partsSegmentationInFrame==partIndex)=...
            frameB(partsSegmentationInFrame==partIndex)+0.5*colors(partIndex,3);
        frameB(frameB>255)=255;
        frameB(frameB<0)=0;
        
    end
    
    frame(:,:,1)=frameR;
    frame(:,:,2)=frameG;
    frame(:,:,3)=frameB;
    frame=uint8(frame);
    writeVideo(outputVideo,frame);
end

close(outputVideo);

fprintf('Visualization generated for sequence %d class %d... ',...
        sequenceIndex,classIndex);
toc

end

