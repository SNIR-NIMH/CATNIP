#!/bin/bash

INSTALL_PREFIX=$0
INSTALL_PREFIX=`readlink -f $INSTALL_PREFIX`
INSTALL_PREFIX=`dirname $INSTALL_PREFIX`


if [ $# -lt "6" ];then
    echo "Usage:
    ./quick_QA_downsample_and_register.sh  INPUTDIR  OUTPUTDIR  DSFACTOR  isOB  NOISE_PARAM  ATLASVERSION  NUMCPU
    
    INPUTDIR        Input directory containing correctly oriented images. They will 
                    not be reoriented further.
    OUTPUTDIR       Output directory where affine registered image will be written.
                    Any existing image will be written over.
    DSFACTOR        Downsample factor, e.g. 6x6x5.
    isOB            Either yes or no.
    NOISE_PARAM     Noise parameter in percentile,stepsize format, used in CATNIP.
    ATLASVERSION    Atlas version (e.g. v2 or v3) used in CATNIP script
    NUMCPU          (Optional) Number of CPUs to use for registration. Default 12.
    "
    exit 1
fi

INPUTDIR=$1
OUTPUTDIR=$2
DSFACTOR=$3
OBFLAG=$4
NOISE=$5
ATLASVERSION=$6
NUMCPU=$7
if [ x"$NUMCPU" == "x" ];then
    NUMCPU=12
fi
    
ID=`basename $INPUTDIR`
mkdir -p $OUTPUTDIR
a=`echo $NOISE |cut -d ',' -f1`
b=`echo $NOISE |cut -d ',' -f2`


if [ "$ATLASVERSION" == "v1" ];then
    if [ "$OBFLAG" == "yes" ];then    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/uClear_Template_withOB_RHplus49_N4.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/annotation_atlasImage.Iteration.002_-x-z_renormalized_withOB.nii.gz
    else    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/uClear_Template_withoutOB_RHplus49_N4.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/annotation_atlasImage.Iteration.002_-x-z_renormalized_withoutOB_v2.nii.gz
    fi
elif [ "$ATLASVERSION" == "v2" ];then  # v2 atlas from Clearmap2, downloaded from  https://github.com/ChristophKirst/ClearMap2
    if [ "$OBFLAG" == "yes" ];then    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_reference_hemisphere_N4.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_annotation_hemisphere_nooutlier.nii.gz
    else    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_reference_hemisphere_N4_withoutOB.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_annotation_hemisphere_nooutlier_withoutOB.nii.gz
    fi

elif [ "$ATLASVERSION" == "v3" ];then  # v3 atlas is the Cerebellum free version of the v2 atlas
    if [ "$OBFLAG" == "yes" ];then    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_reference_hemisphere_N4_noCB.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_annotation_hemisphere_nooutlier_noCB.nii.gz
    else    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_reference_hemisphere_N4_withoutOB_noCB.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_annotation_hemisphere_nooutlier_withoutOB_noCB.nii.gz
    fi
    
elif [ "$ATLASVERSION" == "v4" ];then  # v4 atlas is the wholebrain version of axial images 
    if [ "$OBFLAG" == "yes" ];then    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_reference_axial.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_annotation_axial_nooutlier.nii.gz
    else    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_reference_axial_noOB.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_annotation_axial_nooutlier_noOB.nii.gz
    fi
    WHOLEBRAIN=true
    
elif [ "$ATLASVERSION" == "v5" ];then  # v5 atlas is the wholebrain version of axial images but with modified LUT
    if [ "$OBFLAG" == "yes" ];then    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_reference_axial.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_annotation_axial.nii.gz
    else    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_reference_axial_noOB.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_annotation_axial_noOB.nii.gz
    fi
    WHOLEBRAIN=true
elif [ "$ATLASVERSION" == "v6" ];then  # v5 atlas but no cerebellum or brainstem
    if [ "$OBFLAG" == "yes" ];then    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_reference_axial_noCB.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_annotation_axial_noCB.nii.gz
    else    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_reference_axial_noOB_noCB.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_annotation_axial_noOB_noCB.nii.gz
    fi
    WHOLEBRAIN=true
elif [ "$ATLASVERSION" == "v7" ];then  # v7 atlas is the wholebrain version of coronal images but with modified LUT (v5 --> coronal)
    if [ "$OBFLAG" == "yes" ];then    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_reference_axial.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_annotation_axial.nii.gz
    else    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_reference_axial_noOB.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_annotation_axial_noOB.nii.gz
    fi
    WHOLEBRAIN=true
fi
ATLASHEMIMASK=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/uClear_Template_hemispheremask.nii.gz



IMG=$OUTPUTDIR/${ID}_downsampled_${DSFACTOR}.nii
IMG2=$OUTPUTDIR/${ID}_downsampled_${DSFACTOR}_denoised.nii
${INSTALL_PREFIX}/Downsample3D.sh $INPUTDIR $IMG $DSFACTOR $ATLASIMAGE

${INSTALL_PREFIX}/fix_header.sh $IMG $IMG 25x25x25
${INSTALL_PREFIX}/remove_background_noise.sh $IMG $a $IMG2 $b
${INSTALL_PREFIX}/image_clamp.sh $IMG2 $IMG2 99 true

REG=$OUTPUTDIR/${ID}_atlasimage_affine_${DSFACTOR}.nii
if [ -f "$REG" ];then
    echo "WARNING: Affine registration ($REG) exists. I will delete it now."    
    rm -vf $REG
fi
echo ${INSTALL_PREFIX}/antsaffine.sh $IMG2 $ATLASIMAGE  $REG no $NUMCPU 4x2x1
${INSTALL_PREFIX}/antsaffine.sh $IMG2 $ATLASIMAGE  $REG no $NUMCPU  4x2x1
antsApplyTransforms -d 3 -i $ATLASHEMIMASK -r $IMG2 -o $OUTPUTDIR/${ID}_hemispheremask_${DSFACTOR}.nii -n NearestNeighbor --float -f 0 -v 1  -t $OUTPUTDIR/${ID}_atlasimage_affine_${DSFACTOR}0GenericAffine.mat   
antsApplyTransforms -d 3 -i $ATLASLABEL -r $IMG2 -o $OUTPUTDIR/${ID}_atlaslabel_affine_${DSFACTOR}.nii -n NearestNeighbor --float -f 0 -v 1  -t $OUTPUTDIR/${ID}_atlasimage_affine_${DSFACTOR}0GenericAffine.mat  
