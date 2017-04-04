% for i=1:21
%     figure;imagesc(occurrenceCount(:,:,i));
% end


% for frame=1:length(partsSegmentation)
%     if length(unique(partsSegmentation{frame}))==1
%         disp(frame);
%     end
% end

% for i=1:length(segments)
%     imshow(segments{i});
% end


foregroundSuperPixels=cell(length(superPixels),1);
for frame=1:length(superPixels)
    
    foregroundSPIndex=2;
    foregroundMask=segments{frame};
    foregroundMask=bwareafilt(foregroundMask,1);
    SPs=unique(superPixels{frame});
    
    temp=superPixels{frame};
    
    for sp=SPs'
        spMap=superPixels{frame};
        spMap(spMap~=sp)=0;
        
        if nnz(and(spMap,foregroundMask))>nnz(spMap)*foregroundSPCriteria
            temp(superPixels{frame}==sp)=foregroundSPIndex;
            foregroundSPIndex=foregroundSPIndex+1;
        else
            temp(superPixels{frame}==sp)=1;
        end
    end
    
    foregroundSuperPixels{frame}=temp;
    disp(frame);
end

% temp=superPixels{20};
% SPs=unique(temp);
% for sp=SPs'
%     temp(superPixels{20}==sp)=gtLabels{20}(sp);
% end
% imagesc(temp);