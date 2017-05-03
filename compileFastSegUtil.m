function [ ] = compileFastSegUtil( fileSettings )
%   Compile utility code from 'FastSegmentation'
%--Inupt--
%   fileSettings: ...
%--Output--
%   Mex files

%% Compile Util Mex

fastSegUtilPath=fileSettings.fastSegUtilPath;
homePath=pwd();

cd(fastSegUtilPath);

mex getSpatialConnections.cpp
mex getSuperpixelStats.cpp
mex getTemporalConnections.cpp

cd(homePath);

end