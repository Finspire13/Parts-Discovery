function [ motionDistances ] = getMotionDistance( spI,spJs,f,temporalSP,flow,interval )
%   Get motion distances from superpixel spI to superpixels in spJs.
%--Input--
%   spI,spJs: Index of superpixels 1x1. spJs can be multiple superpixels Nx1.
%   f: Frame Index
%   temporalSP: Temporal superpixel label maps.
%   flow: Optical flows fields.
%   interval: Temporal interval size to find connected superpixels.
%--Output--
%   motionDistances: Motion distances Nx1
%--Eaxmple--
%   getMotionDistance(305,[12;503],75,temporalSP,flow,2);

alpha=5;   % balance between var and velo
beta=15;   % broken penalty

spJsNum=size(spJs,1);

motionDistances=zeros(spJsNum,1);   % motionDistances=centerDistances+velocityDistances
centerDistances=zeros(spJsNum,2*interval+1);
velocityDistances=zeros(spJsNum,2*interval+1);

penaltyFlags=zeros(spJsNum,1);  % add a penalty when there is no connected superpixel in all interval frames

for frameIndex=f-interval:f+interval    % drop frames at satrt and end. Input f should not be at start or end
    [spIRows,spICols]=find(temporalSP{frameIndex}==spI);
    if isempty(spIRows)||isempty(spICols)                  
        penaltyFlags=penaltyFlags+1;    % mark a penalty and give 0 when connection broken
        continue;
    end
    
    centerSpI=[mean(spIRows) mean(spICols)];
    
    flowX=flow{frameIndex}(:,:,1);
    flowY=flow{frameIndex}(:,:,2);
    
    spIFlowIndex=sub2ind(size(flowX),spIRows,spICols);  % size of flow and temporalSP are the same
    velocitySpI=[mean(flowX(spIFlowIndex)) mean(flowY(spIFlowIndex))];
    
    for spJIndex=1:length(spJs)
        
        if spJs(spJIndex)==spI
            continue;   % give 0 when compare to itself
        end
        
        [spJRows,spJCols]=find(temporalSP{frameIndex}==spJs(spJIndex));
        if isempty(spJRows)||isempty(spJCols)                    
            penaltyFlags(spJIndex)=penaltyFlags(spJIndex)+1;    % mark a penalty and give 0 when connection broken
            continue;
        end

        convertedIndex=frameIndex-f+interval+1;     % 1:2*interval+1
        
        centerSpJ=[mean(spJRows) mean(spJCols)];

        spJFlowIndex=sub2ind(size(flowX),spJRows,spJCols);                   
        velocitySpJ=[mean(flowX(spJFlowIndex)) mean(flowY(spJFlowIndex))];
        
        centerDistance=sqrt((centerSpI(1)-centerSpJ(1))^2+(centerSpI(2)-centerSpJ(2))^2); % not in common coordinate, thsi is ok
        centerDistances(spJIndex,convertedIndex)=centerDistance;

        velocityDistance=sqrt((velocitySpI(1)-velocitySpJ(1))^2+(velocitySpI(2)-velocitySpJ(2))^2);
        velocityDistances(spJIndex,convertedIndex)=velocityDistance;
    end
end



for spJIndex=1:length(spJs)
    if spJs(spJIndex)==spI     % get 0 when comparing to itself
        motionDistances(spJIndex)=0;
        continue;
    end
    
    tempCenterDistances=centerDistances(spJIndex,:);
    tempVelocityDistances=velocityDistances(spJIndex,:);
    
    centerDisVar=var(tempCenterDistances(tempCenterDistances~=0));  % ignore zeros
    velocityDisAvg=mean(tempVelocityDistances(tempVelocityDistances~=0));   % ignore zeros, take avg instead of sum
    motionDistances(spJIndex)=centerDisVar+velocityDisAvg*alpha;    
    
    if penaltyFlags(spJIndex)>=interval*2
        motionDistances(spJIndex)=motionDistances(spJIndex)+beta;
        %fprintf('penalty!\n');
    end
    
    if isnan(motionDistances(spJIndex))
        motionDistances(spJIndex)=Inf;  % get Inf when one of the superpixel not exist in any frame
    end
    
end

%disp(spI);

end
