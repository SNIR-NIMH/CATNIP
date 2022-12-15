#!/bin/bash
exe_name=$0
exe_dir=`dirname "$0"`

if [ $# -lt "3" ]; then
    echo "Usage:
    ./Downsample3D.sh INPUTDIR OUTPUTIMAGE DSFACTOR TEMPLATE XML
    INPUTDIR      Input directory containing tiff images
    OUTPUTIMAGE   Output downsampled images
    DSFACTOR      Downsample factor, either a scalar (e.g. 5), or a comma
                  separared triplet (e.g. 5,5,4), meaning x-y dimensions will
                  be downsampled by 5, and z by 4. Useful if z resolution is
                  low but x-y resolution is high. Factor must be integers. A
                  reasonable number is 5,5,5
    TEMPLATE      A template nifti file to get headers from. If it is not
                  provided, then the default nifti headers will be used, which is
                  typically incorrect. For correct nifti headers, use a
                  template nifti. Only resolution and image dimension will be
                  changed from the template header, rest of the header
                  information will be kept.
    XML           The first OME tiff file or the directory containing the 2D OME
                  tiff files that has the header containing resolutions.
    "
    exit 1
fi
  
export MCR_INHIBIT_CTF_LOCK=1  
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
DS=$3
TEMPLATE=$4
XML=$5
echo ${exe_dir}/Downsample3D $INPUT $OUTPUT $DS $FLIP $TEMPLATE $XML
${exe_dir}/Downsample3D $INPUT $OUTPUT $DS $FLIP $TEMPLATE $XML


rm -rf ${MCR_CACHE_ROOT}
