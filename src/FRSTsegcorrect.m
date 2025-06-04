function FRSTsegcorrect(atlasimage,cellpxiddir,thresholds,outputdir,numcpu)
% 
% function FRSTsegcorrect(atlasimage,cellpxiddir,outputdir,numcpu)
% 
% ATLASDIR         Registered atlas directory, only used to get dimensions of
%                  the images
% CELLPXIDDIR      The pixelIDList folder where .mat files for the cell pixel
%                  ids are located. Usually it is FRST_seg/cellvolumes/
% THRESHOLDS       Original thresholds that were used
% OUTPUTDIR        Output folder where FRSTseg_xxx_corrected folders will be written
% NUMCPU           (Optional) Number of parallel processes, default 8.


if nargin<5
    numcpu=8;
end
if isdeployed
    thresholds=str2num(thresholds);
    if nargin==5
        numcpu=str2num(numcpu);
    end
end

A=rdir(fullfile(atlasimage,'*.tif'));
x=imfinfo(A(1).name);
dim=[x(1).Height x(1).Width length(A)];
fprintf('Input image dimension %d x %d x %d\n',dim(1),dim(2),dim(3));
if isempty(gcp('nocreate'))
    setenv('MATLAB_SHELL','/bin/sh');
    username=getenv('USER');
    tempdirname=tempname(fullfile('/home',username,'.matlab','local_cluster_jobs','R2022a'));
    mkdir(tempdirname);
    cluster=parallel.cluster.Local();
    cluster.NumWorkers=numcpu;
    cluster.JobStorageLocation=tempdirname;
    fprintf('Temp Job directory = %s\n',tempdirname);
    pl=parpool(cluster);
else
    pl=[];
end


for i=1:length(thresholds)
    ii=num2str(thresholds(i),'%08d');
    s=['FRSTseg_' ii '_cellpixelIDlist.mat'];
    s=fullfile(cellpxiddir,s);
    if ~isfile(s)
        fprintf('ERROR: Mat file for threshold %s is not found at %s\n',ii,s);
    else
        fprintf('Working on %s\n',s)
        x=load(s);
        s1=['FRSTseg_' num2str(thresholds(i),'%08d') '_filtered'];
        s1=fullfile(outputdir,s1);
        if ~isfolder(s1)
            mkdir(s1);
        end
        f=[];
        for l=1:length(x.cellpixelIDlist)
            f(l)=size(x.cellpixelIDlist{l},1);
        end
        fprintf('Total cell volume %d voxels.\n',sum(f));
        
        
        L=length(x.cellpixelIDlist);
%         cellpixelIDlist has uid, cellvolume, I,J,K in 5 columns
        C=zeros([sum(f) 5],'single');
        cc=0;
        for l=1:L
            if f(l)>0
                C(cc+1:cc+f(l),:)=x.cellpixelIDlist{l};
                cc=cc+f(l);
            end
        end
        
        parfor k=1:dim(3)
            fprintf('%d,',k);
            INDX=find(C(:,5)==k);
            b=C(INDX,:);
            s2=['Z' num2str(k,'%05d') '.tif'];
            s2=fullfile(s1,s2);
            
            v=zeros([dim(1) dim(2)],'uint16');
            for j=1:length(INDX)
                v(b(j,3),b(j,4))=b(j,2);
            end
            imwrite(v,s2,'Compress','deflate');
            if mod(k,10)==0 fprintf('\n'); end
        end
        fprintf('\n');
    end
end
fprintf('\n'); 
if ~isempty(pl)
    delete(pl);
    try
        rmdir(tempdirname,'s');
    end
end
