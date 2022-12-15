#!/bin/bash
exe_name=$0
exe_dir=`dirname "$0"`

if [ $# -lt "3" ]; then
    echo "Usage:
    ./nii2tiff.sh INPUTNII  OUTPUTTIFF  OUTPUTTYPE  COMPRESS
     
 INPUTNII        Input 3D nifti file
 OUTPUTTIFF      Output tiff file, either 3D (e.g. somefile.nii) or a directory
                 (e.g. /home/user/some_dir/) where 2D slices will be written                 
 OUTPUTTYPE      Output tiff image type, options are: uint8, uint16, float32.
                 Most common is  uint16
 COMPRESS        A yes/no flag to check if the output images are to be
                 compressed. It is needed only of OUTPUTTIFF is a 3D tiff
                 file. 2D tiff files are always compressed. Default yes.                
    "
    exit 1
fi
MCR_INHIBIT_CTF_LOCK=1
export MCR_CACHE_ROOT=/tmp/mcr_${USER}_${RANDOM}
mkdir -p ${MCR_CACHE_ROOT}


MCRROOT=/usr/local/matlab-compiler/v97
LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/opengl/lib/glnxa64;
export LD_LIBRARY_PATH;
INPUT=$1
OUTPUT=$2
TYPE=$3
COMPRESS=$4
echo ${exe_dir}/nii2tiff ${INPUT} ${OUTPUT} ${TYPE} $COMPRESS
${exe_dir}/nii2tiff ${INPUT} ${OUTPUT} ${TYPE} $COMPRESS

rm -rf ${MCR_CACHE_ROOT}
