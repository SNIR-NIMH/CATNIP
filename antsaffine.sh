#!/bin/bash 

NUMPARAMS=$#

if [ $NUMPARAMS -lt 4 ]
then 
echo "USAGE :
antsaffine.sh  fixed.nii  moving.nii  outputvolname.nii  rigidonly(yes/no) numcpu  shrinkfactor

FIXED          Fixed image (nifti nii)
MOVING         Moving image (nifti nii)
OUTPUTVOL      Output image (nifti .nii)
RIGIDONLY      A flag (yes or no), indicating if the registration is rigid (yes) or affine (no)
NUMCPU         Number of parallel processing cores to be used. Optional.
SHRINKFACTOR   Shrink factor, usually 4x2x1. For big images, use larger shrink factor.
"
exit
fi



dim=3
#FSLOUTPUTTYPE=NIFTI
START=$(date +%s)
f=$1
m=$2
output=$3
isrigid=$4
numcpu=$5
shrinkfactor=$6

# ======================================================================
# There is a bug in ANTS where the call must be from within the fixed 
# image's directory # Otherwise there can be an error saying mismatch 
# between number of levels and number of # shrink factors. So cd into the 
# directory and use absolute paths everywhere. See this,
# https://github.com/ANTsX/ANTs/issues/105 (last comment)
f=`readlink -f $f`
m=`readlink -f $m`
output=`readlink -f $output`
#dir=`dirname $f`
#cd $dir
#f=`basename $f`
# ======================================================================
prefix=${output%.*}
#prefix=`remove_ext ${output}` # removing dependence on FSL

if [ x"$numcpu" == "x" ];then
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=12
else
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$numcpu
fi    

echo "Setting environment variable ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS to $ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS"

if [ x"$shrinkfactor" == "x" ];then
    shrinkfactor=4x2x1
fi

AP=`which antsRegistration`
AP=`readlink -f $AP`
if [ -f "$AP" ];then
    AP=`dirname $AP`
    echo "I found ANTs installation at $AP "
else
    echo "I did not find ANTs in your path. Please install ANTs and add the bin directory to your PATH."    
    exit 1
fi 

its=100x50x25
percentage=0.35
#shrinkfactor=18x12x6
#shrinkfactor=4x2x1
sigma=1x0.5x0.5vox  # in voxels
verbose=0
bins=64

if [ -f "$prefix".nii ];then
    echo "The following file exists. I will not overwrite."
    echo "$prefix".nii
    echo "If you want to rerun, please delete/move this file first. Exiting."
    exit 1
fi   
if [ -f "$prefix".nii.gz ];then
    echo "The following file exists. I will not overwrite."
    echo "$prefix".nii.gz
    echo "If you want to rerun, please delete/move this file first. Exiting."
    exit 1
fi  
if [ "$isrigid" == "yes" ];then
    echo "antsRegistration -d $dim -r [ $f, $m ,1]  -m MI[  $f, $m , 1 , $bins, regular, $percentage ] -t translation[ 0.1 ] -c [ $its, 1.e-8, 20 ] -s ${sigma}  -f ${shrinkfactor} -l 1 -m MI[  $f, $m , 1 , $bins, regular, $percentage ] -t rigid[ 0.1 ] -c [ $its, 1.e-8, 20 ]  -s ${sigma}  -f ${shrinkfactor} -o [ ${prefix} ] -v ${verbose} --float"
    antsRegistration -d $dim -r [ $f, $m ,1]  -m MI[  $f, $m , 1 , $bins, regular, $percentage ] -t translation[ 0.1 ] -c [ $its, 1.e-8, 20 ] -s ${sigma}  -f ${shrinkfactor} -l 1 -m MI[  $f, $m , 1 , $bins, regular, $percentage ] -t rigid[ 0.1 ] -c [ $its, 1.e-8, 20 ]  -s ${sigma}  -f ${shrinkfactor} -o [ ${prefix} ] -v ${verbose} --float
    
else
    echo "antsRegistration -d $dim -r [ $f, $m ,1]  -m MI[  $f, $m , 1 , $bins, regular, $percentage ] -t translation[ 0.1 ] -c [ $its, 1.e-8, 20 ] -s ${sigma}  -f ${shrinkfactor} -l 1 -m MI[  $f, $m , 1 , $bins, regular, $percentage ] -t rigid[ 0.1 ] -c [ $its, 1.e-8, 20 ]  -s ${sigma}  -f ${shrinkfactor} -l 1 -m MI[  $f, $m , 1 , $bins, regular, $percentage ] -t affine[ 0.1 ] -c [ $its, 1.e-8, 20 ]  -s ${sigma}  -f ${shrinkfactor} -o [ ${prefix} ] -v ${verbose} --float"
    antsRegistration -d $dim -r [ $f, $m ,1]  -m MI[  $f, $m , 1 , $bins, regular, $percentage ] -t translation[ 0.1 ] -c [ $its, 1.e-8, 20 ] -s ${sigma}  -f ${shrinkfactor} -l 1 -m MI[  $f, $m , 1 , $bins, regular, $percentage ] -t rigid[ 0.1 ] -c [ $its, 1.e-8, 20 ]  -s ${sigma}  -f ${shrinkfactor} -l 1 -m MI[  $f, $m , 1 , $bins, regular, $percentage ] -t affine[ 0.1 ] -c [ $its, 1.e-8, 20 ]  -s ${sigma}  -f ${shrinkfactor} -o [ ${prefix} ] -v ${verbose} --float
    
fi    

#echo antsApplyTransforms -d $dim -i $m -r $f -o ${output} -n BSpline -t "$prefix"0GenericAffine.mat -f 0 -v ${verbose} --float
#antsApplyTransforms -d $dim -i $m -r $f -o ${output} -n BSpline -t "$prefix"0GenericAffine.mat -f 0 -v ${verbose} --float
echo antsApplyTransforms -d $dim -i $m -r $f -o ${output} -n Linear -t "$prefix"0GenericAffine.mat -f 0 -v ${verbose} --float
antsApplyTransforms -d $dim -i $m -r $f -o ${output} -n Linear -t "$prefix"0GenericAffine.mat -f 0 -v ${verbose} --float

# No need for fslmaths since Linear interpolation does not introduce negative values
#L=${#output}
#ext=${output:L-4:4}
#if [ "$ext" != ".tif" ];then
#    echo fslmaths ${prefix}.nii -thr 0 ${prefix}.nii -odt float
#    fslmaths ${prefix}.nii -thr 0 ${prefix}.nii -odt float
#fi

END=$(date +%s)
DIFF=$(( $END - $START ))
((sec=DIFF%60, DIFF/=60, min=DIFF%60, hrs=DIFF/60))
if [ "$isrigid" == "yes" ];then
    echo "ANTS rigid registration took $hrs HRS $min MIN $sec SEC"
else    
    echo "ANTS affine registration took $hrs HRS $min MIN $sec SEC"
fi    

