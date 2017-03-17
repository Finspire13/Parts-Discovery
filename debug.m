% figure;
% for i=1:length(temporalSP)
%     temp=double(temporalSP{i})/double(max(max(temporalSP{i})));
%     imshow(temp);
% end

% count=zeros(15490,1);
% for i=1:length(temporalSP)
%     count(unique(temporalSP{i}))=count(unique(temporalSP{i}))+1;
% end
% 
% count=count(count~=0);\


% figure;
% for i=1:length(segments)
%     imshow(segments{i});
% end
for i=1:671
    gt=gtLabels{i};
    if ~isempty(gt)
        
        sps=unique(superPixels{i});
        map=superPixels{i};
        for j=1:length(sps)
            map(map==sps(j))=gt(j);
        end
        figure;imshow(segments{i});
        figure;imagesc(map);
    end
end

for i=1:21
    figure;imagesc(occurrenceCount(:,:,i)>0.5*max(max(occurrenceCount(:,:,i))));
end

bodyClusterIndex=0;
minBodyClusterEnergy=Inf;
for i=1:clusterNum
    mask=occurrenceCount(:,:,i)>0.5*max(max(occurrenceCount(:,:,i)));
    area=bwarea(mask);
    if area>quantizedSpace*quantizedSpace*0.25&&clusterEnergy(i)<minBodyClusterEnergy
        if bodyClusterIndex~=0
            clusterEnergy(bodyClusterIndex)=Inf;
        end
        minBodyClusterEnergy=clusterEnergy(i);
        bodyClusterIndex=i;
    end
end
if bodyClusterIndex~=0
    clusterEnergy(bodyClusterIndex)=0;
end

for i=1:clusterNum
    for j=i+1:clusterNum
        maskI=occurrenceCount(:,:,i)>0.5*max(max(occurrenceCount(:,:,i)));
        maskJ=occurrenceCount(:,:,j)>0.5*max(max(occurrenceCount(:,:,j)));
        areaI=bwarea(maskI);
        areaJ=bwarea(maskJ);
        if areaI>=areaJ 
            overlapratio=bwarea(and(maskI,maskJ))/areaJ;
            if overlapratio>0.85 && clusterEnergy(i)~=Inf
                clusterEnergy(j)=Inf;
            end
        else
            overlapratio=bwarea(and(maskI,maskJ))/areaI;
            if overlapratio>0.85 && clusterEnergy(j)~=Inf
                clusterEnergy(i)=Inf;
            end
        end
    end
end