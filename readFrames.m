function [ frameCells ] = ...
    readFrames( fileSettings,classIndex,sequenceIndices)
%READFRAMES Summary of this function goes here
%   Detailed explanation goes here

dataPath=fileSettings.dataPath;
frameType=fileSettings.frameType;
%%
classes=dir(dataPath);
classes=classes(~ismember({classes.name},{'.','..'}));      % Remove . and ..
classPath=fullfile(dataPath, classes(classIndex).name);

sequences=dir(classPath);
sequences=sequences(~ismember({sequences.name},{'.','..'}));     % Remove . and ..

if nargin==2
    sequenceIndices=1:length(sequences);
end

frameCells={};
cellIndex=1;
for sequenceIndex=sequenceIndices
    sequencePath=fullfile(classPath,sequences(sequenceIndex).name);
    frames=dir([sequencePath strcat('/',frameType)]);

    for frameIndex=1:length(frames)
        framePath=fullfile(sequencePath,frames(frameIndex).name);
        currentFrame=imread(framePath);
        frameCells{cellIndex}=currentFrame;
        cellIndex=cellIndex+1;
    end
end

end

