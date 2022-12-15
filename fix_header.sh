#!/bin/bash

exe_name=$0
exe_dir=`readlink -f ${exe_name}`
exe_dir=`dirname ${exe_dir}`

if [ $# -lt "3" ]; then
  echo "Usage:
  ./fix_header.sh INPUT  OUTPUT  RES
    INPUT    Input nifti file
    OUTPUT   Output nifti file (could be same)
    RES      Desired resolution, separated by x, e.g. 25x25x25 (HxWxD)
    This script takes a nifti file and edits the resolution to the input string RES
    NOTE: Nifti orientation is WxHxD, but use RES in HxWxD orientation (TIFF format)
    E.g. RES=1x2x3 means H=1,W=2,D=3, although Nifti will eventually have 2x1x3.
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
echo ${exe_dir}/fix_header $args
${exe_dir}/fix_header $args

