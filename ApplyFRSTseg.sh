#!/bin/bash

exe_name=$0
exe_dir=`dirname "$0"`
if [ $# -lt "3" ]; then
  echo "Usage:
  ./ApplyFRSTseg.sh IN_FRST_DIR OUT_FRSTseg_DIR THRESHOLD  OUTPUTTYPE
 
     IN_FRST_DIR      Input directory where serial FRST files are kept. It could
                      be a 3D tiff image as well. It is the output of ApplyFRST.sh
     OUT_FRSTseg_DIR  Output directory where FRST thresholded files are written. 
                      All thresholded files will be written as 3D tif stack.
     THRESHOLD        A comma separated list of thresholds for FRST output, e.g.
                      1000,2000,3000. Otherwise it can be a matlab style array,
                      e.g. 1000:100:5000. Generally, the FRST output was clipped 
                      to the range [0, 65535].
     OUTPUTTYPE       Either file or folder. If file, each segmentation will be
                      written as a 3D tif file. If folder, the segmentation images
                      will be written as 2D tifs in a folder. Use file only for
                      smaller images.
                      * Default folder
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
INDIR=$1
OUTDIR=$2
THR=$3
TYPE=$4
if [ ! -d "$OUTDIR" ];then
    mkdir -p $OUTDIR
fi
if [ x"$TYPE" == "x" ];then
    TYPE=folder
fi
echo ${exe_dir}/ApplyFRSTseg $INDIR $OUTDIR $THR $TYPE
${exe_dir}/ApplyFRSTseg $INDIR $OUTDIR $THR $TYPE
rm -rf ${MCR_CACHE_ROOT}
