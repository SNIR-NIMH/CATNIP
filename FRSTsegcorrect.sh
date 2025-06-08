#!/bin/bash
exe_name=$0
exe_dir=`dirname "$0"`

if [ $# -lt "5" ]; then
    echo "Usage:
   ./FRSTsegcorrect.sh ATLASDIR  CELLPXIDDIR  THRESHOLDS OUTPUTDIR  [NUMCPU]

 ATLASDIR         Registered atlas directory, only used to get dimensions of the images
 CELLPXIDDIR      The pixelIDList folder where .mat files for the cell pixel
                  ids are located. Usually it is FRST_seg/cellvolumes/
 THRESHOLDS       Original thresholds that were used
 OUTPUTDIR        Output folder where FRSTseg_xxx_corrected folders will be written
 NUMCPU           (Optional) Number of parallel processes, default 8.


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
echo ${exe_dir}/FRSTsegcorrect $args
${exe_dir}/FRSTsegcorrect $args
rm -rf ${MCR_CACHE_ROOT}

