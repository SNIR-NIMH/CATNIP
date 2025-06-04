% function [face, vert, dat, filename]=ReadVtk(vtkname)
% vtkname is the full path of the vtk file. 
% f is a Mx3 array containing the face information
% v is a Nx3 array containing the vertex information
% dat is a Nx1 array containing the vertex data
% Filename is the name of the vtk.

% 5/18/2009
% Snehashis Roy 
% created file
% gets vertex data from vtk file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5/19/2009
% John Bogovic
% added vertex and face outputs


function [face, vert, dat, filename]=ReadVtk(vtkname)

fp1=fopen(vtkname);
% look at the first few lines 
fgetl(fp1);
filename=fgetl(fp1); % get the filename
fgetl(fp1);fgetl(fp1);
%read header for point data
C=textscan(fp1,'%s %d %s',1);
N1=double(C{2})+1; % number of vertices
C=textscan(fp1,'%f %f %f',N1);
vert = zeros(size(C{1},1),3);
vert(:,1) = single(C{1}); % vertex data x
vert(:,2) = single(C{2}); % vertex data y
vert(:,3) = single(C{3}); % vertex data z
D=textscan(fp1,'%s %d %d',1);
N2=double(D{2})+1; % number of polygons
%read header for face data
C=textscan(fp1,'%d %d %d %d',N2);
face = zeros(size(C{1},1),3,'int32');
face(:,1) = int32(C{2}+1); % triangle data 1
face(:,2) = int32(C{3}+1); % triangle data 2
face(:,3) = int32(C{4}+1); % triangle data 3

C=textscan(fp1,'%s %d',1);
N3=C{2};
fgetl(fp1);fgetl(fp1);fgetl(fp1);
C=textscan(fp1,'%f',N3);
dat=double(C{1});

fclose(fp1);
