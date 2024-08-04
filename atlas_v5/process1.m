X=readtable('atlas_info_v4a.csv','delimiter','comma','headerlines',1);
X=table2cell(X);
vol=load_untouch_nii('ABA_25um_annotation_axial_nooutlier_noOB.nii');
y=zeros(size(vol.img),'uint16');
N=length(X);
for i=progress(1:N)
    a=cell2mat(X(i,1));
    b=cell2mat(X(i,4));
    indx=find(vol.img==a);
    y(indx)=b;
end
vol.img=y;
save_untouch_nii(vol,'ABA_25um_annotation_axial_nooutlier_noOB_v2.nii');
