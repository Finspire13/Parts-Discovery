%% Compute optical flow using 'brox2010'

%% Set Paths and Parameters
dataPath = './data';
frameType = '*.jpg'; 
opticalFlowPath='./external/opticalFlow/brox2010';
opticalFlowFile='opticalFlow.mat';               

addpath(opticalFlowPath);

%% Compute Optical Flow
classes=dir(dataPath);
classes=classes(~ismember({classes.name},{'.','..','.gitignore'}));      % Remove . and ..
for classIndex=1:length(classes)
    classPath=fullfile(dataPath , classes(classIndex).name);
    sequences=dir(classPath);
    sequences=sequences(~ismember({sequences.name},{'.','..','.gitignore'}));     % Remove . and ..
    
    for sequenceIndex=1:length(sequences)
        sequencePath=fullfile(classPath,sequences(sequenceIndex).name);
        frames=dir([sequencePath strcat('/',frameType)]);
        
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
        outputPath=fullfile(sequencePath,opticalFlowFile);
        save(outputPath,'flow');
        
    end
    
end