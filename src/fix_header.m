function fix_header(input,output,res)
% 
% function fix_header(input,output,RES)
% INPUT    Input nifti file
% OUTPUT   Output nifti file (could be same)
% RES      Desired resolution, separated by x, e.g. 25x25x25 (HxWxD)
% This script takes a nifti file and edits the resolution to the input string RES
% NOTE: Nifti orientation is WxHxD, but use RES in HxWxD orientation (TIFF
% format)
% E.g. RES=1x2x3 means H=1,W=2,D=3, although Nifti will eventually have 2x1x3.


x=load_untouch_nii(input);
temp=strsplit(res,'x');
for t=1:3
    r(t)=str2num(temp{t});
end
r=[r(2) r(1) r(3)];

x.hdr.dime.pixdim(2:4)=r;
% x.hdr.hist.qform_code=1; % qform_code=1 means pixdim will be read
% x.hdr.hist.sform_code=0; % sform_code=0 means srow_x/y/z will not be read

if x.hdr.hist.srow_x(1)<0
    x.hdr.hist.srow_x(1)=-r(1);
else
    x.hdr.hist.srow_x(1)=r(1);
end
if x.hdr.hist.srow_y(2)<0
    x.hdr.hist.srow_y(2)=-r(2);
else
    x.hdr.hist.srow_y(2)=r(2);
end
if x.hdr.hist.srow_z(3)<0
    x.hdr.hist.srow_z(3)=-r(3);
else
    x.hdr.hist.srow_z(3)=r(3);
end
save_untouch_nii(x,output);