% frames=readFrames(fileSettings,4,8);
% for i=1:length(frames)
%      imwrite(frames{i},sprintf('./tmp/tiger-right-8/%05d.jpg',i));
% end


% 
% frames=readFrames(fileSettings,4,6);
% 
% outputVideo=VideoWriter('./output/segments/46_new.avi');
% open(outputVideo);
% for i=1:length(segments)
%     frames{i}(:,:,2) = min(255, frames{i}(:,:,2) + 100*uint8(segments{i}));
%     writeVideo(outputVideo,frames{i});
% end
% close(outputVideo);
% 
% 
% 
% for i=1:21
%     figure;imagesc(occurrenceCount(:,:,i));
% end


height=225+0.5;
width=400+0.5;

upperLeftPoint=[0.5 0.5];
upperRightPoint=[width 0.5];
lowerLeftPoint=[0.5 height];
lowerRightPoint=[width height];

mask=zeros(height,width,2);

%% y=0

y=0.5;

if cut(4)-cut(2)==0
    point1=[];
else
    k=(cut(3)-cut(1))/(cut(4)-cut(2));
    x=k(y-cut(2))+cut(1);
    
    if x<0.5||x>width
        point1=[];
    else
        point1=[x y];
    end
end

%% y=h

y=height;

if cut(4)-cut(2)==0
    point2=[];
else
    k=(cut(3)-cut(1))/(cut(4)-cut(2));
    x=k(y-cut(2))+cut(1);
    
    if x<0.5||x>width
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
    y=k(x-cut(1))+cut(2);
    
    if y<0.5||y>height
        point3=[];
    else
        point3=[x y];
    end
end


%% x=w

x=width;

if cut(3)-cut(1)==0
    point4=[];
else
    k=(cut(4)-cut(2))/(cut(3)-cut(1));
    y=k(x-cut(1))+cut(2);
    
    if y<0.5||y>height
        point4=[];
    else
        point4=[x y];
    end
end

%%

%% 

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