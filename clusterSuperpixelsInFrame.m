function [ partsProposal,partsProposalMap,clusterResultMap ] = clusterSuperpixelsInFrame( flow,temporalSP,segments, frame,parameterSettings )
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
foregroundMask=segments{frame};
if sum(sum(foregroundMask))==0    %check for empty mask
    partsProposal=[];
    partsProposalMap=[];
    clusterResultMap=zeros(size(temporalSP{frame}));
else
    foregroundMask=bwareafilt(foregroundMask,1);
    quantizedSpace=parameterSettings.quantizedSpace;
    temporalInterval=parameterSettings.temporalInterval;
    partsNum=parameterSettings.partsNum;

    superpixels=unique(temporalSP{frame});
    foregroundSPMap=uint32(zeros(size(temporalSP{frame})));
    for spIndex=1:length(superpixels)
        spMap=temporalSP{frame};
        spMap(spMap~=superpixels(spIndex))=0;
        if nnz(and(spMap,foregroundMask))>nnz(spMap)*0.75
            foregroundSPMap=foregroundSPMap+spMap;
        else
            superpixels(spIndex)=0;
        end
    end

    foregroundSP=superpixels(superpixels~=0);
    if length(foregroundSP)<=1
        partsProposal=[];
        partsProposalMap=[];
        clusterResultMap=zeros(size(temporalSP{frame}));
    else
        distfunHandler=@(spI,spJs)getMotionDistance(spI,spJs,frame,temporalSP,flow,temporalInterval);

        distanceVector=pdist(foregroundSP,distfunHandler);
        links=linkage(distanceVector,'single');   %!! why complete?
        clusterResult=cluster(links,'maxclust',ceil(partsNum*0.7));  %!!!!!!!!!!!!!!!!!!!!!!!
        %clusterResult=cluster(links,'cutoff',1.15);

        clusterResultMap=foregroundSPMap;
        for i=1:length(foregroundSP)
            clusterResultMap(clusterResultMap==foregroundSP(i))=clusterResult(i);
        end

        [partsProposal,partsProposalMap]=extractPartsProposal(clusterResultMap,foregroundMask,quantizedSpace);
    end


    %figure;dendrogram(links,480);
    %figure;imagesc(partsProposalMap);
    %figure;imshow('data/horseLeft/1/175.jpg');

end

end

