function [ motionDistances ] = getMotionDistance( spI,spJs,f,temporalSP,flow,interval )
%GETMOTIONDISTANCE Summary of this function goes here
%spI,spJs: Index of superpixels, spJs,multiple superpixels
%f: frame index
%temporalSP: Temporal superpixel label images
%flow: Optical flows
%interval: interval size
%Eaxmple: getMotionDistance(305,[12;503],75,temporalSP,flow,2);

% motionDistances=zeros(size(spJs,1),1);
% alpha=5;   % balance between var and velo
% beta=15;   % broken penalty
% 
% for spJIndex=1:length(spJs)
%     if spJs(spJIndex)==spI               % get 0 when comparing to itself
%         motionDistances(spJIndex)=0;
%         continue;
%     end
%     centerDistances=zeros(2*interval+1,1);
%     velocityDistances=zeros(2*interval+1,1);
%     
%     penaltyFlag=0;
%     for frameIndex=f-interval:f+interval                                        % !! drop frames at satrt and end
%         [spIRows,spICols]=find(temporalSP{frameIndex}==spI);
%         [spJRows,spJCols]=find(temporalSP{frameIndex}==spJs(spJIndex));
%         if isempty(spIRows)||isempty(spICols)||isempty(spJRows)||isempty(spJCols)    % !! give a constant when connection broken
%             penaltyFlag=penaltyFlag+1;
%             %fprintf('broken!%d\n',penaltyFlag);
%             continue;
%         end
% 
%         centerDistance=sqrt((mean(spIRows)-mean(spJRows))^2+(mean(spICols)-mean(spJCols))^2); % !!not in common coordinate
%         centerDistances(frameIndex)=centerDistance;
% 
%         flowX=flow{frameIndex}(:,:,1);
%         flowY=flow{frameIndex}(:,:,2);
% 
%         spIFlowIndex=sub2ind(size(flowX),spIRows,spICols); % size of flow and temporalSP are the same
%         spIFlowX=flowX(spIFlowIndex);
%         spIFlowY=flowY(spIFlowIndex);
% 
%         spJFlowIndex=sub2ind(size(flowX),spJRows,spJCols);
%         spJFlowX=flowX(spJFlowIndex);
%         spJFlowY=flowY(spJFlowIndex);
% 
%         velocityDistance=sqrt((mean(spIFlowX)-mean(spJFlowX))^2+(mean(spIFlowY)-mean(spJFlowY))^2);
%         velocityDistances(frameIndex)=velocityDistance;
%     end
% 
%     %!!zero var when only one frame
%     centerDisVar=var(centerDistances(centerDistances~=0));                      % !! ignore zeros
%     velocityDisAvg=mean(velocityDistances(velocityDistances~=0));                 % !! ignore zeros, take avg instead of sum
%     motionDistance=centerDisVar+velocityDisAvg*alpha;                                   % !!get NaN when one of the superpixel not exist in any frame
%     
%     if penaltyFlag>=interval*2
%         motionDistance=motionDistance+beta;
%         fprintf('penalty!\n');
%     end
%     
%     
%     motionDistances(spJIndex)=motionDistance;
%     %fprintf('var:%f\n',centerDisVar);
%     %fprintf('velo:%f\n',velocityDisAvg);
% end
% 
% disp(spI);



motionDistances=zeros(size(spJs,1),1);
centerDistances=zeros(size(spJs,1),2*interval+1);
velocityDistances=zeros(size(spJs,1),2*interval+1);

alpha=5;   % balance between var and velo
beta=15;   % broken penalty

penaltyFlags=zeros(size(spJs,1),1);

for frameIndex=f-interval:f+interval                                        % !! drop frames at satrt and end
    [spIRows,spICols]=find(temporalSP{frameIndex}==spI);
    if isempty(spIRows)||isempty(spICols)                  % !! give a constant when connection broken
        penaltyFlags=penaltyFlags+1;
        continue;
    end
    
    certerSpI=[mean(spIRows) mean(spICols)];
    
    flowX=flow{frameIndex}(:,:,1);
    flowY=flow{frameIndex}(:,:,2);
    spIFlowIndex=sub2ind(size(flowX),spIRows,spICols);                   % size of flow and temporalSP are the same
    velocitySpI=[mean(flowX(spIFlowIndex)) mean(flowY(spIFlowIndex))];
    
    for spJIndex=1:length(spJs)
        
        if spJs(spJIndex)==spI
            continue;
        end
        
        [spJRows,spJCols]=find(temporalSP{frameIndex}==spJs(spJIndex));
        if isempty(spJRows)||isempty(spJCols)                     % !! give a constant when connection broken
            penaltyFlags(spJIndex)=penaltyFlags(spJIndex)+1;
            continue;
        end

        convertedIndex=frameIndex-f+interval+1;
        
        certerSpJ=[mean(spJRows) mean(spJCols)];
        centerDistance=sqrt((certerSpI(1)-certerSpJ(1))^2+(certerSpI(2)-certerSpJ(2))^2); % !!not in common coordinate
        centerDistances(spJIndex,convertedIndex)=centerDistance;

        spJFlowIndex=sub2ind(size(flowX),spJRows,spJCols);                   
        velocitySpJ=[mean(flowX(spJFlowIndex)) mean(flowY(spJFlowIndex))];

        velocityDistance=sqrt((velocitySpI(1)-velocitySpJ(1))^2+(velocitySpI(2)-velocitySpJ(2))^2);
        velocityDistances(spJIndex,convertedIndex)=velocityDistance;
    end
end



for spJIndex=1:length(spJs)
    if spJs(spJIndex)==spI                                                % get 0 when comparing to itself
        motionDistances(spJIndex)=0;
        continue;
    end
    
    %!!zero var when only one frame
    tempCenterDistances=centerDistances(spJIndex,:);
    tempVelocityDistances=velocityDistances(spJIndex,:);
    
    centerDisVar=var(tempCenterDistances(tempCenterDistances~=0));                      % !! ignore zeros
    velocityDisAvg=mean(tempVelocityDistances(tempVelocityDistances~=0));                 % !! ignore zeros, take avg instead of sum
    motionDistances(spJIndex)=centerDisVar+velocityDisAvg*alpha;                             % !!get NaN when one of the superpixel not exist in any frame
    
    if penaltyFlags(spJIndex)>=interval*2
        motionDistances(spJIndex)=motionDistances(spJIndex)+beta;
        %fprintf('penalty!\n');
    end
end

%disp(spI);

end
