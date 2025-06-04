function ret=Downsample3D(input,outputimage,dsfactor,templatenifti,xmlfile)
% 
% function ret=Downsample3D(inputdir,outputimage,dsfactor,template)
% INPUTDIR      Input directory containing 2D slices or a 3D tif image.
% OUTPUTIMAGE   Output downsampled image (.nii or .tif file, use .nii preferably)
% DSFACTOR      Downsample factor, either a scalar (e.g. 5), or a comma
%               separared triplet (e.g. 5,5,4), or a "x" separated triplet (e.g.
%               (5x5x4), meaning x-y (height x width)
%               dimensions will be downsampled by 5, and z by 4. Useful if z
%               resolution is low but x-y resolution is high. Factor must be integers.
%               A reasonable number is 5,5,5
% TEMPLATE      A template nifti file to get headers from. If it is not
%               provided, then the default nifti headers will be used, which is
%               typically incorrect. For correct nifti headers, use a
%               template nifti. Only resolution will be copied from the 
%               template header, rest of the header information will be kept
% XMLFILE       The first OME tiff file (or the folder containing it as the
%               first file) that has the headers. It is optional. Default
%               resolutions (3.77x3.77x5um) is used if not provided.
setenv('MATLAB_SHELL','/bin/sh');
username=getenv('USER');
ret=0;
warning off;
if nargin<4
    templatenifti=[];
    if strcmpi(outputimage(end-3:end),'.nii')
        fprintf('WARNING: Template nifti image is not provided. Default template will be used.\n');
    end
    xmlfile='none';
end
if nargin<5
    xmlfile='n';
end
if isdeployed || ischar(dsfactor)
    try
        dsfactor2=str2num(dsfactor);
    catch e
        temp=strsplit(dsfactor,'x');
        dsfactor2=zeros(3,1);
        for t=1:3
            dsfactor2(t)=str2num(temp{t});
        end
    end
end
if isempty(dsfactor2)
    temp=strsplit(dsfactor,'x');
    dsfactor2=zeros(3,1);
    for t=1:3
        dsfactor2(t)=str2num(temp{t});
    end
end
dsfactor=dsfactor2;
fprintf('Dowsampling factor = %d x %d x %d \n',dsfactor(1),dsfactor(2),dsfactor(3));

if length(dsfactor)==1
    dx=dsfactor;
    dy=dsfactor;
    dz=dsfactor;
else
    dx=dsfactor(1);
    dy=dsfactor(2);
    dz=dsfactor(3);
end
T1=affine2d([1/dy 0 0;0 1/dx 0;0 0 1]);
T2=affine2d([1/dz 0 0;0 1 0;0 0 1]);
if isfolder(input)
    filelist=rdir(fullfile(input,'*.tif'));
    if isempty(filelist)
        filelist=rdir(fullfile(input,'*.tiff'));
    end
    x=imfinfo(filelist(1).name);
    dim=[x.Height x.Width length(filelist)];
elseif isfile(input)
    info=imfinfo(input);
    dim=[info(1).Height info(1).Width length(info)];
else
    fprintf('ERROR: Input must be a 3D tif image or a folder containing multiple 2D tifs.\n');
    ret=1;
    return;
end
fprintf('Input image size = %d x %d x %d \n', dim(1),dim(2),dim(3));
   

try
%     Move to v2 of the parse_ome_tiff_xml code, the Imspector software has
%     been upgraded
    resx=parse_ome_tiff_xml_v2(xmlfile,'dx','v2')/1000;
    resy=parse_ome_tiff_xml_v2(xmlfile,'dy','v2')/1000;
    resz=parse_ome_tiff_xml_v2(xmlfile,'dz','v2')/1000;
%     resx=parse_ome_tiff_xml(xmlfile,'dx')/1000;
%     resy=parse_ome_tiff_xml(xmlfile,'dy')/1000;
%     resz=parse_ome_tiff_xml(xmlfile,'dz')/1000;
catch e
    fprintf('WARNING: XML header isn''t found in the first tif image : %s\n',xmlfile);
    fprintf('WARNING: Assuming 3.77x3.77x5.0 um resolution.\n');
    fprintf('WARNING: If the resolutions are incorrect, then the registration to atlas may be incorrect.\n');
    fprintf('%s\n',e.message);
    resx=3.77;
    resy=3.77;
    resz=5;
end

odim=zeros(1,3);
odim(1)=length([1:dx:dim(1)]);
odim(2)=length([1:dy:dim(2)]);
odim(3)=length([1:dz:dim(3)]);
fprintf('Output image size = %d x %d x %d \n',odim(1),odim(2),odim(3));
if isfile(input)
    X=zeros([odim(1) odim(2) dim(3)],'single');
elseif isfolder(input)
    X=cell(dim(3),1);
    for k=1:dim(3)
        X{k}=zeros([odim(1) odim(2)],'single');
    end
end

if isfolder(input)
    if isempty(gcp('nocreate'))
        numcpu=8;
        n=feature('numcores');
        if n<numcpu
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
else
    p=[];
end

fprintf('Resampling X-Y dimension:\n');
if isfile(input)
    for k=1:dim(3)
        fprintf('.');
        x=single(imread(input,'Index',k));     
        x=imresize(x,[odim(1) odim(2)],'cubic');
%         x=imwarp(x,T1,'cubic','Outputview',imref2d([odim(1) odim(2)]));
        x(x<0)=0;
        x(x>65535)=65535;
        X(:,:,k)=single(x);
        
    end   
else
    parfor k=1:dim(3)
        fprintf('%d,',k);        
        x=single(imread(filelist(k).name));      
        x=imresize(x,[odim(1) odim(2)],'cubic');
%         x=imwarp(x,T1,'cubic','Outputview',imref2d([odim(1) odim(2)]));
        x(x<0)=0;
        x(x>65535)=65535;
        X{k}=single(x);
        if mod(k,20)==0
            fprintf('\n');
        end
    end
end
fprintf('\n');
vol=zeros(odim,'single');
if isfolder(input)
    Y=zeros([odim(1) odim(2) dim(3)],'single');
    for k=1:dim(3)
        Y(:,:,k)=X{k};
    end
    X=Y;
    Y=[];
end
% Do everything in float, then convert to uint16 if needed
fprintf('Resampling Z dimension:\n');
for i=1:odim(1)
    fprintf('.');    
    x=X(i,:,:);    
    x=squeeze(x);
    x=imresize(x,[odim(2) odim(3)],'cubic');
%     x=imwarp(single(x),T2,'cubic','Outputview',imref2d([odim(2) odim(3)]));
    x(x<0)=0;
    x(x>65535)=65535;
    vol(i,:,:)=x;
%     vol(i,:,:)=uint16(x);
    
end
fprintf('\n');

if ~isempty(p)
    delete(p);
    rmdir(tempdirname,'s');
end
if strcmpi(outputimage(end-3:end),'.tif')
    vol=uint16(vol);
    % If output if tif, use 16bit tifs
    options.color     = false;
    options.compress  = 'adobe';
    options.message   = false;
    options.append    = false;
    options.overwrite = true;
    if 2*numel(vol)<4*(1024^3)
        options.big       = false;
    else
        options.big       = true;
    end
    
    fprintf('Saving %s\n',outputimage);
    saveastiff(vol,outputimage,options);
elseif (strcmpi(outputimage(end-3:end),'.nii') ||strcmpi(outputimage(end-6:end),'.nii.gz')) ...
        && ~isempty(templatenifti)
    vol=permute(vol,[2 1 3]); % nifti x-y is different from tiff x-y
    
%     vxlsize=[resx*dy resy*dx resz*dz]; 
    y=load_untouch_nii(templatenifti);
    vxlsize=y.hdr.dime.pixdim(2:4);
    y.img=vol;
%     y.hdr.dime.pixdim(2:4)=vxlsize;
    y.hdr.dime.dim(2:4)=size(vol);
    % Niftis are small, so always written as 32bit by default
    y.hdr.dime.bitpix=32;
    y.hdr.dime.datatype=16;
    % follow the template, assume it to be accurate
%     y.hdr.hist.qform_code=0; % qform code = 1 means use pixdim
%     y.hdr.hist.sform_code=1; % sform code = 1 means use srow_x etc
    if y.hdr.hist.srow_x(1)<0
        y.hdr.hist.srow_x(1)=-vxlsize(1);
    else
        y.hdr.hist.srow_x(1)=vxlsize(1);
    end
    if y.hdr.hist.srow_y(2)<0
        y.hdr.hist.srow_y(2)=-vxlsize(2);
    else
        y.hdr.hist.srow_y(2)=vxlsize(2);
    end
    if y.hdr.hist.srow_z(3)<0
        y.hdr.hist.srow_z(3)=-vxlsize(3);
    else
        y.hdr.hist.srow_z(3)=vxlsize(3);
    end
    y.hdr.dime.scl_slope=1;
    y.hdr.dime.cal_max=max(y.img(:));
    y.hdr.dime.cal_min=min(y.img(:));
    fprintf('Output image resolution = %.2f %.2f %.2f \n',vxlsize(1),...
        vxlsize(2),vxlsize(3));
    fprintf('Saving %s\n',outputimage);
    save_untouch_nii(y,outputimage);
%     niftiwrite(vol,outputimage,y);
    
else
    fprintf('WARNING: outputimage must be either tif or nifti. I will write a Nifti file\n');
    vol=permute(vol,[2 1 3]); % nifti x-y is different from tiff x-y
    
    vxlsize=[resx*dy resy*dx resz*dz]; 
    fprintf('Output image resolution = %.2f %.2f %.2f \n',vxlsize(1),...
        vxlsize(2),vxlsize(3));
    nii = make_nii(vol, vxlsize, [0 0 0],16);  
    
    nii.hdr.dime.pixdim(1)=1;
    nii.hdr.hist.qform_code=0;
    nii.hdr.hist.sform_code=1; % use sform code, easy to choose
    nii.hdr.hist.srow_x(1:3)=[1 0 0];
    nii.hdr.hist.srow_y(1:3)=[0 1 0];
    nii.hdr.hist.srow_z(1:3)=[0 0 1];
    nii.hdr.hist.srow_x(1)=-vxlsize(1); % Default is LPI, to make RAI,
    nii.hdr.hist.srow_y(2)=-vxlsize(2); % invert x and y orientation
    nii.hdr.hist.srow_z(3)=vxlsize(3);
    nii.hdr.dime.datatype=16;
    nii.hdr.dime.bitpix=32;
    nii.hdr.dime.scl_slope=1;
    nii.hdr.dime.xyzt_units=10; % millimeters
    nii.hdr.dime.cal_max=max(nii.img(:));
    nii.hdr.dime.cal_min=min(nii.img(:));
    fprintf('Saving %s\n',outputimage);
    save_nii(nii,[outputimage '.nii']);
end
ret=0;

