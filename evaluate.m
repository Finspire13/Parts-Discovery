function [ avgOverlapRatio, overlapRatio ] =...
    evaluate( fileSettings,parameterSettings, classIndex, sequenceIndices)
%EVALUATE Summary of this function goes here
%   Detailed explanation goes here
dataPath=fileSettings.dataPath;
gtLabelsFile=fileSettings.gtLabelsFile;
superPixelsFile=fileSettings.superPixelsFile;
partsSegmentationFile=fileSettings.partsSegmentationFile;
partsSegmentationPath=fileSettings.partsSegmentationPath;

partsNum=parameterSettings.partsNum;
%%
classes=dir(dataPath);
classes=classes(~ismember({classes.name},{'.','..'}));      % Remove . and ..
classPath=fullfile(dataPath , classes(classIndex).name);

sequences=dir(classPath);
sequences=sequences(~ismember({sequences.name},{'.','..'}));     % Remove . and ..

labelMappingMethod='perVideo';
if nargin==3
    sequenceIndices=1:length(sequences);
    labelMappingMethod='perClass';
end

gtLabelsSet=cell(1,length(sequenceIndices));
gtMasksSet=cell(1,length(sequenceIndices));
partsSegmentationSet=cell(1,length(sequenceIndices));
for sIndex=1:length(sequenceIndices)
    sequencePath=fullfile(classPath,sequences(sequenceIndices(sIndex)).name);
    load(fullfile(sequencePath,gtLabelsFile),'gtLabels');
    load(fullfile(sequencePath,superPixelsFile),'superPixels');
    load(fullfile(partsSegmentationPath,int2str(classIndex),...
                  int2str(sequenceIndices(sIndex)),...
                  partsSegmentationFile),'partsSegmentation');
    
    gtMasks=cell(length(gtLabels),1);
    for frame=1:length(gtLabels)
        if ~isempty(gtLabels{frame})
            gtLabel=gtLabels{frame};
            gtMask=superPixels{frame};
            for sp=1:length(gtLabel)
                gtMask(gtMask==sp)=gtLabel(sp);
            end
            gtMasks{frame}=gtMask;
        end
    end
    
    gtLabelsSet{sIndex}=gtLabels;
    gtMasksSet{sIndex}=gtMasks;
    partsSegmentationSet{sIndex}=partsSegmentation;
    
end

%%
labelMapping=zeros(partsNum+1,length(sequenceIndices));
if strcmp(labelMappingMethod,'perVideo')
    
    for sIndex=1:length(sequenceIndices)
        gtLabels=gtLabelsSet{sIndex};
        gtMasks=gtMasksSet{sIndex};
        partsSegmentation=partsSegmentationSet{sIndex};
        
        for i=[partsNum+1 1:partsNum]
            maxOverlapRatioSum=0;
            maxJ=-1;
            for j=1:partsNum+1
                if nnz(labelMapping(:,sIndex)==j)==0
                    overlapRatioSum=0;
                    for frame=1:length(partsSegmentation)
                        if ~isempty(gtLabels{frame})
                            gtMask=gtMasks{frame};
                            
                            andArea=bwarea(and(gtMask==j,...
                                             partsSegmentation{frame}==i));
                            orArea=bwarea(or(gtMask==j,...
                                             partsSegmentation{frame}==i));
                            if orArea==0
                                tempOverlapRatio=0;
                            else
                                tempOverlapRatio=andArea/orArea;
                            end
                            overlapRatioSum=...
                                overlapRatioSum+tempOverlapRatio;
                        end
                    end
                    if overlapRatioSum>=maxOverlapRatioSum
                        maxOverlapRatioSum=overlapRatioSum;
                        maxJ=j;
                    end
                end
            end
            labelMapping(i,sIndex)=maxJ;
            disp(i);
        end
    end
    
elseif strcmp(labelMappingMethod,'perClass')
    
    gtLabels={};
    gtMasks={};
    partsSegmentation={};

    for sIndex=1:length(sequenceIndices)
        gtLabels=[gtLabels;gtLabelsSet{sIndex}];
        gtMasks=[gtMasks;gtMasksSet{sIndex}];
        partsSegmentation=[partsSegmentation partsSegmentationSet{sIndex}];
    end
        
    for i=[partsNum+1 1:partsNum]
        maxOverlapRatioSum=0;
        maxJ=-1;
        for j=1:partsNum+1
            if nnz(labelMapping==j)==0
                overlapRatioSum=0;
                for frame=1:length(partsSegmentation)
                    if ~isempty(gtLabels{frame})
                        gtMask=gtMasks{frame};
                        
                        andArea=bwarea(and(gtMask==j,...
                                             partsSegmentation{frame}==i));
                        orArea=bwarea(or(gtMask==j,...
                                         partsSegmentation{frame}==i));
                        if orArea==0
                            tempOverlapRatio=0;
                        else
                            tempOverlapRatio=andArea/orArea;
                        end
                        overlapRatioSum=overlapRatioSum+tempOverlapRatio;
                    end
                end
                if overlapRatioSum>=maxOverlapRatioSum
                    maxOverlapRatioSum=overlapRatioSum;
                    maxJ=j;
                end
            end
        end
        labelMapping(i,:)=maxJ;
        disp(i);
    end
end

%%
overlapRatio={};
for sIndex=1:length(sequenceIndices)
    gtLabels=gtLabelsSet{sIndex};
    gtMasks=gtMasksSet{sIndex};
    partsSegmentation=partsSegmentationSet{sIndex};
    
    overlapRatioInSequence=[];
    for frame=1:length(partsSegmentation)
        if ~isempty(gtLabels{frame})
            overlapRatioInFrame=zeros(partsNum+1,1);

            gtMask=gtMasks{frame};

            for i=1:partsNum+1
                andArea=bwarea(and(gtMask==labelMapping(i,sIndex),...
                                   partsSegmentation{frame}==i));
                orArea= bwarea(or(gtMask==labelMapping(i,sIndex),...
                                  partsSegmentation{frame}==i));
                if orArea==0
                    overlapRatioInFrame(i)=0;
                else  
                    overlapRatioInFrame(i)=andArea/orArea;
                end
            end
            overlapRatioInSequence=...
                [overlapRatioInSequence overlapRatioInFrame];
            disp(frame);
        end
    end
    overlapRatio{sIndex}=overlapRatioInSequence;
end

temp=cellfun(@(x)mean(x,2),overlapRatio,'UniformOutput',false);
temp=cellfun(@mean,temp);
avgOverlapRatio=mean(temp);




end

