function [ ] = compileFastSegUtil( fileSettings )
%COMPILEFASTSEGUTIL Summary of this function goes here
%   Detailed explanation goes here

fastSegUtilPath=fileSettings.fastSegUtilPath;
homePath=pwd();

cd(fastSegUtilPath);

mex getSpatialConnections.cpp
mex getSuperpixelStats.cpp
mex getTemporalConnections.cpp

cd(homePath);

end

