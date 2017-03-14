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
    classPath=strcat(dataPath ,'/' , classes(classIndex).name);
    sequences=dir(classPath);
    sequences=sequences(~ismember({sequences.name},{'.','..'}));     % Remove . and ..
    
    for sequenceIndex=1:length(sequences)
        sequencePath=strcat(classPath,'/',sequences(sequenceIndex).name);
        frames=dir([sequencePath strcat('/',frameType)]);
        %frames=frames(~ismember({frames.name},{'.','..'}));
        
        flow=cell(1,length(frames)-1);
        for frameIndex=1:length(frames)-1
            currentFramePath=strcat(sequencePath,'/',frames(frameIndex).name);
            nextFramePath=strcat(sequencePath,'/',frames(frameIndex+1).name);
            disp(currentFramePath);
            
            currentFrame=imread(currentFramePath);
            nextFrame=imread(nextFramePath);
            
            currentFlow=mex_LDOF(double(currentFrame),double(nextFrame));
            flow{frameIndex}=currentFlow;
        end
        outputPath=strcat(sequencePath,'/',outputFile);
        save(outputPath,'flow');
        
    end
    
end