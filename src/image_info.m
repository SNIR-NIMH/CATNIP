function ret=image_info(img,option)
% 
% OUTPUT=image_info(IMG, OPTION)
% 
% IMG     A single tif image (either 2D or 3D) or a folder containing multiple 
%         tiff images
% OPTION  H  : Height
%         W  : Width
%         D  : Depth
% 
% For 2D images, D=1
% 
% The purpose of this simple code is to get dimension of an image. Normally
% tiffinfo is fine, but with OME-TIFF images having text headers, tiffinfo does
% not work.

dim=[0 0 0];
if isfolder(img)
    A=rdir(fullfile(img,'*.tif'));
    x=imread(A(1).name);
    dim=[size(x,1) size(x,2) length(A)];
elseif isfile(img)
    info=imfinfo(img);
    dim=[info(1).Height info(1).Width length(info)];
end

if strcmpi(option,'H')
    ret=dim(1); % height
elseif strcmpi(option,'W')
    ret=dim(2);  % width
elseif strcmpi(option,'D')
    ret=dim(3);
end
fprintf('%d\n',ret);
