function binarize(input,output)

% function binarize(input,output)
% 
% Binarize a Nifti file and write as unsigned integer


x=load_untouch_nii(input);
x.img=uint8(x.img>0);
x.hdr.dime.datatype=2;
x.hdr.dime.bitpix=8;
save_untouch_nii(x,output)