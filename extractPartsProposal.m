function [ partsProposal ] = extractPartsProposal( partsProposalMap, foregroundMask )
%   Extract part proposals from part proposals map.
%--Input--
%   partsProposalMap: Part proposals map.
%   foregroundMask: Foreground mask.
%--Output--
%   partsProposal: Nx4 matrix of part proposals.

if sum(sum(foregroundMask))==0    %check for empty mask
    partsProposal=[];
else
    ppLabels=unique(partsProposalMap);
    partsProposal=zeros(length(ppLabels),4);
    for index=1:length(ppLabels)
        partMap=partsProposalMap==ppLabels(index);
        partMap=bwareafilt(partMap,1);

        prop=regionprops(partMap);
        boundingBox=prop.BoundingBox;      %[left corner  size]

        %check for background
        if boundingBox(3)==size(partMap,2) || boundingBox(4)==size(partMap,1)
            continue;
        end

        bbX=boundingBox(1)+0.5*boundingBox(3);
        bbY=boundingBox(2)+0.5*boundingBox(4);
        [commonXY,scale]=getCommonCoordinate([bbX bbY],foregroundMask);
        scaledWidth=boundingBox(3)/scale;
        scaledHeight=boundingBox(4)/scale;
        partsProposal(index,:)=[commonXY scaledWidth scaledHeight];
    end

    partsProposal(all(partsProposal==0,2),:)=[]; %remove rows of all zeros
end

end

