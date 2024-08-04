#!/bin/bash

exe_name=$0
exe_dir=`readlink -f ${exe_name}`
exe_dir=`dirname ${exe_dir}`

if [ $# -lt "7" ]; then
  echo "Usage:
  ./Generate_Stats.sh CsvDir Label_info Segmentation Cell_Images

CsvDir              Output directory where CSV files are written, each csv
                    contains info about each cell segmentation count
                
Label_Info          A text file containing label names (usually present in 
                    /data/NIMH_MHSNIR/Clearmap/atlas/atlas_info.txt
                
Segmentation_ds     Discreet registered label image (atlaslabel_def_masked.nii.gz) 
                    but masked by the hemisphere mask, in the downsampled space. 
                    The label boundaries are computed from this image.                    
DSFACTOR            Same downsampling factor used to generate the downsampled
                    image, e.g. 6x6x5. This must be a "x" separated string.
Segmentation_origspace  Discreet registered label image
                    (atlaslabel_def_origspace) on the original space. The cells
                    are counted on this space.
CellRadii           Cell radii used to compute FRST. This is used when the
                    image is too. In that case, the X-Y axis is downsampled
                    by the minimum of the cell radii without any loss of cell
                    count. This must be a comma separated.
Cell_images         Multiple cell segmentation images, binary, output of
                    ApplyFRSTseg script, i.e. 640_FRST_seg folder content
"
exit 1
fi
export MCR_INHIBIT_CTF_LOCK=1
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
echo ${exe_dir}/Generate_Stats $args
${exe_dir}/Generate_Stats $args
rm -rf ${MCR_CACHE_ROOT}
