figure;
for i=1:length(flow)
    flowXY=flow{i};
    imshow(sqrt(flowXY(:,:,1).^2+flowXY(:,:,2).^2));
end

