function [ shapeCuts, cutsMask ] = ...
    loadShapeData( fileSettings,segments,classIndex,sequenceIndex)
%LOADSHAPEDATA Summary of this function goes here
%   Detailed explanation goes here
%%

shapeDataPath=fileSettings.shapeDataPath;

classes=dir(shapeDataPath);
classes=classes(~ismember({classes.name},{'.','..'}));      % Remove . and ..
classPath=fullfile(shapeDataPath, classes(classIndex).name);

sequences=dir(classPath);
sequences=sequences(~ismember({sequences.name},{'.','..'}));     % Remove . and ..
sequencePath=fullfile(classPath,sequences(sequenceIndex).name);

frames=dir([sequencePath strcat('/','*.txt')]);

shapeCuts=cell(length(frames),1);
cutsMask=cell(length(frames),1);

for frameIndex=1:length(frames)
    framePath=fullfile(sequencePath,frames(frameIndex).name);
    frameCuts=importdata(framePath);
    shapeCuts{frameIndex}=frameCuts;

    cutsMask{frameIndex}=getCutsMask(frameCuts,segments{frameIndex});
end

end

