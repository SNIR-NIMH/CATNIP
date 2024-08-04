#!/bin/bash
exe_name=$0
exe_dir=`dirname "$0"`

if [ $# -lt "5" ]; then
    echo "Usage:
    ./create_heatmap.sh INTENSITY_IMAGE  DSFACTOR  OUTPUTDIR  TEMPLATENIFTI  SEG_IMAGE(s)
    
    
 INTENSITY_IMAGE  The 640 channel image that was segmented by FRST to generate 
                  the binary cell segmentation image.    
 DSFACTOR         Downsampling factor, e.g. 6x6x5 (separated by x). It is the
                  same factor that was used to downsample 640 image for
                  registration.
 OUTPUTDIR        Output directory where heat map images (nifti) in the downsampled 
                  (by DSFACTOR) space will be written. They need to be transformed to 
                  the atlas space.
 TEMPLATENIFTI    Template nifti image for headers. It is usually the
                  downsampled 640 or 488 image. *IT IS NOT THE ATLAS*
 SEG_IMAGE(s)     Multiple binary cell segmentation image to be downsampled by
                  DSFACTOR to create heatmap. They are usually the FRST segmentation 
                  images, thresholded by a given threshold
    "
    exit 1
fi
  

MCRROOT=/usr/local/matlab-compiler/v912
export MCR_INHIBIT_CTF_LOCK=1
export MCR_CACHE_ROOT=/tmp/mcr_${USER}_${RANDOM}
mkdir -p ${MCR_CACHE_ROOT}
LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/opengl/lib/glnxa64;
export LD_LIBRARY_PATH;

args=
while [ $# -gt 0 ]; do
    token=$1
    args="${args} ${token}" 
    shift
done
echo ${exe_dir}/create_heatmap $args
${exe_dir}/create_heatmap $args
rm -rf ${MCR_CACHE_ROOT}

