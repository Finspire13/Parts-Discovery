function [ partsProposal,partsProposalMap ] = clusterSuperpixelsInFrame( flow,temporalSP,segments, frame,interval,partsNum )
%CLUSTERSUPERPIXELSINFRAME Summary of this function goes here
%   Detailed explanation goes here

superpixels=unique(temporalSP{frame});


distfunHandler=@(spI,spJs)getMotionDistance(spI,spJs,frame,temporalSP,flow,interval);

distanceVector=pdist(superpixels,distfunHandler);
links=linkage(distanceVector,'complete');
clusterResult=cluster(links,'maxclust',partsNum+1);

partsProposalMap=temporalSP{frame};
for i=1:length(superpixels)
    partsProposalMap(find(partsProposalMap==superpixels(i)))=clusterResult(i);
end

partsProposal=extractPartsProposal(partsProposalMap,segments{frame});

%figure;dendrogram(links,480);
%figure;imagesc(partsProposalMap);
%figure;imshow('data/horseLeft/1/175.jpg');

end

