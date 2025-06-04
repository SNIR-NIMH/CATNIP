function N4Process(input,n4field,outputdir,dsfactor)
% 
% function N4Process(input,n4field,outputdir)
% 
% INPUT         Directory containing original tiff images (e.g., 640 channel
%               images), or a 3D tiff/nifti image
% N4FIELD       N4 bias field image, must have same dimension as the INPUT
% OUTPUTDIR     Output directory where corrected images are written
% DSFACTOR      (Optional) A downsampling factor to downsample the field image
%               to compute its mode. Default 5x5x5. It can be same as the
%               downsampling factor used originally. It must be string separated
%               by x, e.g. 6x6x5


if nargin==3
    dsfactor=[5 5 5];
elseif nargin>=4
    temp=strsplit(dsfactor,'x');
    ds=zeros(1,3);
    for i=1:3
        ds(i)=str2num(temp{i});
    end
    dsfactor=ds;
end

setenv('MATLAB_SHELL','/bin/sh');
username=getenv('USER');
dim1=get_dimension(input);
dim2=get_dimension(n4field);
if dim1(1)~=dim2(1) || dim1(2)~=dim2(2) || dim1(3)~=dim2(3)
    fprintf('ERROR: Input and N4 field must have same dimensions. \n');
    return;
end
fprintf('Input image size = %d x %d x %d\n',dim1(1),dim1(2),dim1(3));
dim=dim1;
if isfolder(input)
    inputfilelist=rdir(fullfile(input,'*.tif'));
end
if isfolder(n4field)
    fieldfilelist=rdir(fullfile(n4field,'*.tif'));
end
if ~isfolder(outputdir)
    mkdir(outputdir);
end
if isfolder(n4field)
    if isempty(gcp('nocreate'))
        numcpu=8;
        n=feature('numcores');
        if n<numcpu
            fprintf('Warning: number of available cpu = %d, you entered %d\n',n,numcpu);
            numcpu=n;
        end
        tempdirname=tempname(fullfile('/home',username,'.matlab','local_cluster_jobs','R2022a'));
        mkdir(tempdirname);
        cluster=parallel.cluster.Local();
        cluster.NumWorkers=numcpu;
        cluster.JobStorageLocation=tempdirname;
        fprintf('Temp Job directory = %s\n',tempdirname);
        p=parpool(cluster);
    else
        p=[];
    end
end

dim2=floor(dim./dsfactor);
fprintf('Renormalizing the field image to %dx%dx%d make mode unity:\n',dim2(1),dim2(2),dim2(3));
% A little subsampling to compute mode
count=1;
if isfile(n4field)
    q=zeros(dim2,'single');
    for k=1:dsfactor(3):dim1(3)
%         fprintf('.');        
        x=imread(n4field,'Index',k);
        q(:,:,count)=imresize(single(x),[dim2(1) dim2(2)],'bilinear');
        count=count+1;
    end
%     fprintf('.');
else
    
    I=round([1:dsfactor(3):dim1(3)]);
    q=cell(length(I),1);
    parfor k=1:length(I)
%         fprintf('%d,',I(k));        
        x=imread(fieldfilelist(I(k)).name);        
        q{k}=imresize(single(x),[dim2(1) dim2(2)],'bilinear');  
%         if mod(k,20)==0 fprintf('\n'); end
    end
    q=celltomat(q);
end
% fprintf('\n');
q=q(:);
q=mode(q(q>0));
fprintf('Scaling the field image by its mode %.2f\n',q);

    
fprintf('Applying the field.\n');
if isfile(input) || isfile(n4field)
    
    for k=1:dim1(3)
        fprintf('.');
        if isfile(input)
            a=single(imread(input,'Index',k));
        else
            a=single(imread(inputfilelist(k).name));
        end
        if isfile(n4field) 
            b=single(imread(n4field,'Index',k));
        else
            b=single(imread(fieldfilelist(k).name));
        end
        b=b/q;
        z=a./b;
%         z=uint16(a./b);
        z(isnan(z))=0;
        z(isinf(z))=0;
        z=uint16(z);  % uint16 comes after floating point operations, not before
        if isfolder(input)
            [~,s,~]=fileparts(inputfilelist(k).name);
            s=[s '_corrected.tif'];
            s=fullfile(outputdir,s);
            
        else
            [~,s,~]=fileparts(input);
            s=[s '_Z' sprintf('%06d',k) '.tif'];
            s=fullfile(outputdir,s);
        end
        imwrite(z,s,'Compression','deflate');
    end    
    fprintf('\n');
else
    
    parfor k=1:dim1(3)
        fprintf('%d,',k);
        a=single(imread(inputfilelist(k).name));
        b=single(imread(fieldfilelist(k).name));
        b=b/q;
        z=a./b;
%         z=uint16(a./b);
        z(isnan(z))=0;
        z(isinf(z))=0;
        z=uint16(z);% uint16 comes after floating point operations, not before
        
        [~,s,~]=fileparts(inputfilelist(k).name);
        s=[s '_corrected.tif'];
        s=fullfile(outputdir,s);        
        imwrite(z,s,'Compression','deflate');
        if mod(k,20)==0 fprintf('\n'); end
    end
   
end
fprintf('\n');
if ~isempty(p)
    delete(p);
    rmdir(tempdirname,'s');
end
end


function dim=get_dimension(input)
if isfolder(input)    
    filelist=rdir(fullfile(input,'*.tif'));
    info=imfinfo(filelist(1).name);
    dim=[info(1).Height info(1).Width length(filelist)];
elseif isfile(input)
    [~,~,ext]=fileparts(input);
    if strcmpi(ext,'.tif') || strcmpi(ext,',tiff')
    
        info=imfinfo(input);
        dim=[info(1).Height info(1).Width length(info)];
    elseif strcmpi(ext,'.nii') || strcmpi(ext,'.gz') || strcmpi(ext,'.hdr')
        x=load_untouch_nii(input);
        dim=size(x.img);
        dim=[dim(2) dim(1) dim(3)]; % nifti and tiff conventions are opposite
    else
        dim=0;
        fprintf('WARNING: Only nifti (.nii,.nii.gz,.hdr) or tiff files are supported.\n');
    end
else
    fprintf('ERROR: Input should be a folder containing 2D slices, or a 3D tif volume.\n');
    dim=0;
end
end
        
        
        