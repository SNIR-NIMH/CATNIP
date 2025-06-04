function ret=FlipImages(input,output,udflip,lrflip,zflip,numcpu,dsfactor)

% function ret=FlipImages(INPUT,OUTPUT,UDFLIP,LRFLIP,ZFLIP,NUMCPU)
% 
% INPUT             Input 3D tiff file or a folder with 2D tiff slices
% OUTPU             Output 3D tiff file (somefile.tif) or a folder (/home/user/somefolder)
%                   where 2D tiff slices will be written
% UDFLIP            A yes/no flag if the image is to be flipped up-down
% LRFLIP            A yes/no flag if the image is to be flipped left-right
% ZFLIP             A yes/no flag if the image depth (z axis) is to be flipped
% NUMCPU            (Optional) Number of parallel processes to be used, default 8. 
%                   Used only if both input and output are folders
% DSFACTOR          (Optional) A downsampling factor to downsample images in
%                   X-Y only dimensions only. Default 1, i.e. no downsampling.
ret=1;
setenv('MATLAB_SHELL','/bin/sh');
username=getenv('USER');
if ~strcmpi(udflip,'yes') && ~strcmpi(udflip,'no')
    ret=1;
    fprintf('ERROR: UDFLIP flag must be yes or no. You entered %s.\n',udflip);
    return;
end
if ~strcmpi(lrflip,'yes') && ~strcmpi(lrflip,'no')
    ret=1;
    fprintf('ERROR: LRFLIP flag must be yes or no. You entered %s.\n',lrflip);
    return;
end
if ~strcmpi(zflip,'yes') && ~strcmpi(zflip,'no')
    ret=1;
    fprintf('ERROR: ZFLIP flag must be yes or no. You entered %s.\n',zflip);
    return;
end
if nargin<6
    numcpu=8;
    dsfactor=1;
elseif nargin==6
    if isdeployed
        numcpu=str2num(numcpu);
        
    end
    dsfactor=1;
    n=feature('numcores');
    if n<numcpu
        fprintf('Warning: number of available cpu = %d, you entered %d\n',n,numcpu);
        numcpu=n;
    end
elseif nargin==7
    if isdeployed
        numcpu=str2num(numcpu);
        dsfactor=str2num(dsfactor);
    end
end
if isfolder(input)
    A=rdir(fullfile(input,'*.tif'));
    x=imfinfo(A(1).name);
    dim=[x.Height x.Width length(A)];
    input_is_file=0;
elseif isfile(input)
    x=imfinfo(input);
    dim=[x(1).Height x(1).Width length(x)];
    input_is_file=1;
else
    fprintf('ERROR: Input must be 3D tiff file or a folder with 2D tiff slices.\n');
    ret=1;
    return;
end
    
fprintf('Input image dimension = %d x %d x %d\n',dim(1),dim(2),dim(3));

[~,~,ext]=fileparts(output);
if strcmpi(ext,'.tif') || strcmpi(ext,'.tiff')
    output_is_file=1;
else
    if ~isfolder(output)
        mkdir(output);
    end
    output_is_file=0;
end
if dsfactor~=1
    odim=[round(dim(1:2)/dsfactor) dim(3)];
    fprintf('Output image dimension = %d x %d x %d\n',odim(1),odim(2),odim(3));
else
    odim=dim;
end



tic
if output_is_file==0 && input_is_file==0
    tempdirname=tempname(fullfile('/home',username,'.matlab','local_cluster_jobs','R2022a'));
    mkdir(tempdirname);
    cluster=parallel.cluster.Local();
    cluster.NumWorkers=numcpu;
    cluster.JobStorageLocation=tempdirname;
    fprintf('Temp Job directory = %s\n',tempdirname);
    p=parpool(cluster,numcpu);
    
    parfor i=1:dim(3)       
        x=imread(A(i).name);
        fprintf('%d,',i);
        if strcmpi(udflip,'yes')
            x=flipud(x);
        end
        if strcmpi(lrflip,'yes')
            x=fliplr(x);
        end
        if dsfactor~=1
            x=imresize(x,1/dsfactor,'bilinear');
        end
        if strcmpi(zflip,'no')
            s=basename(A(i).name);
        else
            s=dim(3)-i+1;
            s=sprintf('%06d',s);
            s=['Z' s '.tif'];
        end
       

        s=fullfile(output,s);
        imwrite(x,s,'Compression','Deflate');
        if mod(i,10)==0 fprintf('\n');end
    end
    fprintf('\n');
    delete(p);
    rmdir(tempdirname,'s');
elseif output_is_file==0 && input_is_file==1
    tempdirname=tempname(fullfile('/home',username,'.matlab','local_cluster_jobs','R2022a'));
    mkdir(tempdirname);
    cluster=parallel.cluster.Local();
    cluster.NumWorkers=numcpu;
    cluster.JobStorageLocation=tempdirname;
    fprintf('Temp Job directory = %s\n',tempdirname);
    p=parpool(cluster,numcpu);
    [~,id,~]=fileparts(input);
    parfor i=1:dim(3)
        x=imread(input,'Index',i);
%         fprintf('%d,',i);
        if strcmpi(udflip,'yes')
            x=flipud(x);
        end
        if strcmpi(lrflip,'yes')
            x=fliplr(x);
        end
        if dsfactor~=1
            x=imresize(x,1/dsfactor,'bilinear');
        end
        if strcmpi(zflip,'no')
            s=[id '_Z' sprintf('%06d',i) '.tif'];
        else
            s=[id '_Z' sprintf('%06d',dim(3)-i+1) '.tif'];
        end
        s=fullfile(output,s);
        imwrite(x,s,'Compression','Deflate');
        if mod(i,10)==0 fprintf('\n');end
    end
    fprintf('\n');
    delete(p);
    rmdir(tempdirname,'s');
elseif output_is_file==1 && input_is_file==0
    vol=zeros(odim,'uint16');
    options.color     = false;
    options.compress  = 'adobe';
    options.message   = true;
    options.append    = false;
    options.overwrite = true;
    if 2*prod(odim)>=4*(1024^3)
        options.big       = true;
    else
        options.big       = false;
    end

    for i=progress(1:odim(3))
        x=imread(A(i).name);
%         fprintf('%d,',i);
        if strcmpi(udflip,'yes')
            x=flipud(x);
        end
        if strcmpi(lrflip,'yes')
            x=fliplr(x);
        end
        if dsfactor~=1
            x=imresize(x,1/dsfactor,'bilinear');
        end
        if strcmpi(zflip,'no')
            vol(:,:,i)=x;
        else
            vol(:,:,odim(3)-i+1)=x;
        end
    end
    fprintf('\n');
    fprintf('Writing %s\n',output);
    saveastiff(vol,output,options);
    
else % output_is_file==1 && input_is_file==1
    vol=zeros(odim,'uint16');
    options.color     = false;
    options.compress  = 'adobe';
    options.message   = true;
    options.append    = false;
    options.overwrite = true;
    if 2*prod(odim)>=4*(1024^3)
        options.big       = true;
    else
        options.big       = false;
    end

    for i=progress(1:odim(3))
        x=imread(input,'Index',i);
%         fprintf('%d,',i);
        if strcmpi(udflip,'yes')
            x=flipud(x);
        end
        if strcmpi(lrflip,'yes')
            x=fliplr(x);
        end
        if dsfactor~=1
            x=imresize(x,1/dsfactor,'bilinear');
        end
        if strcmpi(zflip,'no')
            vol(:,:,i)=x;
        else
            vol(:,:,odim(3)-i+1)=x;
        end
    end
    fprintf('\n');
    fprintf('Writing %s\n',output);
    saveastiff(vol,output,options);
end
toc;
ret=0;    
    