function Generate_Stats(varargin)
% 
% function Generate_Stats(CsvDir,Label_info,Segmentation_ds,dsfactor,...
%                             Segmentation_origspace,cellsizerange,Cell_Images)
% 
% CsvDir             Output directory where CSV files  written, each csv
%                    contains info about each cell segmentation count
% Label_Info         A text file containing label names (usually present in 
%                    /data/NIMH_MHSNIR/BigClearmap/atlas/atlas_info.txt
% Segmentation_ds    Discreet registered label image (atlaslabel_def_masked.nii.gz) 
%                    but masked by the hemisphere mask, in the downsampled space. 
%                    The label boundaries are computed from this image.                    
% DSFACTOR           Same downsampling factor used to generate the downsampled
%                    image, e.g. 6x6x5. This must be a "x" separated string.
% Segmentation_origspace  Discreet registered label image
%                    (atlaslabel_def_origspace) on the original space. The cells
%                    are counted on this space.
% CellSizeinPx       Cell size range in pixels, a 2x1 comma separated pair
%                    denoting min and max cell size. Default 9,900. **If the max
%                    cell size is larger than 65535, there might be problem.**
% Cell_images        Multiple cell segmentation images, binary, output of
%                    ApplyFRSTseg script, i.e. FRST_seg folder content

N=length(varargin);
csvdir=varargin{1};
label=varargin{2};
seg_ds=varargin{3};
dsf=varargin{4};
seg=varargin{5};
% cellradii=varargin{6};
cellsizerange=varargin{6};  % a 2x1 array to denote maximum cell size to find, default 9,900

temp=strsplit(dsf,'x');
dsfactor=[];
for k=1:3
    dsfactor(k)=str2num(temp{k});
end
if isdeployed
%     cellradii=str2num(cellradii);
    cellsizerange=str2num(cellsizerange);
end
if length(cellsizerange) ~=2
    fprintf('ERROR: Cell size range must be a comma separated pair, e.g. 9,900. \n');
    fprintf('ERROR: You entered %s\n',num2str(cellsizerange));
    return;
end
% cellradius=min(cellradii);

cells=cell(N-6,1);
for i=7:N
    cells{i-6}=varargin{i};
end
fprintf('%d cell segmentation images found.\n',length(cells))
% labelinfo=readtable(label,'delimiter','tab','headerlines',1);
labelinfo=readtable(label,'delimiter','comma','headerlines',1);
labelinfo=table2cell(labelinfo);
L=size(labelinfo,1);
LID=zeros(L,1);
LName=cell(L,1);
LAcronym=cell(L,1);
for j=1:L
    LID(j)=labelinfo{j,1};
    LName{j}=strrep(labelinfo{j,2},' ','_');
    LName{j}=strrep(LName{j},',','');
    LAcronym{j}=strrep(labelinfo{j,3},' ','_');
    LAcronym{j}=strrep(LAcronym{j},',','');
    
end

fprintf('%d labels found in the atlas info file.\n',size(labelinfo,1));


if isfolder(seg)
    segfilelist=rdir(fullfile(seg,'*.tif'));
    info=imfinfo(segfilelist(1).name);
    dim=[info(1).Height info(1).Width length(segfilelist)];
elseif isfile(seg)
    info=imfinfo(seg);
    dim=[info(1).Height info(1).Width length(info)];
end
fprintf('Original segmentation image dimension = %d x %d x %d.\n',dim(1),dim(2),dim(3));

[~,~,ext]=fileparts(seg_ds);
if strcmpi(ext,'.tif') || strcmpi(ext,'.tiff')
    seg_ds_vol=load3Dtiff(seg_ds,0);
elseif strcmpi(ext,'.nii') || strcmpi(ext,'.gz')
    temp=load_untouch_nii(seg_ds);
    seg_ds_vol=permute(temp.img,[2 1 3]);
end
dim_ds=size(seg_ds_vol);
fprintf('Dowsampled segmentation image dimension = %d x %d x %d\n',size(seg_ds_vol,1),...
    size(seg_ds_vol,2),size(seg_ds_vol,3));


if ~isfolder(csvdir)
    mkdir(csvdir);
end
% Write the cell volume stats in a different folder, because mask_correction
% will use csvdir/*.csv as a wildcard

csvdir2=fullfile(csvdir,'cellvolumes'); 
mkdir(csvdir2);





fprintf('Finding z boundaries of each label: \n');
% tStart = tic; 
SliceBoundary=cell(dim_ds(3),1);

for k=1:dim_ds(3)
    x=seg_ds_vol(:,:,k);
    U=unique(x(x>0));
    SliceBoundary{k}=U;
end

LabelRange=zeros([L 6],'single');
for l=1:L
    for k=1:dim_ds(3)
        if ~isempty(find(SliceBoundary{k}==LID(l)))
            if k==1
                LabelRange(l,1)=1;
            else
                LabelRange(l,1)=round((k-1)*dsfactor(3));
            end
            break;
        end
    end
end
for l=1:L
    for k=dim_ds(3):-1:1
        if ~isempty(find(SliceBoundary{k}==LID(l)))
            if k==dim_ds(3)
                LabelRange(l,2)=dim(3);
            else
                LabelRange(l,2)=round((k+1)*dsfactor(3));
            end
            % This upper bound should ideally be k*dsfactor, but the downsampled image dimension is
            % not exactly a multiple of original image dimension, so a safe
            % choice is to add another additional slice/dsfactor(3). This is an
            % overestimation is most cases though.
            break;
        end
    end
end
% tEnd = toc(tStart);
% fprintf('took %.2f seconds.\n',tEnd);
fprintf('Finding x-y bounding box for each label: \n');
% tStart = tic; 
% temp=zeros([L 4 dim_ds(3)],'single');

for l=1:L
    try
    K=round((LabelRange(l,2)-LabelRange(l,1))/dsfactor(3));
    cp=zeros(K,4);
    count=1;
    for k=max(1,floor(LabelRange(l,1)/dsfactor(3))):min(dim_ds(3),ceil(LabelRange(l,2)/dsfactor(3)))
        % min(dim_ds is required because we added (k+1)*dsfactor
        x=seg_ds_vol(:,:,k);
        y=cropparams(x,LID(l));
        if ~isempty(y)
            cp(count,:)=y;
        else
            cp(count,:)=[dim_ds(1) 1 dim_ds(2) 2];
        end
        count=count+1;
    end
    cp=[round(min(cp(:,1)-1)*dsfactor(1)) round(max(cp(:,2)+1)*dsfactor(1)) ...
        round(min(cp(:,3)-1)*dsfactor(2)) round(max(cp(:,4)+1)*dsfactor(2))];
    % Intentionally adding one more pixel in the downsampled space because dim
    % is not always multiple of dim_ds
    if cp(1)<1 cp(1)=1; end
    if cp(2)>dim(1) cp(2)=dim(1); end
    if cp(3)<1 cp(3)=1; end
    if cp(4)>dim(2) cp(4)=dim(2); end
    LabelRange(l,3:6)=cp;
    catch e
        fprintf('Label %d does not exist in the label image.\n',LID(l));
    end
end
% LabelRange=[K1 K2 I1 I2 J1 J2]; in this order


% tEnd = toc(tStart);
% fprintf('took %.2f seconds.\n',tEnd);
setenv('MATLAB_SHELL','/bin/sh');
username=getenv('USER');
numcpu=8; % required memory is linearly proportional to numcpu, so 8 is fine for small images
n=feature('numcores');
if n<numcpu
    fprintf('Warning: number of available cpu = %d, you entered %d.\n',n,numcpu);
    numcpu=n;
end
if isempty(gcp('nocreate'))


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

fprintf('Computing segmentation volumes (in pixels): ');
% This must be done on the original space
tStart = tic;   
temp=cell(dim(3),1);
labelvol=zeros(L,1);
if isfile(seg)
    for k=1:dim(3)
%         fprintf('.');        
        x=imread(seg,'Index',k);        
        h=histc(x(:),LID);
        labelvol=labelvol+h;        
    end
else
    parfor k=1:dim(3)     
%         fprintf('.'); 
        x=imread(segfilelist(k).name);
        h=histc(x(:),LID);
        temp{k}=h;
%         if mod(k,20)==0  fprintf('\n'); end
    end
    for k=1:dim(3)
        labelvol=labelvol+temp{k};
    end
end
tEnd = toc(tStart);
fprintf('took %.2f seconds.\n',tEnd);

%===============================
% Find the max size of the volume to be loaded
tempdim=zeros(L,3);
tempdim(:,1)=LabelRange(:,4)-LabelRange(:,3)+1;
tempdim(:,2)=LabelRange(:,6)-LabelRange(:,5)+1;
tempdim(:,3)=LabelRange(:,2)-LabelRange(:,1)+1;

V=round(2*prod(tempdim,2)/(1024^3));  % 2 because cellvol is logical and same amount of 
                                      % memory required during bwconncomp
fprintf('WARNING: Max memory required for a "single" label is %d GB.\n',max(V));
if max(V)>20  % With renew_parpool, new pools are created for every label
    
%     fprintf('WARNING: I will downsample the image by %d (minimum of cell radius).\n',cellradius);
%     downsample_img=cellradius;
    % Cells are computed in the downsampled space, and the volumes are
    % multiplied by min(cellradius)^2. So the cell volumes will always be
    % multiples of min(cellradius)^2. This could look odd in statistics
%     downsample_img=1; % don't downsample, get the original volume because the indices are required
    renew_parpool=1;
    numcpu=4;  % For very large images, use 4 pools instead of 8
    % If the image is too big, more often than not one of the pools dies
    % because of more memory required than allocated. Then the remaining pools 
    % work fine, but they may slow down the computation for next cell
    % segmentations. So new pools are created for every cell segmentation
    % labels.
else
    %     downsample_img=1;
    renew_parpool=0;
    numcpu=8;
    
end

fprintf('Counting cells now : \n');


for i=1:length(cells)
    if renew_parpool
        
        delete(gcp('nocreate'));
        
        tempdirname=tempname(fullfile('/home',username,'.matlab','local_cluster_jobs','R2022a'));
        mkdir(tempdirname);
        cluster=parallel.cluster.Local();
        cluster.NumWorkers=numcpu;
        cluster.JobStorageLocation=tempdirname;
        fprintf('Temp Job directory = %s\n',tempdirname);
        pl=parpool(cluster);
    end
    
    tStart = tic;
    fprintf('Working on %s\n',cells{i});
    if isfolder(cells{i})
        cellfilelist=rdir(fullfile(cells{i},'*.tif'));
    end
    LABELstats=zeros(L,3);
    LABELstats(:,1)=LID;
    LABELstats(:,3)=labelvol';
    
    tempLABELcount=zeros(L,1);
    
    fprintf('Counting cells on %d labels :',L);
    cellsizeinpx=cell(1,L); % cell volume in pixels
    cellsizeinpx_indx=zeros(L,1);
    cellpixelIDlist=cell(L,1);  % add a 3x1 pixel indices [I,J,K] of each positive cell
    for t=1:L
        cellsizeinpx{t}=[];
        cellpixelIDlist{t}=[];
    end
    rng('shuffle');
    lIndx=randsample(L,L);
    % Shuffle the indices so that not all iterations are deterministic. If it is
    % deterministic, then one or two pools may be assigned the biggest regions,
    % so only one or two pools work for a long time. Shuffling randomizes and
    % tries to make all pools works
    
    parfor l1=1:L    
        
        l=lIndx(l1);
        try
            
            I1=max(1,LabelRange(l,3)-5);
            I2=min(LabelRange(l,4)+5,dim(1));
            J1=max(1,LabelRange(l,5)-5);
            J2=min(LabelRange(l,6)+5,dim(2));
            K1=max(1,LabelRange(l,1)-5);
            K2=min(LabelRange(l,2)+5,dim(3));
            % Don't threshold the cellvol by segvol==label because some cells
            % can overlap between multiple labels
            cellvol=read_image(cellfilelist,I1,I2,J1,J2,K1,K2,'logical',255);
            pdim=size(cellvol);
            
%             cellvol=logical(cellvol>0);
            cc=bwconncomp(cellvol,18);
%             f1=zeros(cc.NumObjects,1);
%             for uu=1:cc.NumObjects
%                 f1(uu)=length(cc.PixelIdxList{uu});
%             end
%             fprintf('Label %d: Correcting %d out of total %d cells with size above %d\n',...
%                 LID(l),length(find(f1>cellsizerange(2))),cc.NumObjects,cellsizerange(2))
            cellvol=0; % free the memory
            
            
            segvol=read_image(segfilelist,I1,I2,J1,J2,K1,K2,'logical',LID(l));
%             segvol=segvol==LID(l);
            
            % function [count,cellsize]=number_of_cells(cc,segvol,label)
            [temp1,temp2,cc1,uid]=number_of_cells(cc,segvol,LID(l),cellsizerange);            
            % Why is UID needed? UID is used later to identify cells. Instead of
            % a bwconncomp on the whole image, it is easier to do a unique of
            % the UIDs of the cellpixelIDlist matrix. Once a cell pixel list is
            % identified, its downsampled version on heatmaps can be easily
            % calculated by the downsampling factor. UID are
            % label+cellcount/(2*max(cellcount))
            segvol=0;
            temp3=[];
            % 1st column of cellpixelIDlist is the unique ids
            for uu=1:temp1
                [I J K]=ind2sub(pdim,cc1{uu});
                a=[I+I1-1 J+J1-1 K+K1-1];  % original index of the image
                b=uid(uu)*ones(length(I),1);
                c=temp2(uu)*ones(length(I),1);
                c=cat(2,b,c,a); % uids to check which cell, cellsize, indices
                temp3=cat(1,temp3,c); % temp3 UID has LID(l), which is not the same as cellsizeinpx UIDs, l
            end
            
            cellpixelIDlist{l1}=temp3;
%             cellvol2=zeros(size(cellvol),'single');
%             for uu=1:temp1
%                cellvol2(cc1{uu})=length(cc1{uu});
%             end

%             LABELstats(l,2)=temp1;
            cellsizeinpx{l1}=temp2; 
            tempLABELcount(l1)=temp1;
            cellsizeinpx_indx(l1)=LID(l);
%             LABELstats(l,2)=number_of_cells(cc,segvol,LID(l));
            
        catch e
            fprintf('WARNING: Label %d is missing in the segmentation.\n',LID(l));
            cellsizeinpx_indx(l1)=LID(l);
            tempLABELcount(l1)=0;
%             LABELstats(l,2)=0;
        end
                
    end
    tEnd = toc(tStart);
    fprintf('took %.2f seconds.\n',tEnd);
    if renew_parpool        
        delete(pl);        
        rmdir(tempdirname,'s');        
    end
    % Reorganize cellsizeinpx to be a matrix
    f=0;
    for l=1:L
        f=f+length(cellsizeinpx{l});
    end
    f1=f;  % number of cells
    temp=zeros([f 2],'double');  % why double and not single? this contains the 
                                 % cell indices which could overflow the single
                                 % integer accuracy, which is essentially half
                                 % of 32bit integer accuracy. index should never
                                 % be single precision
    cellcount=0;
    cellsizeinpx_orig=cellsizeinpx;
    for l=1:L
        l1=find(cellsizeinpx_indx==LID(l));
        f=length(cellsizeinpx{l1});
%         f2(l)=sum(cellsizeinpx{l1});
        temp(cellcount+1:cellcount+f,1)=LID(l);
        temp(cellcount+1:cellcount+f,2)=cellsizeinpx{l1};
%         fprintf('%d,%d,%d,%d\n',l,l1,sum(f2),sum(temp(:,2)));
        cellcount=cellcount+f;
       
    end
    cellsizeinpx=temp; 
    fprintf('Total %d cells found within the volume (min/max/99th percentile = %d/%d/%d voxels).\n',...
        f1,min(cellsizeinpx(:,2)),max(cellsizeinpx(:,2)),round(quantile(cellsizeinpx(:,2),0.99)));   


    
    for l=1:L
        l1=find(cellsizeinpx_indx==LID(l));
        LABELstats(l,2)=tempLABELcount(l1);
    end
    
    
              
    
    if isfile(cells{i})
        [~,s,~]=fileparts(cells{i});
    elseif isfolder(cells{i})
        s=basename(cells{i});
    end
    % Write the cell count csv
    s=fullfile(csvdir,[s '.csv']);
    fprintf('Writing %s\n',s)
    fp1=fopen(s,'w');
    fprintf(fp1,'Label_ID,Name,Acronym,Cell_Count,Label_Volume(Pixels)\n');
    for t=1:L       
        fprintf(fp1,'%d,%s,%s,%d,%d\n',...
            LABELstats(t,1),LName{t},LAcronym{t},LABELstats(t,2),LABELstats(t,3));
        
    end
    fclose(fp1);
    % Write the cellsizeinpx 
     if isfile(cells{i})
        [~,s,~]=fileparts(cells{i});
    elseif isfolder(cells{i})
        s=basename(cells{i});
    end
    s=fullfile(csvdir2,[s '_cellvolume_in_pixels.csv']);
    fprintf('Writing %s\n',s)
    writematrix(cellsizeinpx,s);
    
    % write the cell pixels in mat format because they could be very big
     if isfile(cells{i})
        [~,s,~]=fileparts(cells{i});
    elseif isfolder(cells{i})
        s=basename(cells{i});
    end
    s=fullfile(csvdir2,[s '_cellpixelIDlist.mat']);
    fprintf('Writing %s\n',s)
    save(s,'-nocompression','-v7.3',"cellpixelIDlist");
    % for very large files, v7.3 is required
    
    
end
if ~isempty(pl)
    delete(pl);
    try
        rmdir(tempdirname,'s');
    end
end
end



function vol=read_image(input,I1,I2,J1,J2,K1,K2,imagetype,label)
% This function reads the volume within a cube mentioned by [I1:I2 J1:J2 K1:K2]
% imagetype is either uint16 (for intensity images) or logical (for binary
% images)
% The label indicates to return a logical volume for img==label. It is useful to
% return the segvol as logical volume to save memory.
if nargin<9
    label=1;
end

dim=[I2-I1+1 J2-J1+1 K2-K1+1];
% downsample the image in X-Y, this is alright because the downsampling factor
% is the minimum cell radius
% dim=[round(dim(1:2)/ds) dim(3)];

if strcmpi(imagetype,'uint16')
    vol=zeros(dim,'uint16');
elseif strcmpi(imagetype,'logical')
    vol=zeros(dim,'logical');
elseif strcmpi(imagetype,'uint8')
    vol=zeros(dim,'uint8');
end
% vol=cell(dim(3),1);
klist=K1:K2;
% count=1;
% DONT USE PARFOR AND CELLTOMAT, it requires double the memory.
for kk=1:length(klist)
    
    x=imread(input(klist(kk)).name,'PixelRegion',{[I1 I2],[J1 J2]});
%     if ds>1
%         x=imresize(x,[dim(1) dim(2)],'nearest');
%         % always use nearest neighbour interpolation because the images are
%         % either binary seg or discreet label
%     end
    if strcmpi(imagetype,'uint16')
        x=uint16(x);
    elseif strcmpi(imagetype,'logical')
        x=logical(x==label);
    elseif strcmpi(imagetype,'uint8')
        x=uint8(x);
    end
%     vol{kk}=x;
    vol(:,:,kk)=x;
%     count=count+1;
end
% vol=celltomat(vol);
    
end

    
function [count,cellsize,cc1,uid]=number_of_cells(cc,segvol,label,cellsizerange)
% cc       bwconncomp structure
% segvol   segmentation uin16 volume, within which number of objects in cc will
%          be counted
% 
% label    segvol==label will be used
% 

count=0;
cc1=[];
cellsize=zeros(cc.NumObjects,1);
uid=[];
for t=1:cc.NumObjects
    % if a cell is overlapping multiple labels, only the mode label is 
    % selected. i.e. if the mode corresponds to the given label, its cell count
    % is incremented. This is definitely more time consuming but more accurate.
    % This is also 4x memory requirement, because the segvol is in uint16 size,
    % so that the mode can be calculated. Easier and less memory hogging option
    % would be to pass label into the read_image function, read the volume and
    % use the label to convert that to logical, then find intersection of the
    % the two logical volumes
    if length(cc.PixelIdxList{t})>=cellsizerange(1) && length(cc.PixelIdxList{t})<=cellsizerange(2)
        a=mode(segvol(cc.PixelIdxList{t}));
        a=a(1);
        if a==1 % segvol is logical now
%         if a==label
            count=count+1;
            cellsize(count)=length(cc.PixelIdxList{t});
            cc1{count}=cc.PixelIdxList{t};
            
        end
    elseif length(cc.PixelIdxList{t})>cellsizerange(2)
        a=mode(segvol(cc.PixelIdxList{t}));
        a=a(1);
        if a==1 
%         if a==label
            cc2=make_watershed(cc.PixelIdxList{t},size(segvol));
            for n=1:cc2.NumObjects
                if length(cc2.PixelIdxList{n})<=cellsizerange(2) && length(cc2.PixelIdxList{n})>=cellsizerange(1)
                    count=count+1;
                    cellsize(count)=length(cc2.PixelIdxList{n});
                    cc1{count}=cc2.PixelIdxList{n};
                end
            end
                    
        end
    end
end
cellsize=cellsize(1:count);
uid=label+[1:count]/(2*count);

end

function dim=get_info(input)
if isfolder(input)    
    filelist=rdir(fullfile(input,'*.tif'));
    info=imfinfo(filelist(1).name);
    dim=[info(1).Height info(1).Width length(filelist)];
elseif isfile(input)
    info=imfinfo(input);
    dim=[info(1).Height info(1).Width length(info)];   
else
    fprintf('ERROR: Input should be a folder containing 2D slices, or a 3D tif volume.\n');
    
    dim=[0 0 0];
end
end

function cp=cropparams(img,label) 
% img is a 2D array

[I,J]=find(img==label);
cp=[min(I) max(I) min(J) max(J)];
end


function cc1=make_watershed(pxidlist,dim)
[I J K]=ind2sub(dim,pxidlist);
bw=zeros(dim,'logical');
bw(pxidlist)=1;
I1=min(I);I2=max(I);J1=min(J);J2=max(J);K1=min(K);K2=max(K);
bw=bw(I1:I2,J1:J2,K1:K2);

D=bwdist(single(~bw));L=watershed(-D,18);L(~bw)=0;
cc1=bwconncomp(L,18);
% This is done so that the bwconncomp is applied only on the cropped cell
% volume. Then the indices are upsampled to original dimension
for t=1:cc1.NumObjects
    a=cc1.PixelIdxList{t};
    [m n p]=ind2sub(size(bw),a);
    m=m+I1-1;n=n+J1-1;p=p+K1-1;  % go to original dimension
    b=sub2ind(dim,m,n,p);
    cc1.PixelIdxList{t}=b;
end

% L1=zeros(dim,'uint16');
% L1(I1:I2,J1:J2,K1:K2)=L;


end



