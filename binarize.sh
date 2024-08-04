#!/bin/bash

exe_name=$0
exe_dir=`dirname "$0"`

if [ $# -lt "2" ]; then
  echo "
  Usage:
  ./binarize.sh INPUT OUTPUT

    INPUT           Input NIFTI file
    OUTPUT          Output binary NIFTI file
    
  "
  exit 1
fi


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
echo ${exe_dir}/binarize $args
${exe_dir}/binarize $args
