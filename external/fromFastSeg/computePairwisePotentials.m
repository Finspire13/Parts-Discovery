function potentials = computePairwisePotentials( parameterSettings,...
                        superpixels,flow, colours, centres,labels,...
                        superpixelFrameIDs,cutsMask)

    [ sSource, sDestination ] = ...
        getSpatialConnections( superpixels, labels );
    [ tSource, tDestination, tConnections ] = ...
        getTemporalConnections( flow, superpixels, labels );

    sSqrColourDistance = sum( ( colours( sSource + 1, : ) - ...
        colours( sDestination + 1, : ) ) .^ 2, 2 ) ;
    sCentreDistance = sqrt( sum( ( centres( sSource + 1, : ) - ...
        centres( sDestination + 1, : ) ) .^ 2, 2 ) );
    tSqrColourDistance = sum( ( colours( tSource + 1, : ) - ...
        colours( tDestination + 1, : ) ) .^ 2, 2 ) ;

    sBeta = 0.5 / mean( sSqrColourDistance ./ sCentreDistance );
    tBeta = 0.5 / mean( tSqrColourDistance .* tConnections );

    sWeights = exp( -sBeta * sSqrColourDistance ) ./ sCentreDistance;
    tWeights = tConnections .* exp( -tBeta * tSqrColourDistance );
    
    %% Shape Term
    
    cWeights = zeros(size(sWeights));%cut weights
    
    for sPairIndex=1:length(sSource)
        sp1=sSource(sPairIndex)+1;
        sp2=sDestination(sPairIndex)+1;
        sp1FrameID=superpixelFrameIDs(sp1);
        sp2FrameID=superpixelFrameIDs(sp2);
        
        if sp1FrameID~=sp2FrameID
            continue;
        end
        
        sp1Mask=superpixels{sp1FrameID}==sp1;
        sp2Mask=superpixels{sp2FrameID}==sp2;
        
        for cutIndex=1:length(cutsMask{sp1FrameID})
            if isempty(cutsMask{sp1FrameID}{cutIndex})
                continue;
            end
            cutMask1=cutsMask{sp1FrameID}{cutIndex}(:,:,1);
            cutMask2=cutsMask{sp1FrameID}{cutIndex}(:,:,2);
            
            if (bwarea(and(cutMask1,sp1Mask))>0.5*bwarea(sp1Mask)&&...
                bwarea(and(cutMask2,sp2Mask))>0.5*bwarea(sp2Mask))||...
               (bwarea(and(cutMask2,sp1Mask))>0.5*bwarea(sp1Mask)&&...
                bwarea(and(cutMask1,sp2Mask))>0.5*bwarea(sp2Mask))
                
                cWeights(sPairIndex)=parameterSettings.shapeWeight;
                                           
                break;
            end
        end     
        
        
    end
    
    %%
    
    potentials.source = [ sSource; tSource ];
    potentials.destination = [ sDestination; tDestination ];
    potentials.value = [ ...
        (parameterSettings.spatialWeight * sWeights +cWeights); ...
        parameterSettings.temporalWeight * tWeights ];
    
end

