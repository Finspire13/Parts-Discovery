%% Compute optical flow using 'FlowNet'

addpath('./external/opticalFlowUtil');

classes=dir('./data');
classes=classes(~ismember({classes.name},{'.','..','.gitignore'}));      % Remove . and ..
for classIndex=1:length(classes)
    classPath=fullfile('./data' , classes(classIndex).name);
    sequences=dir(classPath);
    sequences=sequences(~ismember({sequences.name},{'.','..','.gitignore'}));     % Remove . and ..
    
    for sequenceIndex=1:length(sequences)
        sequencePath=fullfile(classPath,sequences(sequenceIndex).name);
        
        frames=readFrames(fileSettings,classIndex,sequenceIndex);
        for i=1:length(frames)
             imwrite(frames{i},sprintf('./tmp/%03d.ppm',i));
        end

        fileName1='./external/opticalFlow/FlowNet/models/FlowNetC/img1_list.txt';
        fileName2='./external/opticalFlow/FlowNet/models/FlowNetC/img2_list.txt';
        file1=fopen(fileName1,'w');
        file2=fopen(fileName2,'w');

        for i=1:length(frames)-1
            fprintf(file1,'data/%03d.ppm\n',i);
        end
        for i=2:length(frames)
            fprintf(file2,'data/%03d.ppm\n',i);
        end

        fclose(file1);
        fclose(file2);
        
        system('./external/opticalFlow/FlowNet/models/FlowNetC/run.py img1_list.txt img2_list.txt');
        
        flow=cell(length(frames)-1,1);
        for i=1:length(frames)-1
            currentFlow=readFlowFile(sprintf('./external/opticalFlow/FlowNet/models/FlowNetC/flownets-pred-%07d.flo',i-1));
            flow{i}=int16(currentFlow);
        end

        outputPath=fullfile(sequencePath,'flow_flownet.mat');
        save(outputPath,'flow','-v7.3');
        
        disp(sequenceIndex);
    end
    
end
