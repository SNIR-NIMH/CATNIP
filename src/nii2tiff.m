function ret=nii2tiff(inputnii,outputtif,outputtype,compress)
% 
% function ret=nii2tiff(inputnii,outputtiff,outputtype,compress)
% 
% INPUTNII        Input 3D nifti file
% OUTPUTTIFF      Output tiff file, either 3D (e.g. somefile.nii) or a directory
%                 (e.g. /home/user/some_dir/) where 2D slices will be
%                 written
% OUTPUTTYPE      Output tiff image type, options are: uint8, uint16, float32.
%                 Most common is  uint16
% COMPRESS        A yes/no flag to check if the output images are to be
%                 compressed. It is needed only of OUTPUTTIFF is a 3D tiff
%                 file. 2D tiff files are always compressed. Default yes.

ret=0;
if nargin<4
    compress='yes';
end
if ~strcmpi(compress,'yes') && ~strcmpi(compress,'no')
    fprintf('ERROR: Compress must be yes or no. \n');
    fprintf('ERROR: You entered %s\n',compress);
    ret=1;
    return;
end

if ~strcmpi(outputtype,'uint8') && ~strcmpi(outputtype,'uint16') ...
        && ~strcmpi(outputtype,'float32')
    ret=1;
    fprintf('ERROR: Output type must be one of the following: uint8, uint16, float32.\n');
    fprintf('ERROR: You entered %s\n',outputtype);
    return;
end

[~,~,ext]=fileparts(outputtif);
if ~strcmpi(ext,'.tif') && ~strcmpi(ext,'.tiff')
    mkdir(outputtif);
    output_is_file=0;
    A=rdir(fullfile(outputtif,'*.tif'));
    if ~isempty(A)
        ret=1;
        fprintf('ERROR: Output directory contains some tif images. I will not overwrite. Exiting.\n');
        return;
    end
else
    output_is_file=1;
end
fprintf('Loading %s\n',inputnii);
tic
vol=load_untouch_nii(inputnii);
toc
vol=vol.img;
if strcmpi(outputtype,'uint8')
    vol=uint8(vol);    
elseif strcmpi(outputtype,'uint16')
    vol=uint16(vol);        
elseif strcmpi(outputtype,'float32')
    vol=single(vol);    
end

vol=permute(vol,[2 1 3]);  % tiff x-y is different from nifti x-y
if output_is_file
    options.color     = false;
    if strcmpi(compress,'yes')
        options.compress  = 'adobe';
    else
        options.compress  = 'no';
    end
    options.message   = false;
    options.append    = false;
    options.overwrite = true;
    if 2*numel(vol) > 4*(1024^3)
        options.big       = true;
        fprintf('Writing a bigtiff image %s\n',outputtif);
    else
        options.big       = false;
        fprintf('Writing image %s\n',outputtif);
    end    
    saveastiff(vol,outputtif,options);
else
    fprintf('Writing in folder %s\n',outputtif);
    tic
    for k=1:size(vol,3)
        n=sprintf('%04d',k);
        n=['Z' n '.tif'];
        s=fullfile(outputtif,n);
        fprintf('.')
        imwrite(vol(:,:,k),s,'Compression','deflate');
    end
    fprintf('\n');
    toc
end
    
