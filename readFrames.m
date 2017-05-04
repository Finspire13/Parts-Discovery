function [ frameCells ] = ...
    readFrames( fileSettings,classIndex,sequenceIndices)
%   Load RGB frames
%--Input--
%   fileSettings: ...
%   classIndex: For which class to load frames
%   sequenceIndices: For which sequences to load frames
%--Output--
%   frameCells: RGB frames

dataPath=fileSettings.dataPath;
frameType=fileSettings.frameType;
%%
classes=dir(dataPath);
classes=classes(~ismember({classes.name},{'.','..','.gitignore'}));      % Remove . and ..
classPath=fullfile(dataPath, classes(classIndex).name);

sequences=dir(classPath);
sequences=sequences(~ismember({sequences.name},{'.','..','.gitignore'}));     % Remove . and ..

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

