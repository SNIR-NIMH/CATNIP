#!/bin/bash

exe_name=$0
exe_dir=`readlink -f ${exe_name}`
exe_dir=`dirname ${exe_dir}`

if [ $# -lt "5" ]; then
  echo "Usage:
  ./mask_correction.sh  ATLASLABEL_DEF   MASK_DS   INPUT_CSV_DIR   OUTPUT_CSV_DIR    MASK_OVL_THRESH
 
 ATLASLABEL_DEF        Registered atlas label image, registered to the downsampled 
                       to the subject image space
 MASK_DS               Exclusion/artifact mask (i.e. exclude pixels >0) downsampled 
                       to the subject image space 
 INPUT_CSV_DIR         Input CSV directory, usually FRST_seg/
 OUTPUT_CSV_DIR        Output CSV directory, usually FRST_seg_corrected, where 
                       corrected csvs are written.
 MASK_OVL_THRESH       A mask volume overlap threshold (between 0 and 1) for 
                       exclusion mask. if the overlab of a label with the mask
                       is more than this, then that label is excluded.
"
exit 1
fi
MCR_INHIBIT_CTF_LOCK=1
export MCR_CACHE_ROOT=/tmp/mcr_${USER}_${RANDOM}
mkdir -p ${MCR_CACHE_ROOT}

MCRROOT=/usr/local/matlab-compiler/v912
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
echo ${exe_dir}/mask_correction $args
${exe_dir}/mask_correction $args

rm -rf ${MCR_CACHE_ROOT}
