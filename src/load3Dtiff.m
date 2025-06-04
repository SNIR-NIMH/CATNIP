function vol=load3Dtiff(inputtiff,verbose)

% 
% function output=load3Dtiff(input_tiff,verbose)
% 
% INPUT_TIFF          Input 3D tiff image or input directory containing
%                     multiple 2D tiff images
% OUTPUT              Output 3D matrix
% VERBOSE             Verbose flag, 0 or 1

if nargin==1
    verbose=1;
end
if verbose
    tic
end
warning off;
if isfile(inputtiff)
    info=imfinfo(inputtiff);
    if info(1).BitDepth==32
        vol=zeros([info(1).Height info(1).Width length(info)],'single');
    else
        vol=zeros([info(1).Height info(1).Width length(info)],'uint16'); 
    end
    tif=Tiff(inputtiff,'r');
    
    if verbose>0
        for i=progress(1:length(info))
            %         if verbose>0
            %             fprintf('.');
            %         end
            tif.setDirectory(i);
            vol(:,:,i)=tif.read();
        end
    else
        for i=1:length(info)
            %         if verbose>0
            %             fprintf('.');
            %         end
            tif.setDirectory(i);
            vol(:,:,i)=tif.read();
        end
    end
    
elseif isfolder(inputtiff)
    A=rdir(fullfile(inputtiff,'*.tif'));
    fprintf('%d tiff files found.\n',length(A));
    x=imread(A(1).name);
    info=imfinfo(A(1).name);
    if info(1).BitDepth==32
        vol=zeros([size(x,1) size(x,2) length(A)],'single');
    else
        vol=zeros([size(x,1) size(x,2) length(A)],'uint16');
    end
    
    if verbose>0
        for i=progress(1:length(A))
            %         if verbose>0
            %             fprintf('.');
            %         end
            try
            vol(:,:,i)=imread(A(i).name);
            catch e
                fprintf('%s\n',e.message);
            end
            %         tif=Tiff(A(i).name,'r');
            %         vol(:,:,i)=tif.read();
        end
    else
        for i=1:length(A)
%         if verbose>0
%             fprintf('.');
%         end
        vol(:,:,i)=imread(A(i).name);
%         tif=Tiff(A(i).name,'r');                
%         vol(:,:,i)=tif.read();
        end
    end
end
if verbose
    fprintf('\n');
    toc
end
