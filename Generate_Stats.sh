#!/bin/bash

exe_name=$0
exe_dir=`readlink -f ${exe_name}`
exe_dir=`dirname ${exe_dir}`

if [ $# -lt "4" ]; then
  echo "Usage:
  ./Generate_Stats.sh CsvDir Label_info Segmentation Cell_Images

CsvDir          Output directory where CSV files are written, each csv
                contains info about each cell segmentation count
                
Label_Info      A text file containing label names (usually present in 
                /data/NIMH_MHSNIR/Clearmap/atlas/atlas_info.txt
                
Segmentation    Discreet segmentation label image where cells are to be counted

Cell_images     Cell segmentation images, binary

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
echo ${exe_dir}/Generate_Stats $args
${exe_dir}/Generate_Stats $args

