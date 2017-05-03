function [ partsProposal,partsProposalMap ] =...
    extractPartsProposal( clusterResultMap, foregroundMask, quantizedSpace)
%   Extract part proposals from cluster result map of foreground superpixels
%--Input--
%   clusterResultMap: Cluster result map of foreground superpixels
%   foregroundMask: Foreground mask.
%   quantizedSpace: Size of quantized space where location model locates
%--Output--
%   partsProposal: Nx3 matrix of part proposals
%   partsProposalMap: HxWxN matrix of part proposal maps

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
    ppCentroid=prop.Centroid;
    ppArea=prop.Area;

    ppX=ppCentroid(1);
    ppY=ppCentroid(2);
    ppScale=sqrt(ppArea);

    % Use coordinate of part proposal centroid and square root of part proposal area to describe
    partsProposal(ppIndex,:)=[ppX ppY ppScale];
    partsProposalMap(:,:,ppIndex)=ppMap;
end

end

