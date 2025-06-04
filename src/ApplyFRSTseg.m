function ret=ApplyFRSTseg(in_FRST_dir,out_FRSTseg_dir,threshold,outputtype)

% function ret=ApplyFRSTseg(in_FRST_dir,out_FRSTseg_dir,threshold,outputtype)
% 
% in_FRST_dir      Input directory where serial FRST files are written. It
%                  is the output of ApplyFRST.m
% out_FRSTseg_dir  Output directory where FRST thresholded files are
%                  written. All thresholded files will be written as 3D tif
%                  stack.
% threshold        A comma separated list of thresholds for FRST output, e.g.
%                  1000,2000,3000. Otherwise it can be a matlab style array,
%                  e.g. 1000:100:5000. Generally, the FRST output was clipped 
%                  to the range [0, 65535].
% outputtype       Either file or folder. If file, each segmentation will be
%                  written as a 3D tif file. If folder, the segmentation images
%                  will be written as 2D tifs in a folder. Use file only for
%                  smaller images.
ret=0;
if ~strcmpi(outputtype,'file') && ~strcmpi(outputtype,'folder')
    ret=1;
    fprintf('ERROR: Outputtype must be either file or folder. You entered %s.\n',outputtype);
    return;
end

if isfolder(in_FRST_dir)  
    fprintf('Reading %s\n',in_FRST_dir); 
    filelist=rdir(fullfile(in_FRST_dir,'*.tif'));
    info=imfinfo(filelist(1).name);
    dim=[info(1).Height info(1).Width length(filelist)];

elseif isfile(in_FRST_dir)
    fprintf('Reading %s\n',in_FRST_dir);
    info=imfinfo(in_FRST_dir);
    dim=[info(1).Height info(1).Width length(info)];
else
    fprintf('ERROR: Input FRST image should be a folder containing 2D slices, or a 3D tif volume.\n');
    ret=1;
    return;
end

thr=str2num(threshold);
fprintf('%d thresholds found.\n',length(thr));
if strcmpi(outputtype,'file')
    segfile=cell(length(thr),1);
    for l=1:length(thr)
        segfile{l}=fullfile(out_FRSTseg_dir,['FRSTseg_' sprintf('%08d',thr(l)) '.tif']);        
    end
else
    segdir=cell(length(thr),1);
    for l=1:length(thr)
        segdir{l}=fullfile(out_FRSTseg_dir,['FRSTseg_' sprintf('%08d',thr(l))]);
        %     Seg files are written in a folder
        mkdir(segdir{l});
    end
end
options2.color     = false;
options2.compress  = 'adobe';
options2.message   = false;
options2.append    = false;
options2.overwrite = true;
if 2*prod(dim)<4*(1024^3)
    options2.big       = false;
else
    options2.big       = true;
end
tic
if strcmpi(outputtype,'file')
    mem=(4*prod(dim)+prod(dim))/(1024^3);
    fprintf('WARNING: Minimum memory required %d GB.\n',ceil(mem));   
    fprintf('Writing FRST segmentation images in %s \n',out_FRSTseg_dir);
    for l=1:length(thr)
        fprintf('Writing to %s\n',segfile{l});
        % Write segmentation images as 3D tiff
        x=uint8(F>=thr(l));
        x=x*255;  % This is done for easy visualization on Fiji
        tic
        saveastiff(x,segfile{l},options2);
        toc;
        
        fprintf('\n');
    end
else  % output is a folder, run in parallel
    setenv('MATLAB_SHELL','/bin/sh');
    username=getenv('USER');
    n=feature('numcores');
    numcpu=8;
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
    if isfile(in_FRST_dir)
        [~,id,~]=fileparts(in_FRST_dir);
        for k=1:dim(3)
            fprintf('.');
            F=imread(in_FRST_dir,'Index',k);
            parfor l=1:length(thr)               
                x=uint8(F>=thr(l));
                x=x*255;  % This is done for easy visualization on Fiji
                s=sprintf('%06d',k);
                s1=sprintf('%06d',thr(l));
                s=fullfile(segdir{l},[id '_T' s1 '_Z' s '.tif']);
                imwrite(x,s,'Compression','deflate');
            end
        end
        fprintf('\n');
    
    else % input is a folder too
        
        parfor k=1:dim(3)
            fprintf('%d,',k);
            F=imread(filelist(k).name);
            for l=1:length(thr) 
                [~,id,~]=fileparts(filelist(k).name);
                x=uint8(F>=thr(l));
                x=x*255;  % This is done for easy visualization on Fiji
                s=sprintf('%06d',thr(l));
                s=fullfile(segdir{l},[id '_T' s '.tif']);
                imwrite(x,s,'Compression','deflate');
            end
            if mod(k,20)==0 fprintf('\n'); end
        end
        fprintf('\n');
    end
    if ~isempty(p)
        delete(p);
        rmdir(tempdirname,'s');
    end
end
toc
    
ret=1;