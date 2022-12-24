#!/bin/bash
if [ $# -lt "4" ]; then
echo "==========================================================================
Usage:
$0 fixed.nii moving.nii mysetting registeredvolume.nii numcpu dsfactor

fixed.nii               Fixed image
moving.nii              Moving image
mysetting               Either forproduction (slowest), fast, or fastfortesting(fastest)
registeredvolume.nii    Registered output image
numcpu                  (Optional) number of cpus to use, default 12
dsfactor                Shrinking factor for each of the 3 levels of registrations,
                        default is 3x2x1. Use higher factor (e.g. 12x6x2 for large images)

NB: fixed/moving/registered volume MUST be nii files
nii.gz is NOT ACCEPTABLE

To transform another image (such as label) using this transform :

1) First, run the following command to make sure the label image
   headers are same as that of moving image
   cp /home/user/labelimage.nii ./otherimage.nii
   fslcpgeom moving.nii otherimage.nii
(Copy because fslcpgeom overwrites files)
2) Then use antsApplyTransforms  to transform the label image,
antsApplyTransforms -d 3 -i otherimage.nii -r fixed.nii -o otherimage_reg.nii -n BSpline/NearestNeighbor -f 0 -v 1 
  -t registeredVolume1Warp.nii.gz -t registeredVolume0GenericAffine.mat
   
========================================================================="
exit 1
fi

#ANTSPATH=/usr/local/apps/ANTs/2.2.0/bin/


dim=3 # image dimensionality


f=$1 
m=$2    # fixed and moving image file names
mysetting=$3
outvol=$4
numcpu=$5
ds=$6
if [ x"$numcpu" == "x" ];then
    numcpu=12
fi
if [ x"$ds" == "x" ];then
    ds=3x2x1
fi
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$numcpu


prefix=`remove_ext ${outvol}`
#prefix=${outvol%.*}
if [ -f "${prefix}.nii" ] || [ -f "${prefix}.nii.gz" ];then
    echo "$prefix exists. I will not overwrite."
    exit 1
fi

bins=64
sigma=1x0.5x0.5vox
reg=antsRegistration  # path to antsRegistration, add ANTS path to $PATH
if [[ $mysetting == "fastfortesting" ]] ; then
  its=100x50x25
  percentage=0.3
  syn="100x5x1,0.0001,4"
elif   [[ $mysetting == "forproduction" ]] ; then
  its=1000x1000x1000
#  its=10000x111110x11110
  percentage=0.3
  syn="100x100x50,0.00001,5"
elif [[ $mysetting == "fast" ]] ; then
   its=100x50x25
  percentage=0.35
  syn="20x20x10,0.00001,5"
else
    echo "ERROR: setting must be either forproduction (slowest), fast, or fastfortesting(fastest)."
    exit 1
fi
START=$(date +%s)


echo "$reg -d $dim -r [ $f, $m ,1] --float -m mattes[  $f, $m , 1 , $bins, regular, $percentage ] -t translation[ 0.1 ] -c [ $its, 1.e-8, 20 ]  -s ${sigma}  -f ${ds} -l 1 -m mattes[  $f, $m , 1 , $bins, regular, $percentage ] -t rigid[ 0.1 ] -c [ $its, 1.e-8, 20 ]  -s $sigma -f $ds -l 1 -m mattes[  $f, $m , 1 , $bins, regular, $percentage ] -t affine[ 0.1 ] -c [ $its, 1.e-8, 20 ]  -s ${sigma}  -f ${ds} -l 1 -m mattes[  $f, $m , 0.5 , $bins ] -m cc[  $f, $m , 0.5 , 4 ] -t SyN[ .20, 3, 0 ]  -c [ $syn ]  -s ${sigma}  -f ${ds} -l 1 -u 1 -z 1 -o [ ${prefix} ] -v 1"
# -w [ 0.01, 0.99 ]
$reg -d $dim -r [ $f, $m ,1]  -m mattes[  $f, $m , 1 , $bins, regular, $percentage ] \
                         -t translation[ 0.1 ] -c [ $its, 1.e-8, 20 ] -s ${sigma} -f ${ds} -l 1 \
                        -m mattes[  $f, $m , 1 , $bins, regular, $percentage ] \
                         -t rigid[ 0.1 ] -c [ $its, 1.e-8, 20 ] -s $sigma -f $ds -l 1 \
                        -m mattes[  $f, $m , 1 , $bins, regular, $percentage ] \
                         -t affine[ 0.1 ] -c [ $its, 1.e-8, 20 ] -s ${sigma} -f ${ds} -l 1 \
                        -m mattes[  $f, $m , 0.5 , $bins ] -m cc[  $f, $m , 0.5 , 4 ] -t SyN[ .20, 3, 0 ] \
                         -c [ $syn ] -s ${sigma} -f ${ds} -l 1 -u 1 -z 1 \
                        -o [ ${prefix} ] -v 1 --float




echo antsApplyTransforms -d $dim -i $m -r $f -o ${prefix}.nii -n BSpline --float -f 0 -v 1 -t  "$prefix"1Warp.nii.gz -t "$prefix"0GenericAffine.mat
antsApplyTransforms -d $dim -i $m -r $f -o ${prefix}.nii -n BSpline --float -f 0 -v 1 -t  "$prefix"1Warp.nii.gz -t "$prefix"0GenericAffine.mat

#fslmaths $outvol -thr 0 $outvol -odt float
echo ImageMath 3 $outvol ReplaceVoxelValue $outvol -65000 0 0
ImageMath 3 $outvol ReplaceVoxelValue $outvol -65000 0 0 


END=$(date +%s)
DIFF=$(( $END - $START ))
((sec=DIFF%60, DIFF/=60, min=DIFF%60, hrs=DIFF/60))
echo "ANTS deformable registration took $hrs HRS $min MIN $sec SEC "

