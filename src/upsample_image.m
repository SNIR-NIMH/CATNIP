function upsample_image(input,output,outputsize,interptype,memsafe,compression,outputtype)

% 
% upsample_image(input,output,outputsize,interptype,memsafe,compression,outputtype)
% 
% INPUT          Input image, either nifti (nii/nii.gz) or 3D tif (.tif/.tiff) or 
%                a folder containing 2D tif
% OUTPUT         Output image, either a 3D tif or a folder. For big images, use a
%                folder, where multiple 2D slices will be written
% OUTPUTSIZE     Output image size, in pixels. It must be bigger than input image
%                size. E.g. 1000x1000x2000 (separated by "x")
% INTERP         Interpolation type, either nearest, bilinear, or cubic
% MEMSAFE        (Optional) Either true or false, depending if memory efficient 
%                image reading is used. Default false.
% COMPRESSION    (Optional) Either true or false, if the output image is to 
%                be compressed. Default false, i.e. no compression. 
%                * Applicable only if the output is a 3D tif. For an output
%                folder, the 2D tif images are always compressed.
% OUTPUTTYPE     (Optional) Either uint16 or float32. Default is uint16.


setenv('MATLAB_SHELL','/bin/sh');
username=getenv('USER');
temp=strsplit(outputsize,{'x','X'});
for t=1:3
    odim(t)=str2num(temp{t});
end

if ~strcmpi(interptype,'nearest') && ~strcmpi(interptype,'cubic') ...
        && ~strcmpi(interptype,'bilinear')
    fprintf('ERROR: Interpolation type must be one of the following: nearest, cubic, bilinear.\n');
    return;
end
if nargin<=4
    memsafe='false';
    compression='false';
    outputtype='uint16';
end
if nargin<=5
    compression='false';
    outputtype='uint16';
end
if nargin<=6    
    outputtype='uint16';
end
if ~strcmpi(memsafe,'true') && ~strcmpi(memsafe,'false') 
    fprintf('ERROR: Memsafe can only be true or false. You entered %s\n', memsafe);
    return;
end
if ~strcmpi(compression,'true') && ~strcmpi(compression,'false') 
    fprintf('ERROR: Compression can only be true or false. You entered %s.\n', compression);
    return;
end
if ~strcmpi(outputtype,'uint16') && ~strcmpi(outputtype,'float32') 
    fprintf('ERROR: Output type can only be uint16 or float32. You entered %s.\n',outputtype);
    return;
end

if ischar(input)
    if isfile(input)
        [~,~,ext]=fileparts(input);
        if strcmpi(ext,'.tif') || strcmpi(ext,'.tiff') 
            info=imfinfo(input);
            idim=[info(1).Height info(1).Width length(info)];
        elseif  strcmpi(ext,'.nii') || strcmpi(ext,'.gz') 
            vol=load_untouch_nii(input);
            vol=permute(vol.img,[2 1 3]);
            idim=size(vol);
            memsafe='false';
        else
            fprintf('ERROR: Input must be tif or nifti image.\n');
            fprintf('ERROR: You entered %s\n',input);
            return;
        end
    elseif isfolder(input)
        inputfilelist=rdir(fullfile(input,'*.tif'));
        if isempty(inputfilelist)
            inputfilelist=rdir(fullfile(input,'*.tiff'));
            if isempty(inputfilelist)
                fprintf('ERROR: Input folder must contain .tif or .tiff files.\n');
                return;
            end

        end

        info=imfinfo(inputfilelist(1).name);
        idim=[info(1).Height info(1).Width length(inputfilelist)];
    end
elseif isnumeric(input)
    idim=size(input);
    memsafe='false';
end
fprintf('Input image size  = %d x %d x %d \n',idim(1),idim(2),idim(3));
fprintf('Output image size = %d x %d x %d \n',odim(1),odim(2),odim(3));
ff=odim./idim;
fprintf('Upsampling factor = %.2f x %.2f x %.2f\n',ff(1),ff(2),ff(3));
if strcmpi(memsafe,'false')
    fprintf('WARNING: Assuming sufficient available memory, input image will be loaded completely from disk.\n');
    if ischar(input)
        [~,~,ext]=fileparts(input);
        if strcmpi(ext,'.tif') || strcmpi(ext,'.tiff') 
            inputvol=load3Dtiff(input,0);
        elseif  strcmpi(ext,'.nii') || strcmpi(ext,'.gz') 
            inputvol=load_untouch_nii(input);
            inputvol=permute(inputvol.img,[2 1 3]); % nifti xy is opposite of tif xy
        end
            
%         fprintf('Loading %s\n',input);
%         inputvol=load3Dtiff(input,0);
    elseif isnumeric(input)
        inputvol=uint16(input);
    end
else
    fprintf('Memory efficient reading of input images enabled, reading will be slow. \n');
end

% f=odim./idim;
% tformz=affine2d([f(3) 0 0;0 1 0;0 0 1]);
% tformxy=affine2d([f(2) 0 0;0 f(1) 0;0 0 1]);
[~,~,ext]=fileparts(output);
if strcmpi(ext,'.tif') || strcmpi(ext,'.tiff')
    output_is_file=1;
else
    output_is_file=0;
    if ~isfolder(output)
        mkdir(output);
    end
end
if output_is_file
    fprintf('WARNING: Output image will be written as a single 3D image.\n');
    if strcmpi(outputtype,'uint16')
        fprintf('WARNING: Required memory is at least %d GB.\n',...
            round((2*prod(odim)+2*idim(1)*idim(2)*odim(3))/(1024^3)));
        outvol=zeros([odim(1) odim(2) odim(3)],'uint16');
        vol=zeros([idim(1) idim(2) odim(3)],'uint16');
    else
        fprintf('WARNING: Required memory is at least %d GB.\n',...
            round((4*prod(odim)+4*idim(1)*idim(2)*odim(3))/(1024^3)));
        outvol=zeros([odim(1) odim(2) odim(3)],'single');
        vol=zeros([idim(1) idim(2) odim(3)],'single');
    end
else  % output is folder
    if strcmpi(outputtype,'uint16')
        fprintf('WARNING: Required memory is at least %d GB.\n',...
            round((2*idim(1)*idim(2)*odim(3))/(1024^3)));
        vol=zeros([idim(1) idim(2) odim(3)],'uint16');
    else
        fprintf('WARNING: Required memory is at least %d GB.\n',...
            round((4*idim(1)*idim(2)*odim(3))/(1024^3)));
        vol=zeros([idim(1) idim(2) odim(3)],'single');
    end
end
fprintf('Resampling Z:\n');
for h=1:idim(1)
    if strcmpi(outputtype,'uint16')
        temp=zeros([idim(2) idim(3)],'uint16');
    else
        temp=zeros([idim(2) idim(3)],'single');
    end
    if strcmpi(memsafe,'true')
        % Memory efficient reading of input image
        
        for z=1:idim(3)
            if isfile(input)
                if strcmpi(outputtype,'uint16')
                    temp(:,z)=uint16(imread(input,'Index',z,'PixelRegion',{[h h],[1 idim(2)]}));
                else
                    temp(:,z)=single(imread(input,'Index',z,'PixelRegion',{[h h],[1 idim(2)]}));
                end
            else
                if strcmpi(outputtype,'uint16')
                    temp(:,z)=uint16(imread(inputfilelist(z).name,'PixelRegion',{[h h],[1 idim(2)]}));
                else
                    temp(:,z)=single(imread(inputfilelist(z).name,'PixelRegion',{[h h],[1 idim(2)]}));
                end
            end
        end
    else
        for z=1:idim(3)
            
            temp(:,z)=inputvol(h,:,z);
        end
    end
    % Don't use imwarp, sizes may not be preserved.
%     vol(h,:,:)=imwarp(temp,tformz,interptype);
    if strcmpi(outputtype,'uint16')
        vol(h,:,:)=imresize(uint16(temp),[idim(2) odim(3)],interptype);
    else
        vol(h,:,:)=imresize(single(temp),[idim(2) odim(3)],interptype);
    end
    
end
if output_is_file==0
    vol2=cell(odim(3),1);
    for z=1:odim(3)
        vol2{z}=vol(:,:,z);
    end
    clear vol;
        
    fprintf('Resampling XY:\n');
    numcpu=8;
    n=feature('numcores');
    if n<numcpu   
        numcpu=n;
    end
    tempdirname=tempname(fullfile('/home',username,'.matlab','local_cluster_jobs','R2019b'));
    mkdir(tempdirname);
    cluster=parallel.cluster.Local();
    cluster.NumWorkers=numcpu;
    cluster.JobStorageLocation=tempdirname;
    fprintf('Temp Job directory = %s\n',tempdirname);
    pl=parpool(cluster);
    parfor z=1:odim(3)
        temp=imresize(vol2{z},[odim(1) odim(2)],interptype);
%         temp=imwarp(vol2{z},tformxy,interptype);
        s=['Z' sprintf('%06d',z) '.tif'];
        s=fullfile(output,s);
        fprintf('%d,',z);
        if strcmpi(outputtype,'uint16')
            temp(temp<0)=0;
            temp(temp>65535)=65535;
            temp=uint16(temp);
        end
        if strcmpi(outputtype,'uint16')
            imwrite(temp,s,'Compression','deflate');
        else
            imwrite_float32(temp,s);
        end
        if mod(z,20)==0
            fprintf('\n');
        end
    end
    fprintf('\n');
    delete(pl);
    rmdir(tempdirname);
else
    fprintf('Resampling XY:\n');
    for z=1:odim(3)
        outvol(:,:,z)=imresize(vol(:,:,z),[odim(1) odim(2)],interptype);
    end
    if strcmpi(outputtype,'uint16')
        outvol(outvol<0)=0;
        outvol=uint16(outvol);
    end
        
    fprintf('Writing %s\n',output);
    options.color     = false;
    if strcmpi(compression,'true')
        options.compress  = 'adobe';
    else
        options.compress  = 'no';
    end
    options.message   = false;
    options.append    = false;
    options.overwrite = true;
    if 2*prod(odim)<4*(1024^3)
        options.big       = false;
    else
        options.big       = true;
    end
    saveastiff(outvol,output,options);
end
        
        
        