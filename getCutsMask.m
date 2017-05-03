function [ masks ] = getCutsMask( cuts,foregroundMask )
%   Get masks of shape cut.
%--Input--
%   cuts: Nx4 matrix of shape cuts
%   foregroundMask: Foreground mask
%--Output--
%   masks: Nx1 cells of HxWx2 masks image.

%%

height=size(foregroundMask,1);
width=size(foregroundMask,2);

% Coordinate of four corners
upperLeftPoint=[0.5 0.5];
upperRightPoint=[width+0.5 0.5];
lowerLeftPoint=[0.5 height+0.5];
lowerRightPoint=[width+0.5 height+0.5];

masks=cell(size(cuts,1),1);

for cutIndex=1:size(cuts,1)
    
    cut=cuts(cutIndex,:);
    
    %% Get point of intersection of cut line and four image boundaries
    %% y=0

    y=0.5;

    if cut(4)-cut(2)==0
        point1=[];
    else
        k=(cut(3)-cut(1))/(cut(4)-cut(2));
        x=k*(y-cut(2))+cut(1);

        if x<0.5||x>width+0.5
            point1=[];
        else
            point1=[x y];
        end
    end

    %% y=h

    y=height+0.5;

    if cut(4)-cut(2)==0
        point2=[];
    else
        k=(cut(3)-cut(1))/(cut(4)-cut(2));
        x=k*(y-cut(2))+cut(1);

        if x<0.5||x>width+0.5
            point2=[];
        else
            point2=[x y];
        end
    end


    %% x=0;

    x=0.5;

    if cut(3)-cut(1)==0
        point3=[];
    else
        k=(cut(4)-cut(2))/(cut(3)-cut(1));
        y=k*(x-cut(1))+cut(2);

        if y<0.5||y>height+0.5
            point3=[];
        else
            point3=[x y];
        end
    end


    %% x=w

    x=width+0.5;

    if cut(3)-cut(1)==0
        point4=[];
    else
        k=(cut(4)-cut(2))/(cut(3)-cut(1));
        y=k*(x-cut(1))+cut(2);

        if y<0.5||y>height+0.5
            point4=[];
        else
            point4=[x y];
        end
    end
    
    %% Get masks

    if (isempty(point1)+isempty(point2)+isempty(point3)+isempty(point4))~=2
        fprintf('Shape Data Error...\n') %left empty
        continue;
    end
    
    
    mask=zeros(height,width,2);
    
    %yy
    if isempty(point1)&&isempty(point2)
        temp1=[upperLeftPoint;point3;point4;upperRightPoint;upperLeftPoint]';
        temp2=[lowerLeftPoint;point3;point4;lowerRightPoint;lowerLeftPoint]';
        mask(:,:,1)=poly2mask(temp1(1,:),temp1(2,:),height,width);
        mask(:,:,2)=poly2mask(temp2(1,:),temp2(2,:),height,width);
    end

    %xx
    if isempty(point3)&&isempty(point4)
        temp1=[upperLeftPoint;point1;point2;lowerLeftPoint;upperLeftPoint]';
        temp2=[upperRightPoint;point1;point2;lowerRightPoint;upperRightPoint]';
        mask(:,:,1)=poly2mask(temp1(1,:),temp1(2,:),height,width);
        mask(:,:,2)=poly2mask(temp2(1,:),temp2(2,:),height,width);    
    end

    %xy
    if isempty(point1)&&isempty(point3)
        temp1=[upperLeftPoint;lowerLeftPoint;point2;point4;...
               upperRightPoint;upperLeftPoint]';
        temp2=[lowerRightPoint;point2;point4;lowerRightPoint]';
        mask(:,:,1)=poly2mask(temp1(1,:),temp1(2,:),height,width);
        mask(:,:,2)=poly2mask(temp2(1,:),temp2(2,:),height,width);    
    end

    %xy
    if isempty(point1)&&isempty(point4)
        temp1=[upperRightPoint;lowerRightPoint;point2;point3;...
               upperLeftPoint;upperRightPoint]';
        temp2=[lowerLeftPoint;point2;point3;lowerLeftPoint]';
        mask(:,:,1)=poly2mask(temp1(1,:),temp1(2,:),height,width);
        mask(:,:,2)=poly2mask(temp2(1,:),temp2(2,:),height,width);     
    end

    %xy
    if isempty(point2)&&isempty(point3)
        temp1=[lowerLeftPoint;upperLeftPoint;point1;point4;...
               lowerRightPoint;lowerLeftPoint]';
        temp2=[upperRightPoint;point1;point4;upperRightPoint]';
        mask(:,:,1)=poly2mask(temp1(1,:),temp1(2,:),height,width);
        mask(:,:,2)=poly2mask(temp2(1,:),temp2(2,:),height,width);    
    end

    %xy
    if isempty(point2)&&isempty(point4)
        temp1=[lowerRightPoint;upperRightPoint;point1;point3;...
               lowerLeftPoint;lowerRightPoint]';
        temp2=[upperLeftPoint;point1;point3;upperLeftPoint]';
        mask(:,:,1)=poly2mask(temp1(1,:),temp1(2,:),height,width);
        mask(:,:,2)=poly2mask(temp2(1,:),temp2(2,:),height,width);     
    end
    
    %% Select the component where cut point or its neighbors locate    
    
    mask(:,:,1)=and(mask(:,:,1),foregroundMask);
    mask(:,:,2)=and(mask(:,:,2),foregroundMask);
    
    % Cut point A and its neighbors
    cutPointANInd(1)=sub2ind([height width], max(cut(2)-1,1), max(cut(1)-1,1));
    cutPointANInd(2)=sub2ind([height width], max(cut(2)-1,1), cut(1));
    cutPointANInd(3)=sub2ind([height width], max(cut(2)-1,1), min(cut(1)+1,width));
    cutPointANInd(4)=sub2ind([height width], cut(2), max(cut(1)-1,1));
    cutPointANInd(5)=sub2ind([height width], cut(2), cut(1));
    cutPointANInd(6)=sub2ind([height width], cut(2), min(cut(1)+1,width));
    cutPointANInd(7)=sub2ind([height width], min(cut(2)+1,height), max(cut(1)-1,1));
    cutPointANInd(8)=sub2ind([height width], min(cut(2)+1,height), cut(1));
    cutPointANInd(9)=sub2ind([height width], min(cut(2)+1,height), min(cut(1)+1,width));
    
    % Cut point B and its neighbor
    cutPointBNInd(1)=sub2ind([height width], max(cut(4)-1,1), max(cut(3)-1,1));
    cutPointBNInd(2)=sub2ind([height width], max(cut(4)-1,1), cut(3));
    cutPointBNInd(3)=sub2ind([height width], max(cut(4)-1,1), min(cut(3)+1,width));
    cutPointBNInd(4)=sub2ind([height width], cut(4), max(cut(3)-1,1));
    cutPointBNInd(5)=sub2ind([height width], cut(4), cut(3));
    cutPointBNInd(6)=sub2ind([height width], cut(4), min(cut(3)+1,width));
    cutPointBNInd(7)=sub2ind([height width], min(cut(4)+1,height), max(cut(3)-1,1));
    cutPointBNInd(8)=sub2ind([height width], min(cut(4)+1,height), cut(3));
    cutPointBNInd(9)=sub2ind([height width], min(cut(4)+1,height), min(cut(3)+1,width));
    
    pointInCCFlag=0;
    conncomp=bwconncomp(mask(:,:,1));
    conncompPList=conncomp.PixelIdxList;
    for ccIndex=1:length(conncompPList)
        if ~(any(ismember(cutPointANInd,conncompPList{ccIndex}))&&...
             any(ismember(cutPointBNInd,conncompPList{ccIndex})))
            
            temp=mask(:,:,1);
            temp(conncompPList{ccIndex})=0;
            mask(:,:,1)=temp;
        else
            pointInCCFlag=pointInCCFlag+1;
        end
    end
    if pointInCCFlag~=1
        fprintf('Shape Data Postprocessing Error...\n') %left empty
        continue;
    end
    
    pointInCCFlag=0;
    conncomp=bwconncomp(mask(:,:,2));
    conncompPList=conncomp.PixelIdxList;
    for ccIndex=1:length(conncompPList)
        if ~(any(ismember(cutPointANInd,conncompPList{ccIndex}))&&...
             any(ismember(cutPointBNInd,conncompPList{ccIndex})))
            
            temp=mask(:,:,2);
            temp(conncompPList{ccIndex})=0;
            mask(:,:,2)=temp;
        else
            pointInCCFlag=pointInCCFlag+1;
        end
    end
    if pointInCCFlag~=1
        fprintf('Shape Data Postprocessing Error...\n') %left empty
        continue;
    end

    masks{cutIndex}=mask;

end

end

