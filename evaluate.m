function [ avgOverlapRatio, overlapRatio ] =...
    evaluate( fileSettings,parameterSettings, classIndex, sequenceIndices)
%   Evaluation of part segmentation result
%--Inupt--
%   fileSettings:...
%   parameterSettings:...
%   classIndex: For which class to evaluate
%   sequenceIndices: For which sequence to evaluate. If this parameter is 
%                    given, 'IoU per video' is computed. If not, 'IoU per class' is computed.
%--Output--
%   avgOverlapRatio: Average IoU
%   overlapRatio: Detailed IoU for each part in each frame

%% Get Settings

dataPath=fileSettings.dataPath;
gtLabelsFile=fileSettings.gtLabelsFile;
superPixelsFile=fileSettings.superPixelsFile;
partsSegmentationFile=fileSettings.partsSegmentationFile;
partsSegmentationPath=fileSettings.partsSegmentationPath;

partsNum=parameterSettings.partsNum;


%% Precompute all parts overlap ratio

classes=dir(dataPath);
classes=classes(~ismember({classes.name},{'.','..','.gitignore'}));      % Remove . and ..
classPath=fullfile(dataPath , classes(classIndex).name);

sequences=dir(classPath);
sequences=sequences(~ismember({sequences.name},{'.','..','.gitignore'}));     % Remove . and ..

labelMappingMethod='perVideo';
if nargin==3
    sequenceIndices=1:length(sequences);
    labelMappingMethod='perClass';
end

fprintf('Start evaluating...\n');
tic;

partOverlapRatiosSet=cell(1,length(sequenceIndices));
for sIndex=1:length(sequenceIndices)
    sequencePath=fullfile(classPath,sequences(sequenceIndices(sIndex)).name);
    load(fullfile(sequencePath,gtLabelsFile),'gtLabels');
    load(fullfile(sequencePath,superPixelsFile),'superPixels');
    load(fullfile(partsSegmentationPath,int2str(classIndex),...
                  int2str(sequenceIndices(sIndex)),...
                  partsSegmentationFile),'partsSegmentation');
    
    partOverlapRatiosVolume=[];
    for frame=1:length(gtLabels)
        if ~isempty(gtLabels{frame})
            gtLabel=gtLabels{frame};
            gtMask=superPixels{frame};
            for sp=1:length(gtLabel)
                gtMask(gtMask==sp)=gtLabel(sp);
            end
            
            partOverlapRatio=zeros(partsNum+1,partsNum+1);
            for i=1:partsNum+1
                for j=1:partsNum+1
                    andArea=bwarea(and(gtMask==j,...
                                   partsSegmentation{frame}==i));
                    orArea=bwarea(or(gtMask==j,...
                                  partsSegmentation{frame}==i));
                    if orArea==0
                        partOverlapRatio(i,j)=0;
                    else
                        partOverlapRatio(i,j)=andArea/orArea;
                    end
                end
            end
            partOverlapRatiosVolume=cat(3,partOverlapRatiosVolume,...
                                        partOverlapRatio);
        end
    end
    
    partOverlapRatiosSet{sIndex}=partOverlapRatiosVolume;
end

fprintf('All parts overlap ratio precomputed... ');toc
tic;

%% Exhausted search of label mapping

labelMapping=zeros(partsNum+1,length(sequenceIndices));
permulations=perms(1:partsNum+1);
if strcmp(labelMappingMethod,'perVideo')
    
    for sIndex=1:length(sequenceIndices)
        partOverlapRatiosVolume=partOverlapRatiosSet{sIndex};
        partOverlapRatioSums=sum(partOverlapRatiosVolume,3);

        maxOverlapRatioSum=0;
        maxPerm=0;
        for permIndex=1:size(permulations,1)
            overlapRatioSum=0;
            for i=1:partsNum+1
                overlapRatioSum=overlapRatioSum+...
                partOverlapRatioSums(i,permulations(permIndex,i));
            end
            if overlapRatioSum>=maxOverlapRatioSum
                maxOverlapRatioSum=overlapRatioSum;
                maxPerm=permIndex;
            end
        end
        labelMapping(:,sIndex)=permulations(maxPerm,:)';
    end
    
elseif strcmp(labelMappingMethod,'perClass')
   
    partOverlapRatiosVolume=[];

    for sIndex=1:length(sequenceIndices)
        partOverlapRatiosVolume=cat(3,partOverlapRatiosVolume,...
                                    partOverlapRatiosSet{sIndex});
    end
    
    partOverlapRatioSums=sum(partOverlapRatiosVolume,3);
        
    maxOverlapRatioSum=0;
    maxPerm=0;
    for permIndex=1:size(permulations,1)
        overlapRatioSum=0;
        for i=1:partsNum+1
            overlapRatioSum=overlapRatioSum+...
            partOverlapRatioSums(i,permulations(permIndex,i));
        end
        if overlapRatioSum>=maxOverlapRatioSum
            maxOverlapRatioSum=overlapRatioSum;
            maxPerm=permIndex;
        end
    end
    labelMapping(:,:)=repmat(permulations(maxPerm,:)',...
                             [1,length(sequenceIndices)]);
    
end

fprintf('Parts label mapped...  ');toc
tic;

%% Compute IoUs

overlapRatio={};
for sIndex=1:length(sequenceIndices)
    partOverlapRatiosVolume=partOverlapRatiosSet{sIndex};
    
    overlapRatioInSequence=[];
    for frame=1:size(partOverlapRatiosVolume,3)
        overlapRatioInFrame=zeros(partsNum+1,1);
        partOverlapRatio=partOverlapRatiosVolume(:,:,frame);
        for i=1:partsNum+1
            overlapRatioInFrame(i)=...
                partOverlapRatio(i,labelMapping(i,sIndex));
        end
        overlapRatioInSequence=...
            [overlapRatioInSequence overlapRatioInFrame];
    end
    overlapRatio{sIndex}=overlapRatioInSequence;
end

temp=cellfun(@(x)mean(x,2),overlapRatio,'UniformOutput',false);
temp=cellfun(@mean,temp);
avgOverlapRatio=mean(temp);

fprintf('Average parts overlap ratio computed...  ');toc

end

