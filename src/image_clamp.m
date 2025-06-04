function image_clamp(input,output,clampval,ispercentile)
% 
% function image_clamp(input,output,clampval,ispercentile)
% 
% INPUT         Input image, either nifti or tif (somefile.tif) or a folder
%               containing multiple 2D tif slices (/home/user/somefolder)
% OUTPUT        Output nifti image, or 3D tif file (somefile.tif) or  folder.
%               It must be same type as th input. If the input is nifti, output
%               must be nifti too.
% CLAMPVAL      Clamping value. Any intensity above this range is clamped at
%               this value. It could also be a percentile (0-100). 
% ISPERCENTILE  If the clamping value an intensity, enter false. If it is a
%                percentile (0-100) of the intensity range, enter true.
% 
% NOTE: If the image is very large that may not fit into memory, then don't use
% the percentile value. Computing intensity percentile requires at least twice
% the size of the image.

if isdeployed
    clampval=str2num(clampval);
end
if ~strcmpi(ispercentile,'true') && ~strcmpi(ispercentile,'false')
    fprintf('ERROR: ISPERCENTILE flag must be either true or false string.\n');
    fprintf('ERROR: You entered %s\n',ispercentile);
    return;
end
[~,~,ext1]=fileparts(input);
if strcmpi(ext1,'.nii') || strcmpi(ext1,'.gz')
    [~,~,ext2]=fileparts(output);
    if ~strcmpi(ext2,'.nii') && ~strcmpi(ext2,'.gz')
        fprintf('ERROR: Input seems a NIFTI image. Output must be a NIFTI image too.\n');
        return;
    end
end
if strcmpi(ext1,'.tif') || strcmpi(ext1,'.tiff')
    [~,~,ext2]=fileparts(output);
    if ~strcmpi(ext2,'.tif') && ~strcmpi(ext2,'.tiff')
        fprintf('ERROR: Input seems a TIFF image. Output must be a TIFF image too.\n');
        return;
    end
end
    
if strcmpi(ext1,'.nii') || strcmpi(ext1,'.gz')
    x=load_untouch_nii(input);
    if strcmpi(ispercentile,'false')
        x.img(x.img>clampval)=clampval;
        fprintf('Clamping by %.4f \n',clampval);
    else
        y=x.img(x.img>0);
        q=quantile(y,clampval/100);
        fprintf('Clamping by %.4f percentile of non-zero values = %.4f \n',clampval/100,q);
        x.img(x.img>q)=q;
    end
    x.fileprefix=output;
    save_untouch_nii(x,output);
end
if strcmpi(ext1,'.tif') || strcmpi(ext1,'.tiff') || isfolder(input)
    x=load3Dtiff(input);
    dim=size(x);
    if round(2*prod(dim)/(1024^3))>10
        fprintf('WARNING: Large image detected. Required memory is at least %d GB.\n',...
            round(2*2*prod(dim)/(1024^3)));
    end
    if strcmpi(ispercentile,'false')
        x(x>clampval)=clampval;
        fprintf('Clamping by %.4f \n',clampval);
    else
        y=x(x>0);
        q=quantile(y,clampval/100);
        fprintf('Clamping by %.4f percentile of non-zero values = %.4f \n',clampval/100,q);
        x(x>q)=q;
    end
    if strcmpi(ext2,'.tif') || strcmpi(ext2,'.tiff')
        options.color     = false;
        options.compress  = 'adobe';
        options.message   = true;
        options.append    = false;
        options.overwrite = true;
        if 2*prod(dim)>=4*(1024^3)
            options.big       = true;
        else
            options.big       = false;
        end
        fprintf('Writing %s\n',output);
        saveastiff(x,output,options);
    else % Output is a folder
        mkdir(output);
        fprintf('Writing in folder %s\n',output);
        for k=progress(1:dim(3))
            s=['Z' sprintf('%06d',k) '.tif'];
            s=fullfile(output,s);
            imwrite(x(:,:,k),s,'Compression','deflate');
        end
    end
end
    
    