function [ locationProbMap,occurrenceCount ] = estimateLocationModel(classIndex, fileSettings,parameterSettings)
%ESTIMATELOCATIONMODEL Summary of this function goes here
%   Detailed explanation goes here

dataPath=fileSettings.dataPath;
segmentsFile=fileSettings.segmentsFile;

frameType=fileSettings.frameType;
outputProposalsPath=fileSettings.outputProposalsPath;
outputProposalsFile=fileSettings.outputProposalsFile;
outputClusterResultFile=fileSettings.outputClusterResultFile;
outputMaxClustersFile=fileSettings.outputMaxClustersFile;

temporalInterval=parameterSettings.temporalInterval;
partsNum=parameterSettings.partsNum;
frameHeight=parameterSettings.frameHeight;
frameWidth=parameterSettings.frameWidth;
softMaskFactor=parameterSettings.softMaskFactor;
quantizedSpace=parameterSettings.quantizedSpace;
backgroundProbFactor=parameterSettings.backgroundProbFactor;

%%

inputPath=strcat(outputProposalsPath,'/',int2str(classIndex),'/',outputProposalsFile);
load(inputPath);
inputPath=strcat(outputProposalsPath,'/',int2str(classIndex),'/',outputClusterResultFile);
load(inputPath);
inputPath=strcat(outputProposalsPath,'/',int2str(classIndex),'/',outputMaxClustersFile);
load(inputPath);

occurrenceCount=zeros(quantizedSpace,quantizedSpace,partsNum+1);
for x=1:quantizedSpace
    for y=1:quantizedSpace
        for proposalIndex=1:size(proposalsAcrossVideo,1)
            if any(clusterResult(proposalIndex)==maxClusters)
                
                % -1.5~1.5 -1~1 -> 1 ~ 500 quantized mapping
                disquantizedX = x*3/quantizedSpace-1.5;
                disquantizedY = y*2/quantizedSpace-1;                 %!! may be wrong
                ppX=proposalsAcrossVideo(proposalIndex,1);
                ppY=proposalsAcrossVideo(proposalIndex,2);
                ppW=proposalsAcrossVideo(proposalIndex,3);
                ppH=proposalsAcrossVideo(proposalIndex,4);

                % check if in proposal
                if disquantizedX-ppX >=0 && disquantizedX-ppX <=ppW && disquantizedY-ppY >=0 && disquantizedY-ppY <=ppH
                    partLabel=find(maxClusters==clusterResult(proposalIndex));
                    occurrenceCount(y,x,partLabel)=occurrenceCount(y,x,partLabel)+1;     %y,x not x,y
                end
            end
        end
    end
    disp(x);
end

%for background
classes=dir(dataPath);
classes=classes(~ismember({classes.name},{'.','..'}));      % Remove . and ..
classPath=strcat(dataPath ,'/' , classes(classIndex).name);

sequences=dir(classPath);
sequences=sequences(~ismember({sequences.name},{'.','..'}));     % Remove . and ..

for sequenceIndex=1:length(sequences)
    sequencePath=strcat(classPath,'/',sequences(sequenceIndex).name);
    
    load(strcat(sequencePath,'/',segmentsFile));
    
    frames=dir([sequencePath strcat('/',frameType)]);
    for frameIndex=temporalInterval+1:length(frames)-temporalInterval-1
        framePath=strcat(sequencePath,'/',frames(frameIndex).name);
        
        softMask=imgaussfilt(double(segments{frameIndex}),softMaskFactor);
        
        
        
        prop=regionprops(segments{frameIndex});
        boundingBox=prop.BoundingBox;
        centroid=prop.Centroid;
        scale=sqrt(boundingBox(3)^2+boundingBox(4)^2);
        for x=1:quantizedSpace
            for y=1:quantizedSpace
                disquantizedX = x*3/quantizedSpace-1.5;
                disquantizedY = y*2/quantizedSpace-1;                 %!! may be wrong
                originalXY=round([disquantizedX disquantizedY].*scale+centroid);

                if originalXY(1)<1 ||originalXY(2)<1||originalXY(1)>frameWidth||originalXY(2)>frameHeight

                else
                    occurrenceCount(y,x,partsNum+1)=occurrenceCount(y,x,partsNum+1)+softMask(originalXY(2),originalXY(1));
                end
            end
        end
        disp(framePath);
    end
    
end
occurrenceCount(:,:,partsNum+1)=occurrenceCount(:,:,partsNum+1)*backgroundProbFactor;
occurrenceCount(:,:,partsNum+1)=max(max(occurrenceCount(:,:,partsNum+1)))-occurrenceCount(:,:,partsNum+1)+0.01;



locationProbMap=zeros(quantizedSpace,quantizedSpace,partsNum+1);
for l=1:partsNum+1
    occurrenceCount(:,:,l)=occurrenceCount(:,:,l)/max(max(occurrenceCount(:,:,l)));%normalize
    
    %occurrenceCount(:,:,l)=occurrenceCount(:,:,l)-0.5*max(max(occurrenceCount(:,:,l)));
    %occurrenceCount(:,:,l)=(1+exp(-1*occurrenceCount(:,:,l))).^-1; %sigmoid
%     
%     if l==partsNum+1
%         occurrenceCount(:,:,l)=occurrenceCount(:,:,l)*backgroundProbFactor;
%     end
    
    
    locationProbMap(:,:,l)=occurrenceCount(:,:,l)./sum(occurrenceCount,3);
end

[~,maxLabel]=max(locationProbMap,[],3);
figure;imagesc(maxLabel);

% occurrenceCount=zeros(quantizedSpace,quantizedSpace,partsNum+1);
% for x=1:quantizedSpace
%     for y=1:quantizedSpace
%         for proposalIndex=1:size(proposalsInVideo,1)
%             if any(clusterResult(proposalIndex)==maxClusters)
% 
%                 % -1.5~1.5 -1~1 -> 1 ~ 500 quantized mapping
%                 disquantizedX = x*3/quantizedSpace-1.5;
%                 disquantizedY = y*2/quantizedSpace-1;                 %!! may be wrong
%                 ppX=proposalsInVideo(proposalIndex,1);
%                 ppY=proposalsInVideo(proposalIndex,2);
%                 ppW=proposalsInVideo(proposalIndex,3);
%                 ppH=proposalsInVideo(proposalIndex,4);
% 
%                 % check if in proposal
%                 if disquantizedX-ppX >=0 && disquantizedX-ppX <=ppW && disquantizedY-ppY >=0 && disquantizedY-ppY <=ppH
%                     partLabel=find(maxClusters==clusterResult(proposalIndex));
%                     occurrenceCount(y,x,partLabel)=occurrenceCount(y,x,partLabel)+1;     %y,x not x,y
%                 end
%  
%             end
%         end
%     end
%     disp(x);
% end
% 
% %for background   
% foregroundProb=zeros(frameHeight,frameWidth,endFrame-startFrame+1);
% for frameIndex=startFrame:endFrame
%     foregroundProb(:,:,frameIndex)=imgaussfilt(double(segments{frameIndex}),softMaskFactor);
% end
% 
% for frameIndex=startFrame:endFrame
%     
%     prop=regionprops(segments{frameIndex});
%     boundingBox=prop.BoundingBox;
%     centroid=prop.Centroid;
%     scale=sqrt(boundingBox(3)^2+boundingBox(4)^2);
% 
%     
%     
%     
%     for x=1:quantizedSpace
%         for y=1:quantizedSpace
%             disquantizedX = x*3/quantizedSpace-1.5;
%             disquantizedY = y*2/quantizedSpace-1;                 %!! may be wrong
%             originalXY=round([disquantizedX disquantizedY].*scale+centroid);
% 
%             if originalXY(1)<1 ||originalXY(2)<1||originalXY(1)>frameWidth||originalXY(2)>frameHeight
%                 
%             else
%                 occurrenceCount(y,x,partsNum+1)=occurrenceCount(y,x,partsNum+1)+foregroundProb(originalXY(2),originalXY(1),frameIndex);
%             end
%         end
%     end
%     disp(frameIndex);
% end
% occurrenceCount(:,:,partsNum+1)=occurrenceCount(:,:,partsNum+1)*backgroundProbFactor;
% occurrenceCount(:,:,partsNum+1)=max(max(occurrenceCount(:,:,partsNum+1)))-occurrenceCount(:,:,partsNum+1)+0.01;
% 
% 
% 
% 
% locationProbMap=zeros(quantizedSpace,quantizedSpace,partsNum+1);
% 
% for x=1:quantizedSpace
%     for y=1:quantizedSpace
%         for l=1:partsNum+1
%             if sum(occurrenceCount(x,y,:))==0
%                 locationProbMap(x,y,l)=0;
%             else
%                 locationProbMap(x,y,l)=occurrenceCount(x,y,l)/sum(occurrenceCount(x,y,:));
%             end
%         end
%     end
% end
% 
% 
% [~,maxLabel]=max(locationProbMap,[],3);
% figure;imagesc(maxLabel);


end