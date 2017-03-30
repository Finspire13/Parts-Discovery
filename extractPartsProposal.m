function [ partsProposal,partsProposalMap ] =...
    extractPartsProposal( clusterResultMap, foregroundMask, quantizedSpace)
%   Extract part proposals from part proposals map.
%--Input--
%   partsProposalMap: Part proposals map.
%   foregroundMask: Foreground mask.
%--Output--
%   partsProposal: Nx4 matrix of part proposals.


ppLabels=unique(clusterResultMap);
ppLabels=ppLabels(ppLabels~=0);
ppNum=length(ppLabels);

partsProposal=zeros(ppNum,3);
partsProposalMap=zeros(quantizedSpace,quantizedSpace,ppNum);

prop=regionprops(foregroundMask);
foregroundBB=prop.BoundingBox;

croppedClusterResultMap=imcrop(clusterResultMap,foregroundBB);
resizedClusterResultMap=imresize(croppedClusterResultMap,...
                                [quantizedSpace quantizedSpace],'nearest');
for ppIndex=1:ppNum

    ppMap=resizedClusterResultMap==ppLabels(ppIndex);
    ppMap=bwareafilt(ppMap,1);

    prop=regionprops(ppMap);
    %ppBB=prop.BoundingBox;      %[left corner  size]
    ppCentroid=prop.Centroid;
    ppArea=prop.Area;

    ppX=ppCentroid(1);
    ppY=ppCentroid(2);
    ppScale=sqrt(ppArea);

    partsProposal(ppIndex,:)=[ppX ppY ppScale];
    partsProposalMap(:,:,ppIndex)=ppMap;
end

end

