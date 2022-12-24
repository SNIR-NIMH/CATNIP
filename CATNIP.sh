#!/bin/bash
check_modules () {  # check if ANTs binaries are correctly added to $PATH
    FUNC=$1    
    if ! [ -x "$(command -v "$FUNC")" ]; then
        echo "
    Error: $FUNC is not installed. Please add $FUNC to PATH.
        "
        exit 1
    fi

}
binarize () {  # binarize image, alternate for fslmaths
    IN=$1    
    OUT=$2
    ImageMath 3 $OUT ReplaceVoxelValue $IN 0.0001 65535 1
    ConvertImage 3 $OUT $OUT 1
    ConvertImage 3 $OUT $OUT 0
}
invert_binary_mask (){  # invert a binary mask
    IN=$1  # Input must be binary image
    OUT=$2
    ImageMath 3 $OUT ReplaceVoxelValue $IN 0 0 2
    ImageMath 3 $OUT ReplaceVoxelValue $OUT 1 1 0
    ImageMath 3 $OUT ReplaceVoxelValue $OUT 2 2 1
    
}

get_extension (){
    NAME=$1    
    EXT=`echo $NAME | tr "."  "\n" |tail -1`  # trim by dot, get the last one, but does not work for tar.gz, which
    # gives only .gz. But this should be fine for practical purpose
    echo $EXT
    
}

INSTALL_PREFIX=$0
INSTALL_PREFIX=`readlink -f $INSTALL_PREFIX`
INSTALL_PREFIX=`dirname $INSTALL_PREFIX`

                      
showHelp() {
cat << EOF  

Usage:

./CATNIP.sh  --c640 CHANNEL640   --o OUTPUTDIR  --ob OB_FLAG  --udflip UPDOWN_FLIP_FLAG  \\
        --lrflip LR_FLIP_FLAG  --thr THRESHOLD  --dsfactor DSFACTOR  --cellradii RADII \\        
        --ncpu NUMCPU  --exclude_mask EXCLUSION_MASK_IMAGE  --bg_noise_param BG_NOISE_PARAM \\
        --atlasversion v1  --mask_ovl_ratio  MASK_OVL_RATIO
    
    Required arguments:
    
    CHANNEL640      : (Required) A folder containing channel 640 tif images
    
    OUTPUTDIR       : (Required) Output directory where all results will be written. 
                                      
    OB_FLAG         : (Required) A flag (yes/no) if the image has olfactory bulb. 
                      If the image has OB, use yes (--ob yes)                      
                      
    XX_FLIP_FLAG    : (Required) A flag (yes/no) if the image is to be up-down or 
                      left-right flipped. If flipping is needed to reorient the 
                      channels to the correct atlas orientation, use yes, otherwise use no.
                      **Correct atlas orientation** is sagittal with cerebellum being at 
                      the bottom left side.   
                       
    DSFACTOR        : (Required) Downsampling factor for registration in HxWxD orientation. 
                      Default is 6x6x5. Use bigger downsampling factor (e.g. 9x9x7) 
                      for larger size images.
                      ** This is a crucial parameter for good registration. Choose
                      downsampling factor so that the downsampled image size is 
                      similar to 528x320x277 (HxWxD) and resolution is approximately
                      25x25x25um, i.e. the size and resolution of the ABA atlas.
                      After resampling, the atlas should approximately be
                      isotropic in resolution. This can be modified based on actual 
                      brain size.
                      
    RADII           : (Required) A range of cell radii in *pixels*, comma separated. 
                      For 3.77x3.77x5um images, the default is 2,3,4. Please estimate 
                      the range of cell radii from the image and enter as a comma
                      separated string.
                      
    Optional arguments:
        
                      
    NUMCPU          : (Optional) Number of parallel processing cores to be used.
                      This must be less/equal to the total available number of 
                      cpus. Usually 8 or 12 is fine. Maximum required memory is
                      also proportional to the number of processes. Default 8.
                      
    THRESHOLD       : (Optional) FRST segmentation thresholds. FRST output is a 
                      continuous valued image from 0-65000. Usually, a threshold 
                      of 7000 is very sensitive. For debugging purpose, it is 
                      recommeneded that a range of thresholds are used, so that 
                      segmentations for each of the thresholds are generated. 
                      Example, 10000:1000:15000 means 6 segmentation images will 
                      be generated at thresholds 10000,11000,..,15000.
                      If not mentioned, default is 45000:5000:60000.                                              
                      
    EXCLUSION_MASK  : (Optional) A binary mask indicating bad regions/artifacts in the image. 
                      ** 1) This must already be in the "atlas orientation", i.e. cerebellum 
                      in bottom left side. See XX_FLIP_FLAG argument for the definition
                      of the atlas orientation
                      ** 2) This must be in one of the following space, 
                      (a) Same dimension as the original image "after" proper orientation, 
                      i.e., this mask will "NOT" be reoriented based on the flip flags.
                      In this case, only use .tif or .tiff format.
                      (b) This mask can also be a NIFTI (.nii or .nii.gz) image 
                      if it is in the downsampled image space. It is recommended
                      to run the pipeline once with correct downsampling factor
                      to generate all outputs, then draw a binary mask on the
                      640_downsampled_AxBxC_brain.nii.gz image.
                      
    BG_NOISE_PARAM  : (Optional) Background noise removal parameter to generate a
                      brain mask to be used for registration target. It is a comma-separated
                      pair, e.g. 40,1.05. The first number (40) denotes a percentile
                      that is initialized as noise background noise threshold. Use
                      higher number (55) for images with heavy noise. The second
                      number indicates a slope (>1) with which the noise threshold is
                      successively increased. Default is 50,1.1. If the brain mask too 
                      conservative, use lower number (e.g., 40,1.05).
                      
    ATLASVERSION    : (Optional) Either v1 (corresponds to uClear atlas) or v2 
                      (corresponds to Clearmap2) atlas. Default is v1.
                      
    MASK_OVL_RATIO    (Optional) A mask overlap ratio between 0 and 1. It is used only
                      when an EXCLUSION_MASK is mentioned. A ratio of 0.5 means a label
                      is going to be ignored if its overlap volume with the mask is 
                      less than half of its total volume. So small overlap with the 
                      exclusion mask is ignored. Default is 0.25.
                      
    
    Example: 
    ./CATNIP.sh --c640 /home/user/input/640/ --o /home/user/output  \\
        --ob yes --udflip no --lrflip yes --cellradii 3,4,5,6 --thr 5000:5000:60000  \\
         --ncpu 12 --dsfactor 9x9x7  
    
    Required arguments:
    /home/user/input/640/ --> 2D tiff images of 640 channel    
    /home/user/output     --> Output will be written here
    yes                   --> Image has OB (--ob)
    no                    --> Image is not up-down flipped (--udflip)
    yes                   --> Image is left-right flipped, i.e. Cerebellum is bottom 
                              right side instead of bottom left side (--lrflip)
    9x9x7                 --> Dowsampling factor for registration   
    3,4,5,6               --> Cell radii is *pixels*  
      
    Optional arguments:
    
    12                    --> Number of cpu to use    
    5000:5000:60000      --> Segmentation images and stats will be generated at 
                              thresholds 5000,10000,..,55000,60000
        
    Please install ANTs (add the binary folder to \$PATH), and Matlab MCR v97.
    Then change the MCRROOT variables in the associated scripts.
EOF
}

if [ "$#" -lt "1" ];then
    showHelp
    exit 0
fi


check_modules antsRegistration
check_modules antsApplyTransforms
check_modules ConvertImage    
check_modules N4BiasFieldCorrection
check_modules ImageMath
check_modules ConvertImage


# -o is for short options like -v
# -l is for long options with double dash like --version
# the comma separates different long options
# -a is for long options with single dash like -version
options=$(getopt -l "c640:,ncpu:,o:,ob:,udflip:,lrflip:,thr:,ometiff:,dsfactor:,cellradii:,exclude_mask:,atlasversion:,bg_noise_param:,mask_ovl_ratio:,help" -o "h" -- "$@")

CHANNEL640=
OUTPUTDIR=
NUMCPU=
OBFLAG=
UDFLIPFLAG=
LRFLIPFLAG=
THRESHOLD=
OMETIFF=
EXCLUDE_MASK=
DSFACTOR=
CELLRADII=
BG_NOISE_PARAM=50,1.1
ATLASVERSION=v1
MASKOVLRATIO=0.25

# set --:
# If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters 
# are set to the arguments, even if some of them begin with a ‘-’.
eval set -- "$options"

while true
do
case $1 in
-h|--help) 
    showHelp
    exit 0
    ;;
--c640) 
    shift
    export CHANNEL640=$1
    ;;
--o) 
    shift
    export OUTPUTDIR=$1
    ;;
--ncpu) 
    shift
    export NUMCPU=$1
    ;;
--ob) 
    shift
    export OBFLAG=$1
    ;;
--lrflip) 
    shift
    export LRFLIPFLAG=$1
    ;;
--udflip) 
    shift
    export UDFLIPFLAG=$1
    ;;
--thr) 
    shift
    export THRESHOLD=$1
    ;;
--ometiff) 
    shift
    export OMETIFF=$1
    ;;
--dsfactor) 
    shift
    export DSFACTOR=$1
    ;;  
--cellradii) 
    shift
    export CELLRADII=$1
    ;; 
--exclude_mask) 
    shift
    export EXCLUDE_MASK=$1    
    ;; 
--bg_noise_param) 
    shift
    export BG_NOISE_PARAM=$1    
    ;;     
--atlasversion) 
    shift
    export ATLASVERSION=$1    
    ;;  
--mask_ovl_ratio) 
    shift
    export MASKOVLRATIO=$1    
    ;; 
--)
    shift
    break;;
esac
shift
done


FSLOUTPUTTYPE=NIFTI

# ========================= Set up paths and check for errors =========================


OUTPUTDIR=`readlink -f $OUTPUTDIR`
if [ x"${OMETIFF}" == "x" ];then
    OMETIFF=${CHANNEL640} # Legacy from previous pipeline, it is not needed any more
fi

if [ x"${CHANNEL640}" == "x" ];then
    echo "ERROR: Channel 640 is required with --c640 argument. Exiting."
    exit 1
fi
if [ x"${OUTPUTDIR}" == "x" ];then
    echo "ERROR: Output directory is required with --o argument. Exiting."
    exit 1
fi
if [ x"${DSFACTOR}" == "x" ];then    
    echo "ERROR: Downsampling factor is required with --dsfactor argument. Exiting."
    exit 1
fi

if [ x"${CELLRADII}" == "x" ];then    
    echo "ERROR: Cell radius (in comma separated format) is required with --cellradii argument. Exiting."
    exit 1
fi

if [ x"${NUMCPU}" == "x" ];then
    echo "WARNING: Number of parallel processing cores is not mentioned with --ncpu argument. "
    echo "WARNING: Using 12 cores by default."
    NUMCPU=12
fi

if [ x"${OBFLAG}" == "x" ];then
    echo "ERROR: OB flag (either yes or no) is required with --ob argument. Exiting."
    exit 1
else
    if [ "${OBFLAG}" != "yes" ] && [ "${OBFLAG}" != "no" ];then
        echo "ERROR: OB flag (--ob XX) must be either yes or no. You entered $OBFLAG"
        exit 1
    fi
fi

if [ x"${LRFLIPFLAG}" == "x" ];then
    echo "ERROR: Left-right flip flag (either yes or no) is required with --lrflip argument. Exiting."
    exit 1
else
    if [ "${LRFLIPFLAG}" != "yes" ] && [ "${LRFLIPFLAG}" != "no" ];then
        echo "ERROR: Left-right flip flag (--lrflip XX) must be either yes or no. You entered $LRFLIPFLAG"
        exit 1
    fi
fi

if [ x"${UDFLIPFLAG}" == "x" ];then
    echo "ERROR: Up-down flip flag (either yes or no) is required with --udflip argument. Exiting."
    exit 1
else
    if [ "${UDFLIPFLAG}" != "yes" ] && [ "${UDFLIPFLAG}" != "no" ];then
        echo "ERROR: Up-down flip flag (--udflip XX) must be either yes or no. You entered $UDFLIPFLAG"
        exit 1
    fi
fi

if [ x"${THRESHOLD}" == "x" ];then    
    echo "WARNING: FRST thresholds are not mentioned with --thr argument. "
    echo "WARNING: Using default 5000:5000:60000."
    THRESHOLD="5000:5000:60000"    
fi

if  [ "${ATLASVERSION}" != "v1" ] && [ "${ATLASVERSION}" != "v2" ];then
    echo "ERROR: ATLASVERSION flag (--atlasversion XX) must be either v1 or v2. You entered $ATLASVERSION"
    exit 1            
fi



if [ x"${EXCLUDE_MASK}" != "x" ];then
     echo "======================================================================================================="
     echo "WARNING: You have chosen a binary exclusion mask to account for bad regions/artifacts."
     echo "WARNING: Is this mask already in the \"atlas orientation\" (sagittal, cerebellum bottom left corner)?"
     echo "WARNING: If not, please exit this script and reorient the mask to the correct atlas orientation first. "
     echo "======================================================================================================="
     EXCLUDE_MASK=`readlink -f ${EXCLUDE_MASK}`
     ext=`basename ${EXCLUDE_MASK}`
     ext=`get_extension ${ext}`     
     if [ "${ext}" == "tif" ] || [ "${ext}" == "tiff" ];then
        echo "WARNING: You are using a tif image, so I assume the image is in correct \"atlas orientation\" but in the \"ORIGINAL\" image space"
        IMGSPACE=original
    elif [ "${ext}" == "nii" ] || [ "${ext}" == "gz" ];then  # nifti nii or nii.gz
        echo "WARNING: You are using a NIFTI image, so I assume the image is in correct \"atlas orientation\" but in the \"DOWNSAMPLED\" image space"
        IMGSPACE=atlas
    else
        echo "ERROR: I do not recognize this image.  The exclusion mask must be one of the two following formats,
        1) A TIF (.tif or .tiff) image in correct \"atlas orientation\" but in the \"ORIGINAL\" image space
        2) A NIFTI (.nii or .nii.gz) format image in correct \"atlas orientation\" but in the \"ORIGINAL\" image space
        "
        exit 1
    fi
fi


    

#=============================================================================

RAND=`echo $RANDOM`
RAND=$((RAND % 30)) # This is to disable race conditions for multiple Matlab compiler calls.
                    # This is specifically useful for HPC clusters while running lots of 
                    # instances of this code simultaneously.
sleep $RAND
ID=`basename $CHANNEL640`
ID="$ID"_`date '+%Y-%m-%d_%H-%M-%S'`
echo "Unique ID is $ID"
OUTPUTDIR=$OUTPUTDIR/$ID/
if [ -d "$OUTPUTDIR" ];then
    echo "ERROR: Output directory already exists. I WILL NOT OVERWRITE into the existing directory.
    It is advised that you choose a new ID or a new output directory
    "
    exit 1
else
    mkdir -p $OUTPUTDIR
fi
LOG=$OUTPUTDIR/${ID}.log.txt
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$NUMCPU


if [ "$ATLASVERSION" == "v1" ];then
    if [ "$OBFLAG" == "yes" ];then    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_v1/uClear_Template_withOB_RHplus49_N4.nii.gz  
        ATLASLABEL=${INSTALL_PREFIX}/atlas_v1/annotation_atlasImage.Iteration.002_-x-z_renormalized_withOB.nii.gz
    else    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_v1/uClear_Template_withoutOB_RHplus49_N4.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_v1/annotation_atlasImage.Iteration.002_-x-z_renormalized_withoutOB_v2.nii.gz
    fi
elif [ "$ATLASVERSION" == "v2" ];then  # v2 atlas from Clearmap2, downloaded from  https://github.com/ChristophKirst/ClearMap2
    if [ "$OBFLAG" == "yes" ];then    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_v2/ABA_25um_reference_hemisphere_N4.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_v2/ABA_25um_annotation_hemisphere_nooutlier.nii.gz
    else    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_v2/ABA_25um_reference_hemisphere_N4_withoutOB.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_v2/ABA_25um_annotation_hemisphere_nooutlier_withoutOB.nii.gz
    fi

fi
ATLASHEMIMASK=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/uClear_Template_hemispheremask.nii.gz
    



    
BG_NOISE_INIT=`echo ${BG_NOISE_PARAM} |cut -d ',' -f1`
BG_NOISE_SLOPE=`echo ${BG_NOISE_PARAM} |cut -d ',' -f2`

START=$(date +%s)
echo "========================= Image Info ===============================" 2>&1 | tee -a $LOG
echo "640 Channel                   : $CHANNEL640"      2>&1 | tee -a  $LOG
echo "Downsampling factor           : $DSFACTOR"        2>&1 | tee -a  $LOG
echo "Number of cpus                : $NUMCPU"          2>&1 | tee -a  $LOG
echo "Output directory              : $OUTPUTDIR"       2>&1 | tee -a  $LOG
echo "Does the image have OB?       : $OBFLAG"          2>&1 | tee -a  $LOG
echo "Is the image l-r flipped?     : $LRFLIPFLAG"      2>&1 | tee -a  $LOG
echo "Is the image u-d flipped?     : $UDFLIPFLAG"      2>&1 | tee -a  $LOG
echo "Log file                      : $LOG"             2>&1 | tee -a  $LOG
echo "Atlas image                   : $ATLASIMAGE"      2>&1 | tee -a  $LOG
echo "Atlas label                   : $ATLASLABEL"      2>&1 | tee -a  $LOG
echo "FRST threshold                : ${THRESHOLD} "    2>&1 | tee -a  $LOG
echo "Atlas version                 : ${ATLASVERSION}"  2>&1 | tee -a  $LOG
echo "Background noise init/slope   : ${BG_NOISE_INIT},${BG_NOISE_SLOPE}" 2>&1 | tee -a  $LOG
if [ x"${EXCLUDE_MASK}" != "x" ];then
    echo "Exclusion mask                : ${EXCLUDE_MASK}"  2>&1 | tee -a  $LOG
fi
echo "Cell radii (in pixels)        : $CELLRADII  "     2>&1 | tee -a  $LOG
echo "Mask overlap ratio            : $MASKOVLRATIO  "     2>&1 | tee -a  $LOG

H=`${INSTALL_PREFIX}/image_info.sh $CHANNEL640 H`
W=`${INSTALL_PREFIX}/image_info.sh $CHANNEL640 W`
D=`${INSTALL_PREFIX}/image_info.sh $CHANNEL640 D`

echo "Image size                    : ${H}x${W}x${D} (HxWxD)"   2>&1 | tee -a  $LOG
CHANNEL640ORIG=${CHANNEL640}


# ======================== Run actual scripts ==================================



if [ "$UDFLIPFLAG" == "yes" ] || [ "$LRFLIPFLAG" == "yes" ];then
    echo "======================== Flipping Images ===========================" 2>&1 | tee -a $LOG 
    mkdir -p $OUTPUTDIR/640_flipped/    
    ${INSTALL_PREFIX}/FlipImages.sh $CHANNEL640 $OUTPUTDIR/640_flipped/ $UDFLIPFLAG $LRFLIPFLAG no $NUMCPU  2>&1 | tee -a $LOG
    CHANNEL640=$OUTPUTDIR/640_flipped/
    echo "====================================================================" 2>&1 | tee -a $LOG 
    
fi

echo "================ Downsample 640 channel for N4 correction =================" 2>&1 | tee -a $LOG 

# Downsample by DSFACTOR
${INSTALL_PREFIX}/Downsample3D.sh ${CHANNEL640} $OUTPUTDIR/640_downsampled_${DSFACTOR}.nii $DSFACTOR $ATLASIMAGE ${OMETIFF} 2>&1 | tee -a  $LOG
${INSTALL_PREFIX}/fix_header.sh $OUTPUTDIR/640_downsampled_${DSFACTOR}.nii  $OUTPUTDIR/640_downsampled_${DSFACTOR}.nii  25x25x25  | tee -a  $LOG # Fix header, for the time being, hardcoded
${INSTALL_PREFIX}/remove_background_noise.sh  $OUTPUTDIR/640_downsampled_${DSFACTOR}.nii ${BG_NOISE_INIT} $OUTPUTDIR/640_downsampled_${DSFACTOR}.nii ${BG_NOISE_SLOPE}  2>&1 | tee  -a $LOG
echo "================= Running N4 bias field correction  ====================" 2>&1 | tee -a $LOG 
# Run N4 in downsampled space for speed
binarize $OUTPUTDIR/640_downsampled_${DSFACTOR}.nii ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_brainmask.nii 
echo "N4BiasFieldCorrection -d 3 -s 4 -i $OUTPUTDIR/640_downsampled_${DSFACTOR}.nii -o [ ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_N4.nii,${OUTPUTDIR}/640_downsampled_${DSFACTOR}_N4Field.nii ] -c [ 50x50x50x50,0.0001] -r 1 -v 1 -x  ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_brainmask.nii " 2>&1 | tee -a  $LOG
N4BiasFieldCorrection -d 3 -s 4 -i $OUTPUTDIR/640_downsampled_${DSFACTOR}.nii -o [ ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_N4.nii,${OUTPUTDIR}/640_downsampled_${DSFACTOR}_N4Field.nii ] -c [ 50x50x50x50,0.0001] -r 1 -v 1  -x  ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_brainmask.nii 2>&1 | tee -a  $LOG
echo ImageMath 3 ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_N4Field.nii m  ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_N4Field.nii   ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_brainmask.nii  2>&1 | tee -a  $LOG
ImageMath 3 ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_N4Field.nii m  ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_N4Field.nii   ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_brainmask.nii
echo "====================================================================" 2>&1 | tee -a $LOG 
# Upsample the N4 field
${INSTALL_PREFIX}/nii2tiff.sh  ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_N4Field.nii ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_N4Field.tif  float32 yes 2>&1 | tee -a  $LOG
echo "============= Upsampling bias field to original image space =============" 2>&1 | tee -a $LOG 
${INSTALL_PREFIX}/upsample_image.sh ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_N4Field.tif ${OUTPUTDIR}/640_N4Field/  ${H}x${W}x${D}  nearest false true float32  2>&1 | tee -a $LOG 
echo "=============== Multiplying bias field with original image =============" 2>&1 | tee -a $LOG 
# Multiply the N4 field with the original image, this will be used for registration and segmentation
${INSTALL_PREFIX}/N4Process.sh ${CHANNEL640} ${OUTPUTDIR}/640_N4Field/  $OUTPUTDIR/640_N4/ 2>&1 | tee -a $LOG 
#rm -f ${OUTPUTDIR}/initmask.nii
export CHANNEL640=${OUTPUTDIR}/640_N4/   


echo "================ Downsample bias corrected 640 image =================" 2>&1 | tee -a $LOG 
# Downsample to approximately 25um resolution, for debugging purpose
${INSTALL_PREFIX}/Downsample3D.sh ${CHANNEL640} $OUTPUTDIR/640_downsampled_${DSFACTOR}.nii ${DSFACTOR} $ATLASIMAGE ${OMETIFF} 2>&1 | tee -a  $LOG
echo "====================================================================" 2>&1 | tee -a $LOG 
${INSTALL_PREFIX}/fix_header.sh $OUTPUTDIR/640_downsampled_${DSFACTOR}.nii  $OUTPUTDIR/640_downsampled_${DSFACTOR}.nii  25x25x25  2>&1 | tee -a  $LOG # Fix header, for the time being, hardcoded
#echo "=============== Removing background noise for better registration =============" 2>&1 | tee -a $LOG 
# Remove background noise for better registration
#${INSTALL_PREFIX}/remove_background_noise.sh  $OUTPUTDIR/640_downsampled_${DSFACTOR}.nii ${BG_NOISE_INIT} $OUTPUTDIR/640_downsampled_${DSFACTOR}_brain.nii ${BG_NOISE_SLOPE}  2>&1 | tee  -a $LOG
# Approximate registration by ANTs
echo "================ Atlas registration with ANTs =================" 2>&1 | tee -a $LOG 
${INSTALL_PREFIX}/image_clamp.sh $OUTPUTDIR/640_downsampled_${DSFACTOR}.nii  $OUTPUTDIR/640_downsampled_${DSFACTOR}_brain.nii 99 true 2>&1 | tee -a  $LOG
echo ${INSTALL_PREFIX}/AntsExample.sh  $OUTPUTDIR/640_downsampled_${DSFACTOR}_brain.nii $ATLASIMAGE fast $OUTPUTDIR/atlasimage_reg.nii $NUMCPU   4x2x1  2>&1 | tee  -a $LOG
${INSTALL_PREFIX}/AntsExample.sh  $OUTPUTDIR/640_downsampled_${DSFACTOR}_brain.nii $ATLASIMAGE fast $OUTPUTDIR/atlasimage_reg.nii $NUMCPU   4x2x1  2>&1 | tee  -a $LOG

echo "================== Transforming labels =========================" 2>&1 | tee -a $LOG 
# Apply the transform to the label
echo antsApplyTransforms -d 3 -i $ATLASLABEL -r $OUTPUTDIR/640_downsampled_${DSFACTOR}.nii -o $OUTPUTDIR/atlaslabel_def.nii -n NearestNeighbor --float -f 0 -v 1 -t $OUTPUTDIR/atlasimage_reg1Warp.nii.gz -t $OUTPUTDIR/atlasimage_reg0GenericAffine.mat   2>&1 | tee -a  $LOG
antsApplyTransforms -d 3 -i $ATLASLABEL -r $OUTPUTDIR/640_downsampled_${DSFACTOR}.nii -o $OUTPUTDIR/atlaslabel_def.nii -n NearestNeighbor --float -f 0 -v 1 -t $OUTPUTDIR/atlasimage_reg1Warp.nii.gz -t $OUTPUTDIR/atlasimage_reg0GenericAffine.mat   2>&1 | tee -a  $LOG
echo "====================================================================" 2>&1 | tee -a $LOG 

echo ConvertImage 3 $OUTPUTDIR/atlaslabel_def.nii $OUTPUTDIR/atlaslabel_def.nii 2  2>&1 | tee -a  $LOG
ConvertImage 3 $OUTPUTDIR/atlaslabel_def.nii $OUTPUTDIR/atlaslabel_def.nii 2  2>&1 | tee -a  $LOG



echo "====================================================================" 2>&1 | tee -a $LOG 
# Resample the label to the original space
${INSTALL_PREFIX}/nii2tiff.sh $OUTPUTDIR/atlaslabel_def.nii $OUTPUTDIR/atlaslabel_def.tif uint16 yes 2>&1 | tee  -a $LOG 
echo "================= Upsampling label to original image space =============" 2>&1 | tee -a $LOG 
${INSTALL_PREFIX}/upsample_image.sh $OUTPUTDIR/atlaslabel_def.tif $OUTPUTDIR/atlaslabel_def_origspace/ ${H}x${W}x${D} nearest false true uint16 2>&1 | tee  -a $LOG 



echo "=============== Computing midline by transforming atlas hemisphere mask ===========" 2>&1 | tee -a $LOG
echo "antsApplyTransforms -d 3 -i $ATLASHEMIMASK -r $OUTPUTDIR/640_downsampled_${DSFACTOR}.nii -o $OUTPUTDIR/hemispheremask_${DSFACTOR}.nii -n NearestNeighbor --float -f 0 -v 1 -t $OUTPUTDIR/atlasimage_reg1Warp.nii.gz -t $OUTPUTDIR/atlasimage_reg0GenericAffine.mat" 2>&1 | tee -a  $LOG
antsApplyTransforms -d 3 -i $ATLASHEMIMASK -r $OUTPUTDIR/640_downsampled_${DSFACTOR}.nii -o $OUTPUTDIR/hemispheremask_${DSFACTOR}.nii -n NearestNeighbor --float -f 0 -v 1 -t $OUTPUTDIR/atlasimage_reg1Warp.nii.gz -t $OUTPUTDIR/atlasimage_reg0GenericAffine.mat   2>&1 | tee -a  $LOG

#echo "fslmaths ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii -mas ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_brainmask.nii ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii -odt char" 2>&1 | tee -a  $LOG
#fslmaths ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii -mas ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_brainmask.nii ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii -odt char
echo ImageMath 3 ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii m ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_brainmask.nii  ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii 2>&1 | tee -a  $LOG
ImageMath 3 ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii m ${OUTPUTDIR}/640_downsampled_${DSFACTOR}_brainmask.nii  ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii
# Mask the atlaslabel_def image for Generate_Stats code
echo ImageMath 3 ${OUTPUTDIR}/atlaslabel_def_brain.nii m ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii  ${OUTPUTDIR}/atlaslabel_def.nii  2>&1 | tee -a  $LOG
ImageMath 3 ${OUTPUTDIR}/atlaslabel_def_brain.nii m ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii  ${OUTPUTDIR}/atlaslabel_def.nii 

echo "====================================================================" 2>&1 | tee -a $LOG 
${INSTALL_PREFIX}/nii2tiff.sh $OUTPUTDIR/hemispheremask_${DSFACTOR}.nii $OUTPUTDIR/hemispheremask_${DSFACTOR}.tif uint16 yes 2>&1 | tee -a  $LOG
echo "============= Upsampling hemisphere mask to original image space ================" 2>&1 | tee -a $LOG 
${INSTALL_PREFIX}/upsample_image.sh  $OUTPUTDIR/hemispheremask_${DSFACTOR}.tif  $OUTPUTDIR/hemispheremask_origspace/ ${H}x${W}x${D} nearest false true uint16 2>&1 | tee  -a $LOG 
echo "============== Masking image by hemisphere mask =================" 2>&1 | tee -a $LOG 
${INSTALL_PREFIX}/image_math.sh ${CHANNEL640} $OUTPUTDIR/hemispheremask_origspace/  $OUTPUTDIR/640_N4_masked/   multiply  $NUMCPU 2>&1 | tee -a $LOG 
echo "=============== Masking label by hemisphere mask ====================" 2>&1 | tee -a $LOG 
${INSTALL_PREFIX}/image_math.sh $OUTPUTDIR/atlaslabel_def_origspace/  $OUTPUTDIR/hemispheremask_origspace/ $OUTPUTDIR/atlaslabel_def_origspace_masked/   multiply  $NUMCPU 2>&1 | tee -a $LOG 
CHANNEL640=${OUTPUTDIR}/640_N4_masked/
echo "====================================================================" 2>&1 | tee -a $LOG 


echo "========================= Running FRST =============================" 2>&1 | tee -a $LOG 
mkdir -p $OUTPUTDIR/640_FRST/
mkdir -p $OUTPUTDIR/640_FRST_seg/
echo ${INSTALL_PREFIX}/ApplyFRST.sh ${CHANNEL640} $OUTPUTDIR/640_FRST/ $NUMCPU  $CELLRADII $OUTPUTDIR/640_downsampled_${DSFACTOR}_brain.nii 2>&1 | tee  -a $LOG
${INSTALL_PREFIX}/ApplyFRST.sh ${CHANNEL640} $OUTPUTDIR/640_FRST/ $NUMCPU  $CELLRADII $OUTPUTDIR/640_downsampled_${DSFACTOR}_brain.nii 2>&1 | tee -a  $LOG
echo "=================== Computing FRST segmentation ======================" 2>&1 | tee -a $LOG 
echo "Creating FRST segmentation by thresholding"  2>&1 | tee -a $LOG 
${INSTALL_PREFIX}/ApplyFRSTseg.sh $OUTPUTDIR/640_FRST/ $OUTPUTDIR/640_FRST_seg/ "${THRESHOLD}"   2>&1 | tee -a  $LOG


echo "============== Generating stats on the cell counts =================" 2>&1 | tee -a $LOG 
${INSTALL_PREFIX}/Generate_Stats.sh $OUTPUTDIR/640_FRST_seg/ ${INSTALL_PREFIX}/atlas_${ATLASVERSION}/atlas_info.txt  $OUTPUTDIR/atlaslabel_def_origspace_masked/ $OUTPUTDIR/640_FRST_seg/FRSTseg*/  2>&1 | tee -a  $LOG


# Generating cell heatmaps in atlas space
echo "========= Generating cell segmentation heatmaps in atlas space =======" 2>&1 | tee -a $LOG 
mkdir ${OUTPUTDIR}/heatmaps_atlasspace/

${INSTALL_PREFIX}/create_heatmap.sh ${CHANNEL640} ${DSFACTOR} ${OUTPUTDIR}/heatmaps_atlasspace/  ${OUTPUTDIR}/640_downsampled_${DSFACTOR}.nii ${OUTPUTDIR}/640_FRST_seg/FRSTseg_*/  2>&1 | tee -a  $LOG

for file in `ls $OUTPUTDIR/heatmaps_atlasspace/*.nii.gz`
do 
    M=`basename $file`
    M=`remove_ext $M`
    X=${OUTPUTDIR}/heatmaps_atlasspace/${M}_atlasspace.nii    
    
    echo antsApplyTransforms -d 3 -i $file -r  ${ATLASIMAGE} -o $X -n Linear -f 0 -v 1 -t [ ${OUTPUTDIR}/atlasimage_reg1InverseWarp.nii.gz ] -t [ ${OUTPUTDIR}/atlasimage_reg0GenericAffine.mat,1 ] --float 2>&1 | tee -a  $LOG
    antsApplyTransforms -d 3 -i $file -r  ${ATLASIMAGE} -o $X -n Linear -f 0 -v 1 -t [ ${OUTPUTDIR}/atlasimage_reg1InverseWarp.nii.gz ] -t [ ${OUTPUTDIR}/atlasimage_reg0GenericAffine.mat,1 ] --float 2>&1 | tee -a  $LOG
    Y=${OUTPUTDIR}/heatmaps_atlasspace/${M}_atlasspace.tif
    ${INSTALL_PREFIX}/nii2tiff.sh ${X} ${Y} float32 yes 2>&1 | tee -a  $LOG
    gzip -vf  ${X} 2>&1 | tee -a  $LOG
done
echo "====================================================================" 2>&1 | tee -a $LOG 

${INSTALL_PREFIX}/nii2tiff.sh ${OUTPUTDIR}/640_downsampled_${DSFACTOR}.nii ${OUTPUTDIR}/640_downsampled_${DSFACTOR}.tif uint16 yes 2>&1 | tee -a  $LOG

gzip -vf  ${OUTPUTDIR}/*.nii



# If mask exists, redo the csvs with the mask.
if [ x"${EXCLUDE_MASK}" != "x" ];then
    echo "=============== Correcting CSV files and heatmaps with the exclusion mask ==============" 2>&1 | tee -a $LOG 
    mkdir -p ${OUTPUTDIR}/640_FRST_seg_corrected/
    #${INSTALL_PREFIX}/Downsample3D.sh ${EXCLUDE_MASK} ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii ${DSFACTOR} $ATLASIMAGE ${OMETIFF} 2>&1 | tee -a  $LOG
    if [ "${IMGSPACE}" == "original" ];then
        ${INSTALL_PREFIX}/Downsample3D.sh ${EXCLUDE_MASK} ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii ${DSFACTOR} $ATLASIMAGE ${OMETIFF} 2>&1 | tee -a  $LOG
    else
        echo ConvertImage 3 ${EXCLUDE_MASK} $OUTPUTDIR/exclusion_mask_downsampled_${DSFACTOR}.nii 1
        ConvertImage 3 ${EXCLUDE_MASK} $OUTPUTDIR/exclusion_mask_downsampled_${DSFACTOR}.nii 1
    fi
    ${INSTALL_PREFIX}/fix_header.sh $OUTPUTDIR/exclusion_mask_downsampled_${DSFACTOR}.nii  $OUTPUTDIR/exclusion_mask_downsampled_${DSFACTOR}.nii  25x25x25  2>&1 | tee -a  $LOG # Fix header, for the time being, hardcoded
    # Extra binarization is needed because sometimes the exclusion mask is 0,255 instead of 0,1
    echo binarize ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii 2>&1 | tee -a  $LOG
    binarize ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii
    #${INSTALL_PREFIX}/mask_correction.sh  ${OUTPUTDIR}/atlaslabel_def_origspace_masked/ ${EXCLUDE_MASK} ${OUTPUTDIR}/640_FRST_seg/ ${OUTPUTDIR}/640_FRST_seg_corrected/ 2>&1 | tee -a $LOG 
    ${INSTALL_PREFIX}/mask_correction_v2.sh  ${OUTPUTDIR}/atlaslabel_def.nii.gz  ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii ${OUTPUTDIR}/640_FRST_seg/ ${OUTPUTDIR}/640_FRST_seg_corrected/ ${MASKOVLRATIO} 2>&1 | tee -a $LOG 
    
    
    
    
    echo antsApplyTransforms -d 3 -i ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii -r ${ATLASIMAGE} -o ${OUTPUTDIR}/exclusion_mask_atlasspace.nii -n NearestNeighbor -f 0 -v 1 -t [ ${OUTPUTDIR}/atlasimage_reg1InverseWarp.nii.gz ] -t [ ${OUTPUTDIR}/atlasimage_reg0GenericAffine.mat,1 ] --float     2>&1 | tee -a  $LOG
    antsApplyTransforms -d 3 -i ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii -r ${ATLASIMAGE} -o ${OUTPUTDIR}/exclusion_mask_atlasspace.nii -n NearestNeighbor -f 0 -v 1 -t [ ${OUTPUTDIR}/atlasimage_reg1InverseWarp.nii.gz ] -t [ ${OUTPUTDIR}/atlasimage_reg0GenericAffine.mat,1 ] --float    
    
    invert_binary_mask ${OUTPUTDIR}/exclusion_mask_atlasspace.nii ${OUTPUTDIR}/exclusion_mask_atlasspace.nii
    
    mkdir -p ${OUTPUTDIR}/heatmaps_atlasspace_corrected/
    for file in `ls ${OUTPUTDIR}/heatmaps_atlasspace/*atlasspace.nii.gz`
    do 
        Y=`basename $file`
        Y=`remove_ext $Y`
        Y=${OUTPUTDIR}/heatmaps_atlasspace_corrected/${Y}        
        echo ImageMath 3 ${Y}.nii  m $file ${OUTPUTDIR}/exclusion_mask_atlasspace.nii 
        ImageMath 3 ${Y}.nii  m $file ${OUTPUTDIR}/exclusion_mask_atlasspace.nii 
        ${INSTALL_PREFIX}/nii2tiff.sh ${Y}.nii ${Y}.tif float32 yes 2>&1 | tee -a  $LOG
        gzip -vf  ${Y}.nii 
    done
    gzip -vf  ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii  ${OUTPUTDIR}/exclusion_mask_atlasspace.nii
fi

# Clean up temporary files
rm -rf ${OUTPUTDIR}/640_N4Field/ 
rm -rf ${OUTPUTDIR}/640_N4/
rm -rf ${OUTPUTDIR}/atlaslabel_def_origspace
END=$(date +%s)
DIFF=$(( $END - $START ))
((sec=DIFF%60, DIFF/=60, min=DIFF%60, hrs=DIFF/60))
echo "CATNIP pipeline took $hrs HRS $min MIN $sec SEC"   2>&1 | tee -a  $LOG
echo "=================================================================================="   2>&1 | tee -a  $LOG


