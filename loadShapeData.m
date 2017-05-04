function [ shapeCuts, cutsMask ] = ...
    loadShapeData( fileSettings,segments,classIndex,sequenceIndex)
%   Load shape data and compute cuts masks.
%--Input--
%   fileSettings: ...
%   segments: Foreground masks
%   classIndex: For which class to load shape data
%   sequenceIndex: For which sequence to load shape data
%--Output--
%   shapeCuts: Shape cuts loaded. Nx4 matrix.
%   cutsMask: Cuts masks. 

%% Load shape data

shapeDataPath=fileSettings.shapeDataPath;

classes=dir(shapeDataPath);
classes=classes(~ismember({classes.name},{'.','..','.gitignore'}));      % Remove . and ..
classPath=fullfile(shapeDataPath, classes(classIndex).name);

sequences=dir(classPath);
sequences=sequences(~ismember({sequences.name},{'.','..','.gitignore'}));     % Remove . and ..
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

