#!/bin/bash

exe_name=$0
exe_dir=`readlink -f ${exe_name}`
exe_dir=`dirname ${exe_dir}`

if [ $# -lt "4" ]; then
  echo "Usage:
  ./mask_correction.sh SEG_IMAGE   MASK_IMAGE  INPUT_CSV_DIR   OUTPUT_CSV_DIR    
 
 SEG_IMAGE             Segmentation image, usually atlaslabel_def_origspace/
 
 MASK_IMAGE            Exclusion/artifact mask (i.e. exclude pixels >0), must
                       be of the same dimension/orientation as the segmentation image.
                       
 INPUT_CSV_DIR         Input CSV directory, usually 640_FRST_seg/
 
 OUTPUT_CSV_DIR        Output CSV directory, where corrected csvs will be written.
"
exit 1
fi
export MCR_INHIBIT_CTF_LOCK=1
MCRROOT=/usr/local/matlab-compiler/v97
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

