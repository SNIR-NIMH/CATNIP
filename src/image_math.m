function image_math(input1,input2,output,operation,numcpu)
% 
% image_math(input1,input2,output,operation,numcpu)
% 
% INPUT1        Input #1, either 3D tiff or a folder
% INPUT2        Input #2, either 3D tiff or a folder
% OUTPUT        Output, either a 3D tiff, or a folder
% OPERATION     Accepted options: add,subtract,difference,multiply,divide, mask.
%               Mask --> create binary mask using non-zero regions of input1 and
%               input2
% NUMCPU        If BOTH inputs AND the output are folders, then slicewise
%               operations are parallelized by NUMCPU
% 
% 
% Both inputs must have the same size. For all operations, user is reponsible to
% make sure output image range lies within UINT16 range.

if nargin==5
    if isdeployed
        numcpu=str2num(numcpu);
    end
end

acceptable_ops={'multiply','divide','add','subtract','difference','mask'};
if ~any(strcmpi(acceptable_ops,operation))
    fprintf('ERROR: Operation must be one of the following: add,subtract,difference,multiply,divide,mask.\n');
    fprintf('ERROR: You entered %s\n',operation);
    return;
end

dim1=get_dimensions(input1);
dim2=get_dimensions(input2);
if dim1(1)~=dim2(1) || dim1(2)~=dim2(2) ||dim1(3)~=dim2(3)
    fprintf('ERROR: Image dimensions must match.\n');
    return;
end
odim=dim1;
otype=get_type(output);
itype1=get_type(input1);
itype2=get_type(input2);
if strcmpi(itype1,'folder')
    inputfilelist1=rdir(fullfile(input1,'*.tif'));
end
if strcmpi(itype2,'folder')
    inputfilelist2=rdir(fullfile(input2,'*.tif'));
end

if strcmpi(otype,'file')
    outvol=zeros(dim1,'uint16');
    for k=progress(1:odim(3))
        if strcmpi(itype1,'file')
            x=imread(input1,'Index',k);
        else
            x=imread(inputfilelist1(k).name);
        end
        if strcmpi(itype2,'file')
            y=imread(input2,'Index',k);
        else
            y=imread(inputfilelist2(k).name);
        end
        if strcmpi(operation,'add')
            x=x+y;
            x(x>65535)=65535;
        elseif strcmpi(operation,'subtract')
            x=x-y;
            x(x<0)=0;
        elseif strcmpi(operation,'difference')
            x=abs(x-y);
        elseif strcmpi(operation,'multiply')
            x=x.*y;
            x(x>65535)=65535;
        elseif strcmpi(operation,'divide')
            x=x./y;
            x(isnan(x))=0;
            x(isinf(x))=0;
        elseif strcmpi(operation,'mask')
            x=uint16(x>0).*uint16(y>0);
        end
        outvol(:,:,k)=x;
    end
    
    options.color     = false;
    options.compress  = 'deflate';
    options.message   = true;
    options.append    = false;
    options.overwrite = true;
    if 2*prod(odim)>=4*(1024^3)
        options.big       = true;
    else
        options.big       = false;
    end
    fprintf('Writing %s\n',output);
    saveastiff(outvol,output,options);
else  % Output is folder, could be parallelized
    if ~isfolder(output)
        mkdir(output);
    end
    if strcmpi(itype1,'file') || strcmpi(itype2,'file')  % one of the input is file
        for k=progress(1:odim(3))
            if strcmpi(itype1,'file')
                x=imread(input1,'Index',k);
            else
                x=imread(inputfilelist1(k).name);
            end
            if strcmpi(itype2,'file')
                y=imread(input2,'Index',k);
            else
                y=imread(inputfilelist2(k).name);
            end
            if strcmpi(operation,'add')
                x=x+y;
                x(x>65535)=65535;
            elseif strcmpi(operation,'subtract')
                x=x-y;
                x(x<0)=0;
            elseif strcmpi(operation,'difference')
                x=abs(x-y);
            elseif strcmpi(operation,'multiply')
                x=x.*y;
                x(x>65535)=65535;
            elseif strcmpi(operation,'divide')
                x=x./y;
                x(isnan(x))=0;
                x(isinf(x))=0;
            elseif strcmpi(operation,'mask')
                x=uint16(x>0).*uint16(y>0);
            end
            s=['Z' sprintf('%06d',k) '.tif'];
            s=fullfile(output,s);
            imwrite(uint16(x),s,'Compression','deflate');
        end
    else  % all inputs and output are folder, so parallelize
        if isempty(gcp('nocreate'))                                    
            tempdirname=tempname(fullfile('/home',getenv('USER'),'.matlab','local_cluster_jobs','R2022a'));
            mkdir(tempdirname);
            mycluster=parallel.cluster.Local();
            mycluster.NumWorkers=numcpu;
            mycluster.JobStorageLocation=tempdirname;
            fprintf('Temp Job directory = %s\n',tempdirname);
            pl=parpool(mycluster,numcpu);
        end
        parfor k=1:odim(3)
            
            x=imread(inputfilelist1(k).name);
            y=imread(inputfilelist2(k).name);
            
            if strcmpi(operation,'add')
                x=x+y;
                x(x>65535)=65535;
            elseif strcmpi(operation,'subtract')
                x=x-y;
                x(x<0)=0;
            elseif strcmpi(operation,'difference')
                x=abs(x-y);
            elseif strcmpi(operation,'multiply')
                x=x.*y;
                x(x>65535)=65535;
            elseif strcmpi(operation,'divide')
                x=x./y;
                x(isnan(x))=0;
                x(isinf(x))=0;
            elseif strcmpi(operation,'mask')
                x=uint16(x>0).*uint16(y>0);
            end
            fprintf('%d,',k);
            s=['Z' sprintf('%06d',k) '.tif'];
            s=fullfile(output,s);
            imwrite(uint16(x),s,'Compression','deflate');
            if mod(k,20)==0
                fprintf('\n');
            end
        end
        fprintf('\n');
        delete(pl);
        rmdir(tempdirname);
    end
        
        
end       
        
        
    
    
end



function dim=get_dimensions(img)

if isfile(img)
    info=imfinfo(img);
    dim=[info(1).Height info(1).Width length(info)];
elseif isfolder(img)
    A=rdir(fullfile(img,'*.tif'));
    info=imfinfo(A(1).name);
    dim=[info(1).Height info(1).Width length(A)];
else
    dim=[0 0 0];
end

end


function ret=get_type(img)
[~,~,ext]=fileparts(img);
if strcmpi(ext,'.tif') || strcmpi(ext,'.tiff')
    ret='file';
else
    ret='folder';
end
end



