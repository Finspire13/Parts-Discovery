%% Set Paths and Parameters
dataPath = './data';
%classList= {'horseLeft','horseRight','tigerLeft','tigerRight'};
frameType='*.jpg';
opticalFlowPath='./external/opticalFlow/brox2010';
outputFile='opticalFlow.mat';                                                                                                                                                                                

frameHeight=225;
frameWidth=400;

addpath(opticalFlowPath);

%% Compute Optical Flow
classes=dir(dataPath);
classes=classes(~ismember({classes.name},{'.','..'}));      % Remove . and ..
for classIndex=1:length(classes)
    classPath=fullfile(dataPath , classes(classIndex).name);
    sequences=dir(classPath);
    sequences=sequences(~ismember({sequences.name},{'.','..'}));     % Remove . and ..
    
    for sequenceIndex=1:length(sequences)
        sequencePath=fullfile(classPath,sequences(sequenceIndex).name);
        frames=dir([sequencePath strcat('/',frameType)]);
        %frames=frames(~ismember({frames.name},{'.','..'}));
        
        flow=cell(1,length(frames)-1);
        for frameIndex=1:length(frames)-1
            currentFramePath=fullfile(sequencePath,frames(frameIndex).name);
            nextFramePath=fullfile(sequencePath,frames(frameIndex+1).name);
            disp(currentFramePath);
            
            currentFrame=imread(currentFramePath);
            nextFrame=imread(nextFramePath);
            
            currentFlow=int16(mex_LDOF(double(currentFrame),double(nextFrame)));
            flow{frameIndex}( :, :, 1 )=currentFlow( :, :, 2 );
            flow{frameIndex}( :, :, 2 )=currentFlow( :, :, 1 );
        end
        outputPath=fullfile(sequencePath,outputFile);
        save(outputPath,'flow');
        
    end
    
end