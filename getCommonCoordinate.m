function [ commonXY, scale ] = getCommonCoordinate( originalXY ,mask )
%   Get coordinate of points in common frame. Points should be in the same
%   video frame.
%   --Input--
%   originalXY: Original coordiante of points in format of Nx2.
%   mask: Foreground mask.
%   --Output--
%   commonXY: Common coordiante of points in format of Nx2.
%   scale: Scaling factor. Diagonal of bounding box of mask.

prop=regionprops(mask);
boundingBox=prop.BoundingBox;
centroid=prop.Centroid;
scale=sqrt(boundingBox(3)^2+boundingBox(4)^2);

commonXY=(originalXY-repmat(centroid,size(originalXY,1),1))./scale;

end

