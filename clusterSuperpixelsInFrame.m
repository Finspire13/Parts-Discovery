function [ partsProposal,partsProposalMap ] = clusterSuperpixelsInFrame( flow,temporalSP,segments, frame,interval,partsNum )
%   Cluster superpixels in frame using hierarchical clustering with motion
%   distance.
%--Inupt--
%   flow: Opticcal flow fields.
%   temporalSP: Temporal superpixels maps.
%   segments: Foreground masks.
%   frame: Frame index
%   interval: Temporal interval size to find connected superpixels.
%   partsNum: Number of parts to find.
%--Output--
%   partsProposal: Nx4 matrix of part proposals.
%   partsProposalMap: Part proposals map.

superpixels=unique(temporalSP{frame});

distfunHandler=@(spI,spJs)getMotionDistance(spI,spJs,frame,temporalSP,flow,interval);

distanceVector=pdist(superpixels,distfunHandler);
links=linkage(distanceVector,'complete');   %!! why complete?
clusterResult=cluster(links,'maxclust',partsNum+1);

partsProposalMap=temporalSP{frame};
for i=1:length(superpixels)
    partsProposalMap(partsProposalMap==superpixels(i))=clusterResult(i);
end

partsProposal=extractPartsProposal(partsProposalMap,segments{frame});

%figure;dendrogram(links,480);
%figure;imagesc(partsProposalMap);
%figure;imshow('data/horseLeft/1/175.jpg');

end

