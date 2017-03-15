%%
% alpha=5;   % balance between var and velo
% beta=15;   % broken penalty
% 
% spJsNum=size(spJs,1);

% temporalSP=cat(3,temporalSP{:});
% flow=cat(3,flow{:});
% flowXs=flow(:,:,1:2:size(flow,3));
% flowYs=flow(:,:,2:2:size(flow,3));
% 
% temporalSPInInterval=temporalSP(:,:,f-interval:f+interval);
% flowXsInInterval=flowXs(:,:,f-interval:f+interval);
% flowYsInInterval=flowYs(:,:,f-interval:f+interval);

% motionDistances=zeros(spJsNum,1);   % motionDistances=centerDistances+velocityDistances
% centerDistances=zeros(spJsNum,2*interval+1);
% velocityDistances=zeros(spJsNum,2*interval+1);

% centerSpI=zeros(2,2*interval+1);
% centerSpJs=zeros(2,2*interval+1,spJsNum);
% velocitySpI=zeros(2,2*interval+1);
% velocitySpJs=zeros(2,2*interval+1,spJsNum);
% 
% 
% spIPixelIndex=find(temporalSPInInterval==spI);
% [spIRows,spICols,spIZs]=ind2sub(size(temporalSPInInterval),spIPixelIndex);
% for zIndex=1:2*interval+1
%     centerSpI(:,zIndex)=[mean(spIRows(spIZs==zIndex)) mean(spICols(spIZs==zIndex))];
%     
%     flowIndex=sub2ind(size(temporalSPInInterval),spIRows(spIZs==zIndex),spICols(spIZs==zIndex),spIZs(spIZs==zIndex));
%     velocitySpI(:,zIndex)=[mean(flowXsInInterval(flowIndex)) mean(flowYsInInterval(flowIndex))];
% end
% 
% for spJIndex=1:length(spJs)
%     spJPixelIndex=find(temporalSPInInterval==spJs(spJIndex));
%     [spJRows,spJCols,spJZs]=ind2sub(size(temporalSPInInterval),spJPixelIndex);
%     for zIndex=1:2*interval+1
%         centerSpJs(:,zIndex,spJIndex)=[mean(spJRows(spJZs==zIndex)) mean(spJCols(spJZs==zIndex))];
% 
%         flowIndex=sub2ind(size(temporalSPInInterval),spJRows(spJZs==zIndex),spJCols(spJZs==zIndex),spJZs(spJZs==zIndex));
%         velocitySpJs(:,zIndex,spJIndex)=[mean(flowXsInInterval(flowIndex)) mean(flowYsInInterval(flowIndex))];
%     end
% end
% 
% tempCenterDiff=centerSpJs-repmat(centerSpI,[1,1,spJsNum]);
% centerDistances=permute(sqrt(sum(tempCenterDiff.^2,1)),[3,2,1]);
% 
% tempVelocityDiff=velocitySpJs-repmat(velocitySpI,[1,1,spJsNum]);
% velocityDistances=permute(sqrt(sum(tempVelocityDiff.^2,1)),[3,2,1]);
% 
% nanIndex=sum(or(isnan(centerDistances),isnan(velocityDistances)),2);
% motionDistances(nanIndex<2*interval,:)=nanvar(centerDistances(nanIndex<2*interval,:),[],2)+alpha*nanmean(velocityDistances(nanIndex<2*interval,:),2);
% motionDistances(nanIndex==2*interval,:)=nanvar(centerDistances(nanIndex==2*interval,:),[],2)+alpha*nanmean(velocityDistances(nanIndex==2*interval,:),2)+beta;
% motionDistances(nanIndex==2*interval+1,:)=Inf;