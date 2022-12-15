#!/bin/bash

exe_name=$0
exe_dir=`dirname "$0"`
if [ $# -lt "4" ];then
    echo "Usage:
    
./upsample_image.sh INPUT OUTPUT OUTPUTSIZE INTERP MEMSAFE COMPRESSION OUTPUTTYPE
 
 INPUT          Input image, either a 3D tif or a folder.
 OUTPUT         Output image, either a 3D tif or a folder. For big images, use a
                folder, where multiple 2D slices will be written
 OUTPUTSIZE     Output image size, in pixels. It must be bigger than input image
                size. E.g. 1000x1000x2000 (separated by "x")
 INTERP         Interpolation type, either nearest, bilinear, or cubic
 MEMSAFE        (Optional) Either true or false, depending if memory efficient 
                image reading is used. Default false.
 COMPRESSION    (Optional) Either true or false, if the output image is to 
                be compressed. Default false, i.e. no compression. 
                * Applicable only if the output is a 3D tif. For an output
                folder, the 2D tif images are always compressed.
 OUTPUTTYPE     (Optional) Either uint16 or float32. Default is uint16.
                 
"
    exit 1
fi

MCRROOT=/usr/local/matlab-compiler/v97
export MCR_INHIBIT_CTF_LOCK=1
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
echo ${exe_dir}/upsample_image $args
${exe_dir}/upsample_image $args


