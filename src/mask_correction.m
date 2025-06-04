function ret=mask_correction(atlaslabel_def,mask_ds,input_csv_dir,output_csv_dir,mask_ovl_thresh)
% 
% ret=mask_correction(atlaslabel_def,mask_ds,input_csv_dir,output_csv_dir,mask_ovl_thresh)
% 
% ATLASLABEL_DEF        Atlas label image, registered to the downsampled subject
%                       image (a .nii or .nii.gz file)
% MASK_DS               Exclusion/artifact mask (i.e. exclude pixels >0)
%                       downsampled to the target image space (not the atlas
%                       space), a .nii or .nii.gz file
% INPUT_CSV_DIR         Input CSV directory, usually 640_FRST_seg/
% OUTPUT_CSV_DIR        Output CSV directory, where corrected csvs will be
%                       written.
% MASK_OVL_THRESH       A mask volume overlap threshold (between 0 and 1) for 
%                       exclusion mask. if the overlab of a label with the mask
%                       is more than this, then that label is excluded.

if isdeployed
    mask_ovl_thresh=str2num(mask_ovl_thresh);
end
if mask_ovl_thresh>1
    fprintf('WARNING: Mask overlap threshold is a number between 0 and 1. You entered %.4f\n',mask_ovl_thresh);
    mask_ovl_thresh=mask_ovl_thresh/100;
    fprintf('WARNING: I will treat it as percent. Using %.4f as overlap threshold.\n',mask_ovl_thresh);
end

mask=load_untouch_nii(mask_ds);
seg=load_untouch_nii(atlaslabel_def);
U1=unique(seg.img(seg.img>0));% all labels 
U=unique(seg.img(mask.img>0));% labels inside mask
mask.img=uint8(mask.img);


% dim=dim1;
% U=[];  % labels inside mask
% U1=[]; % all labels
% fprintf('Computing labels inside and outside of the mask:\n');
% for k=1:dim(3)
%     fprintf('.');
%     if isfile(mask_image)
%         mask=imread(mask_image,'Index',k);
%     elseif isfolder(mask_image)
%         mask=imread(mask_img_list(k).name);
%     end
%     
%     if isfile(seg_image)
%         seg=imread(seg_image,'Index',k);
%     elseif isfolder(seg_image)
%         seg=imread(seg_img_list(k).name);
%     end
%     seg1=uint16(seg).*uint16(mask>0);
%     
%     u=unique(seg1(seg1>0));
%     U=[U u'];
%     u=unique(seg(seg>0));
%     U1=[U1 u'];
% end
fprintf('\n');
U=unique(U);
U1=unique(U1);
fprintf('There are %d total labels and %d labels inside the mask.\n',length(U1), length(U));

U2=setdiff(U1,U);
fprintf('%d labels will be kept. \n',length(U2));



if ~isfolder(output_csv_dir)
    mkdir(output_csv_dir);
end
A=rdir(fullfile(input_csv_dir,'*.csv'));
fprintf('Writing csvs in the output directory %s\n',output_csv_dir);
for t=1:length(A)
    fprintf('.');
    labelinfo=readtable(A(t).name,'delimiter',',','headerlines',1);
    L=size(labelinfo,1);
    s1=basename(A(t).name);
    
    
    s1=fullfile(output_csv_dir,s1);
    %         fprintf('Writing %s\n',s1)
    fp1=fopen(s1,'w');
    fprintf(fp1,'Label_ID,Name,Acronym,Cell_Count,Label_Volume(Pixels)\n');
    for j=1:L
        LID=labelinfo{j,1};
        seg1=mask.img.*uint8(seg.img==LID);
        a=sum(seg.img(:)==LID); % volume of LID
        b=sum(seg1(:));         % volume of masked region
        a=single(a);b=single(b);
        if b>mask_ovl_thresh*a && b>0 && a>0
            fprintf(fp1,'%d,%s,%s,-1,-1\n',...
                table2array(labelinfo(j,1)),cell2mat(table2array(labelinfo(j,2))),...
                cell2mat(table2array(labelinfo(j,3))));
        else
            try
            fprintf(fp1,'%d,%s,%s,%d,%d\n',...
                table2array(labelinfo(j,1)),cell2mat(table2array(labelinfo(j,2))),...
                cell2mat(table2array(labelinfo(j,3))),table2array(labelinfo(j,4)),...
                table2array(labelinfo(j,5)));
            catch e
                fprintf('\n');
            end
        end
            
      
        
%         if ~isempty(intersect(LID,U2))
%             fprintf(fp1,'%d,%s,%s,%d,%d\n',...
%                 table2array(labelinfo(j,1)),cell2mat(table2array(labelinfo(j,2))),...
%                 cell2mat(table2array(labelinfo(j,3))),table2array(labelinfo(j,4)),...
%                 table2array(labelinfo(j,5)));
%         else
%             fprintf(fp1,'%d,%s,%s,-1,-1\n',...
%                 table2array(labelinfo(j,1)),cell2mat(table2array(labelinfo(j,2))),...
%                 cell2mat(table2array(labelinfo(j,3))));
%         end
    end
    fclose(fp1);
end
fprintf('\n');
ret=0;
end




