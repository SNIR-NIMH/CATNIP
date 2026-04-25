Removed these labels:
################################################
# ITK-SnAP Label Description File
# File format: 
# IDX   -R-  -G-  -B-  -A--  VIS MSH  LABEL
# Fields: 
#    IDX:   Zero-based index 
#    -R-:   Red color component (0..255)
#    -G-:   Green color component (0..255)
#    -B-:   Blue color component (0..255)
#    -A-:   Label transparency (0.00 .. 1.00)
#    VIS:   Label visibility (0 or 1)
#    IDX:   Label mesh visibility (0 or 1)
#  LABEL:   Label description 
################################################
41    48  218    0        1  1  0    "optic nerve"
45   134  255   90        1  1  0    "Spinal cord"
76   250  128  114        1  1  0    "spinal trigeminal tract"


1. Remove the above three labels in WHS_SD_rat_atlas_v4.nii as saved as WHS_SD_rat_atlas_v4_removedlabels.nii

2. Create a binary mask of it via FSL,
fslmaths WHS_SD_rat_atlas_v4_removedlabels.nii -bin WHS_SD_rat_atlas_v4_mask.nii -odt char
 
3. Fill the holes of the binary mask via imfill,
x=load_untouch_nii('WHS_SD_rat_atlas_v4_mask.nii');
dim=size(x.img);
for k=1:dim(3)
    x.img(:,:,k)=imfill(x.img(:,:,k),4);
end
save_untouch_nii(x,'WHS_SD_rat_atlas_v4_mask_filled.nii')

4. Multiply the binary mask with the T2star image and the label image
fslmaths WHS_SD_rat_T2star_v1.01.nii -mas WHS_SD_rat_atlas_v4_mask_filled.nii WHS_SD_rat_T2star_v1.01_masked.nii

5. Flip them upside down and in Z so that OB is up and cerebellum is at the beginning of Z.
This is done to conform to the same orientation as the other ABA atlases.

6. Change the resolutions in the header to 25x25x25, instead of 39x39x39. This does
not change any pixel values. This is done only to conform to other ABA atlases, 
which are 25x25x25.


Final atlas images: 
WHS_SD_rat_T2star_v1.01_masked.nii --> FOS image to register
WHS_SD_rat_atlas_v4_removedlabels.nii --> Label image
WHS_SD_rat_atlas_v4_mask_filled.nii --> brainmask
