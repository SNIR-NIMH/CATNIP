function ret=ApplyFRST(in_dir,out_FRST_dir,numcpu,radii,downsampled_image,grad_thresh)
% 
% function ret=ApplyFRST(in_dir,out_FRST_dir,numcpu,radii,downsampled_image)
% 
% in_dir           Input directory with channel 640 tif image, or a 3D volume
% out_FRST_dir     Output directory where FRST transform files are written. This 
%                  must be a folder for 32bit images to be written.
% numcpu           Number of parallel cpus to be used
% radii            Vector of radii at which to compute transform. Comma
%                  separated string if used in compiled code. Default is 2,3,4
% Downsampled_Img  (Optional) A downsampled background-removed image to compute
%                  scaling factor. If it is not mentioned, then the original
%                  image (i.e. input_dir) will be downsampled by 6x6x5. For very
%                  large images, use the _brain.nii.gz 
% Gradient_Thresh  (Optional) Gradient threshold for FRST. Default 0.5. A higher
%                  threshold is used to remove more noise. It is a fraction
%                  between 0 and 1.
if isdeployed
    numcpu=str2num(numcpu);
    
end
if nargin<4
    radii=[2 3 4];
    downsampled_image=[];
    grad_thresh=0.5;
end
if nargin==4 
    if isdeployed   
        radii=str2num(radii); % radii is comma separated
    end
    downsampled_image=[];
    grad_thresh=0.5;
end
if nargin==5 
    if isdeployed  
        radii=str2num(radii);
    end
    grad_thresh=0.5;
end
if nargin==6 
    if isdeployed
        radii=str2num(radii);
        grad_thresh=str2num(grad_thresh);
    end
end
if grad_thresh>=1 | grad_thresh<=0
    fprintf('ERROR: Gradient threshold (%.2f) must be a number between 0 and 1.\n',grad_thresh);
    ret=0;
    return;
end
    
setenv('MATLAB_SHELL','/bin/sh');
username=getenv('USER');
if isfolder(in_dir)    
    fprintf('Reading %s\n',in_dir); 
    filelist=rdir(fullfile(in_dir,'*.tif'));
    info=imfinfo(filelist(1).name);
    dim=[info(1).Height info(1).Width length(filelist)];
elseif isfile(in_dir)
    fprintf('Reading %s\n',in_dir);
    info=imfinfo(in_dir);
    dim=[info(1).Height info(1).Width length(info)];   
else
    fprintf('ERROR: Input should be a folder containing 2D slices, or a 3D tif volume.\n');
    ret=0;return;
end
    
fprintf('Image size = %d x %d x %d \n',dim(1),dim(2),dim(3));
fprintf('FRST will be computed for radii %d,',radii(1));
for t=2:length(radii)
    fprintf('%d,',radii(t));
end
fprintf('\n');
    
% mem1=(prod(dim)*4+prod(dim)*2)/(1024^3);  % variable F is single, vol is uint16
mem2=(dim(1)*dim(2)*numcpu*numcpu)*4/(1024^3);
fprintf('WARNING: At least %d GB memory required.\n',ceil(mem2));   
if ~isfolder(out_FRST_dir)
    mkdir(out_FRST_dir);
end

tic

fprintf('Finding appropriate scaling factor: ');
if isempty(downsampled_image)
    fprintf('Downsample by 6x6x5, denoise, and estimate histogram peak.\n');
    dim2=[round(dim(1)/6) round(dim(2)/6) round(dim(3)/5)];
    vol=zeros(dim2,'single');
    count=1;
    for k=1:round(dim(3)/dim2(3)):dim(3)
        fprintf('.');
        if isfile(in_dir)
            x=imread(in_dir,'Index',k);
        else
            x=imread(filelist(k).name);
        end
        x=single(x);
        x=imresize(x,[dim2(1) dim2(2)],'bilinear');
        vol(:,:,count)=x;
        count=count+1;
    end
    fprintf('\n');
else
    [~,~,ext]=fileparts(downsampled_image);
    if strcmpi(ext,'.nii') || strcmpi(ext,'.gz') % nifti .nii or .nii.gz
        vol=load_untouch_nii(downsampled_image);
        vol=vol.img;
    elseif strcmpi(ext,'.tif') || strcmpi(ext,'.tiff')
        vol=load3Dtiff(downsampled_image);
    else
        fprintf('ERROR: Downsampled image must be a TIF (.tiff/.tif) or NIFTI(nii/nii.gz) file.\n');
        ret=0;
        return;
    end
    
end
        
% In the BigClearmap/CATNIP pipeline, the N4 corrected image has background already
% removed by the mask, so no need to have another background removal process
% vol=remove_background_noise(vol,'40',[],'1.05');
sc=find_WM_peak(vol,'T2');
fprintf('Scaling factor = %.4f\n',sc);


if numcpu>1
    p=gcp('nocreate');
    if isempty(p)
        n=feature('numcores');
        if n<numcpu
            fprintf('Warning: number of available cpu = %d, you entered %d\n',n,numcpu);
            numcpu=n;
        end
        tempdirname=tempname(fullfile('/home',username,'.matlab','local_cluster_jobs','R2019b'));
        mkdir(tempdirname);
        cluster=parallel.cluster.Local();
        cluster.NumWorkers=numcpu;
        cluster.JobStorageLocation=tempdirname;
        fprintf('Temp Job directory = %s\n',tempdirname);
        p=parpool(cluster);
%         p=parpool('local',numcpu);
    else
        if p.NumWorkers < numcpu
            delete(p);
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
%             p=parpool('local',numcpu);
        else
            fprintf('Using existing %d pools.\n',p.NumWorkers);
        end
    end
end



% L=dim(3);

fprintf('Running FRST.\n');
% F=zeros(dim,'single');
% L1=numcpu*floor(L/numcpu);

parfor i=1:dim(3)
    
   
    
    if isfolder(in_dir)
        x=imread(filelist(i).name);
        
    else
        x=imread(in_dir,'Index',i);
    end
    x=single(x);
    fprintf('%d,',i);
    x=x/sc;
    x(x>10)=10;  % assuming proper scaling, any bright object is clamped at 10,
    % NAWM intensity being 1
    % This is in accordance with the observation that for some
    % images, the NAWM is around 6000, so clamping any
    % intensity above 60000 is reasonable since the max
    % intensity is 65535 any way.
    x=11-x;
    x=x*10;
    x=single(FRST(x,radii,grad_thresh,2,0));
    % It makes sense to normalize the FRST probabilities by the number of radii,
    % because if there are a very large number of radii, then the probs are just
    % added
    x=x/length(radii);
    
    if isfile(in_dir)
        s=basename(in_dir);
        s=[s '_' sprintf('Z%05d',i)];
        s=fullfile(out_FRST_dir, [s '.tif']);
        imwrite_float32(x,s);
    else
        [~,s,~]=fileparts(filelist(i).name);
        s=[s '_FRST.tif'];
        s=fullfile(out_FRST_dir,s);
        imwrite_float32(x,s);
    end
    
    if mod(i,10)==0 fprintf('\n'); end;
end
fprintf('\n'); 

if ~isempty(p)
    delete(p);
    rmdir(tempdirname,'s');
end
ret=1;
toc
