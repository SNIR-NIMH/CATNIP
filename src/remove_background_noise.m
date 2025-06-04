function ret=remove_background_noise(input,quant,output,gradscale)
% function ret=remove_background_noise(INPUT,QUANT,OUTPUT,GRADSCALE)
% INPUT    An input volume, nifti nii/nii.gz, xml file, a 3D matrix, or a 3D
%          tif file/folder containing 2D tif files.
% QUANT    Initial quantile for threshold. E.g. 40 means 40% of the image
%          histogram will be used as initial threshold. Enter as a character
%          array, e.g. '40'.
% OUTPUT   An output volume, nifti nii/nii.gz, xml, or a tif file. If left
%          empty, the output will be returned as a 3D matrix.
% SCALE    A scaling factor to increase threshold at each iteration.
%          Usually 1.2 works well.
% *** Input image type and output image type must match. If input is nifti (or tif),
% output must be nifti (or tif) **

if nargin==1
    output=[];
    quant=40;
    gradscale=1.2;
elseif nargin==2
%     if ~ischar(quant)
%         fprintf('ERROR: Enter the Quantile value as string array. e.g. ''40''\n');
%         ret=0;
%         return;
%     end
    
    if isdeployed || ischar(quant)
        quant=str2num(quant);
    end
    output=[];
    gradscale=1.2;
elseif nargin==3  
    fprintf('Output will be written in %s\n',output);
    gradscale=1.2;
    if isdeployed
        quant=str2num(quant);
    end
elseif nargin==4
    if isdeployed || ischar(gradscale)
        
        gradscale=str2num(gradscale);
    end
    if isdeployed || ischar(gradscale)        
        quant=str2num(quant);
    end
end
fprintf('Quantile = %.2f %%\n',quant);
tic
% Check for input/output type match
if ~isnumeric(input)
    [~,~,ext1]=fileparts(input);
end
if ~isempty(output)
    [~,~,ext2]=fileparts(output);
    if strcmpi(ext1,'.nii') || strcmpi(ext1,'.gz')
        if ~strcmpi(ext2,'.nii') && ~strcmpi(ext2,'.gz')
            fprintf('ERROR: Input image type (NIFTI) must match with output image type.\n');
            ret=1;
            return;
        end
    end

    if strcmpi(ext1,'.tif') || strcmpi(ext1,'.tiff') || isfolder(input)
        if ~strcmpi(ext2,'.tif') && ~strcmpi(ext2,'.tiff')
            fprintf('ERROR: Input image type (TIFF) must match with output image type.\n');
            ret=1;
            return;
        end
    end
end




if ~isnumeric(input)
    fprintf('Reading %s\n',input);
end
if ~isnumeric(input)
    if strcmpi(ext1,'.nii') || strcmpi(ext1,'.gz') % .nii.gz or .nii files
        origvol=load_untouch_nii(input);
        invol=single(origvol.img);
        pixd=origvol.hdr.dime.pixdim(2:4);
    elseif strcmpi(ext1,'.xml')
        [invol,xmlparam]=ReadXml(input);
        pixd=xmlparam.res;
    elseif strcmpi(ext1,'.tif') || strcmpi(ext1,'.tiff')
        invol=load3Dtiff(input,0);
    elseif isfolder(input)  % assume a folder with multiple 2D tifs
        invol=load3Dtiff(input,0);
    else
        fprintf('Only XML and NII files are supported\n');
        ret=0;
        return;
    end
else
    invol=input;
    pixd=[1 1 1];
    
end
fprintf('Input file size %d x %d x %d\n',size(invol,1),...
        size(invol,2),size(invol,3));
invol=single(invol);
Q=quantile(invol(invol>0),quant/100);
fprintf('Initial threshold = %.2f\n',Q);
H=strel('disk',2);
start=invol;
origmask=uint8(invol>0);
err=1;
initmask=origmask;

ratio=[];
for iter=1:8
    
    mask=uint8(start>Q);    
    fprintf('Processing ');
    for t=1:3
        fprintf('.');
        mask=fillholes(mask);
        fprintf('.');
        mask=imclose(mask,H);
    end
    fprintf('\n');    
%     mask=fillholes(mask);    
%     x=uint8(xor(mask,initmask));
%     x=x.*origmask;
%     newerr=sum(x(:))/sum(initmask(:));
    newerr= length(find(initmask~=mask & origmask))/sum(origmask(:));
    ratio(iter)=newerr/err;
    fprintf('Iter = %d, Q= %.2f, ratio = %.4f \n',iter,Q,ratio(iter));
    if iter>=3 % various early terminations for breaks
        if newerr>1 || newerr<=0 || ratio(iter)<=ratio(iter-1)
%             mask=initmask;
            break;
        end
    end
    if ratio(iter)>0.9 && iter>2
%         mask=initmask;
        break;
    else
        err=newerr;
        
    end
%     newerr=1-length(find(initmask~=mask & invol>0))/sum(invol(:)>0);
%     fprintf('iter = %d, Q= %.2f, change = %.4f \n',iter,Q,err);
    start=invol.*single(mask);
    Q=gradscale*Q;
    initmask=mask;
   
end

mask=remove_small_components(mask);
% se=strel('ball',3,3);
mask=imclose(mask,H);
mask=fillholes(mask);
outvol=invol.*single(mask);

if isempty(output)
    ret=outvol;
    fprintf('Output is returned as %d x %d x %d matrix \n',size(ret,1),size(ret,2),size(ret,3));    
else
    if strcmpi(ext2,'.nii') || strcmpi(ext2,'.gz')
%         output(end-2:end)='nii';
%         temp=load_untouch_nii(input);
        origvol.img=outvol;
        origvol.hdr.dime.bitpix=32;
        origvol.hdr.dime.datatype=16;
        fprintf('Writing %s with same header as the input\n',output);
        save_untouch_nii(origvol,output);
        ret=0;
    elseif strcmpi(input(end-2:end),'xml')
        if strcmpi(ext2,'.xml')
            f.res=pixd;
            f.type='Float';
            f.orientation='Axial';
            fprintf('Writing %s with default header\n',output);
            writeXml(outvol,f,output);
            ret=0;
        elseif strcmpi(ext2,'.nii') || strcmpi(ext2,'.gz')
            temp=make_nii(outvol,pixd,[],16);  
            fprintf('Writing %s with default header\n',output);
            save_nii(temp,output);
            ret=0;
        end
    elseif strcmpi(ext2,'.tif') || strcmpi(ext2,'.tiff')
        options.color     = false;
        options.compress  = 'adobe';
        options.message   = false;
        options.append    = false;
        options.overwrite = true;
        options.big       = false;
        % Input image type and output image types must be same, so the axes
        % need not be flipped
        saveastiff(uint16(outvol),output,options);
        ret=0;
    elseif isnumeric(input)
        temp=make_nii(outvol,pixd,[],16);
        fprintf('Writing %s with default header\n',output);
        save_nii(temp,output);
        ret=0;
    end
end
toc    


function outmask=fillholes(inmask)
inmask=uint8(inmask);
U=length(unique(inmask(:)));
if U~=2
    fprintf('ERROR: Input mask must be binary.\n');
    outmask=inmask;
    return;
end
dim=size(inmask);
% fprintf('Z ');
for i=1:dim(3)
    inmask(:,:,i)=imfill(inmask(:,:,i),4,'holes');
end
% fprintf('X ');
for i=1:dim(1)
    inmask(i,:,:)=imfill(squeeze(inmask(i,:,:)),4,'holes');
end
% fprintf('Y ');
for i=1:dim(2)
    inmask(:,i,:)=imfill(squeeze(inmask(:,i,:)),4,'holes');
end
% fprintf('Z\n');
for i=1:dim(3)
    inmask(:,:,i)=imfill(inmask(:,:,i),4,'holes');
end
outmask=inmask;


function mask=remove_small_components(mask)

for k=1:size(mask,3)
    temp=squeeze(mask(:,:,k)); 
    cc=bwconncomp(temp,4);
    f=[];for t=1:cc.NumObjects f(t)=length(cc.PixelIdxList{t}); end;
    L=max(f);
    for t=1:cc.NumObjects
        if length(cc.PixelIdxList{t})<0.02*L
            temp(cc.PixelIdxList{t})=0;
        end
    end
    mask(:,:,k)=temp;
end
for k=1:size(mask,1)
    temp=squeeze(mask(k,:,:)); 
    cc=bwconncomp(temp,4);
    f=[];for t=1:cc.NumObjects f(t)=length(cc.PixelIdxList{t}); end;
    L=max(f);
    for t=1:cc.NumObjects
        if length(cc.PixelIdxList{t})<0.02*L
            temp(cc.PixelIdxList{t})=0;
        end
    end
    mask(k,:,:)=temp;
end
for k=1:size(mask,2)
    temp=squeeze(mask(:,k,:)); 
    cc=bwconncomp(temp,4);
    f=[];for t=1:cc.NumObjects f(t)=length(cc.PixelIdxList{t}); end;
    L=max(f);
    for t=1:cc.NumObjects
        if length(cc.PixelIdxList{t})<0.02*L
            temp(cc.PixelIdxList{t})=0;
        end
    end
    mask(:,k,:)=temp;
end

    


