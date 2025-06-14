#!/bin/bash
check_modules () {
    FUNC=$1    
    if ! [ -x "$(command -v "$FUNC")" ]; then
        echo "
    Error: $FUNC is not installed. Please add $FUNC to PATH.
        "
        exit 1
    fi
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
# `cat << EOF` This means that cat should stop reading when EOF is detected
cat << EOF  

Usage:

./CATNIP.sh  --cfos CHANNELFOS   --o OUTPUTDIR  --ob OB_FLAG  --udflip UPDOWN_FLIP_FLAG  \\
        --lrflip LR_FLIP_FLAG  --thr THRESHOLD  --dsfactor DSFACTOR  --cellradii RADII  --cellsizepx CELLSIZEPX \\        
        --ncpu NUMCPU  --exclude_mask EXCLUSION_MASK_IMAGE  --bg_noise_param BG_NOISE_PARAM \\
        --atlasversion v5  --mask_ovl_ratio  MASK_OVL_RATIO --slow
    
    Required arguments:
    
    CHANNELFOS      : (Required) A folder containing FOS channel in 2D tif format
    
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
    CELLSIZEPX    : (Optional) A comma separated pair of cell size range in pixels. 
                       Default 9,900. The numbers indicate the minimum and maximum 
                       sizes of a cell are 9 and 900 pixels. After thresholding, 
                       if an object is bigger than the higher limit, a Watershed algorithm 
                       is run to split it. Anything smaller or bigger is not counted. 
                      
    NUMCPU          : (Optional) Number of parallel processing cores to be used.
                      This must be less/equal to the total available number of 
                      cpus. Usually 8 or 12 is fine. Maximum required memory is
                      also proportional to the number of processes. Default 12.
                      
    THRESHOLD       : (Optional) FRST segmentation thresholds. FRST output is a 
                      continuous valued image from 0-65000. Usually, a threshold 
                      of 7000 is very sensitive. For debugging purpose, it is 
                      recommeneded that a range of thresholds are used, so that 
                      segmentations for each of the thresholds are generated. 
                      Example, 10000:1000:15000 means 6 segmentation images will 
                      be generated at thresholds 10000,11000,..,15000.
                      If not mentioned, default is 45000:5000:60000.                                              
                      Check the FRST images to identify a suitable range of thresholds.
                      
    EXCLUSION_MASK  : (Optional) A binary mask indicating bad regions/artifacts in the image. 
                      ** 1) This must already be in the "atlas orientation".
                      See XX_FLIP_FLAG and --atlasversion argument for the definition
                      of the atlas orientation.
                      ** 2) This must be in one of the following space, 
                      (a) Same dimension as the original image "after" proper orientation, 
                      i.e., this mask will "NOT" be reoriented based on the flip flags.
                      In this case, only use .tif or .tiff format.
                      (b) This mask can also be a NIFTI (.nii or .nii.gz) image 
                      if it is in the downsampled image space. It is recommended
                      to run the pipeline once with correct downsampling factor
                      to generate all outputs, then draw a binary mask on the
                      downsampled_AxBxC_brain.nii.gz image.
                      
    BG_NOISE_PARAM  : (Optional) Background noise removal parameter to generate a
                      brain mask to be used for registration target. It is a comma-separated
                      pair, e.g. 40,1.05. The first number (40) denotes a percentile
                      that is initialized as noise background noise threshold. Use
                      higher number (55) for images with heavy noise. The second
                      number indicates a slope (>1) with which the noise threshold is
                      successively increased. Default is 50,1.05. If the brain mask too 
                      conservative, use lower number (e.g., 40,1.05). If there is a lot
                      of background left, use higher number (e.g., 55, 1.1)
                      
    ATLASVERSION    : (Optional) Choose between the following options
                      v1: uClear atlas, sagittal, single hemisphere
                      v2: Clearmap2 atlas, sagittal, single hemisphere. 
                      v3: v2 atlas but without cerebellum
                      v4: whole brain Clearmap2 atlas, axial, cerebellum front & 
                          brainstem back in depth
                      v5: (Default) whole brain Clearmap2 atlas, axial, cerebellum front & 
                          brainstem back in depth, with new colormap where left and 
                          right hemisphere labels have alternating numbers.
                      v6: v5 atlas but excludes brainstem and cerebellum
                      v7: v5 atlas but in coronal orientation, OB front and 
                          cerebellum back in depth.
                      
    MASK_OVL_RATIO    (Optional) A mask overlap ratio between 0 and 1. It is used only
                      when an EXCLUSION_MASK is mentioned. A ratio of 0.5 means a label
                      is going to be ignored if its overlap volume with the mask is 
                      less than half of its total volume. So small overlap with the 
                      exclusion mask is ignored. Default is 0.25.
                      
    SLOW              (Optional) Adding a --slow argument will make the ANTs registration
                      use a fixed seed and a single processor, as opposed to default
                      NUMCPU parallel processes. This also makes the registration
                      deterministic and reproducible at the cost of speed. Usually 
                      the registration takes 2-4 hours with 12 cpus. It will take 
                      approx 12 times that when this argument is added. This argument 
                      only affects the ANTs registration, the rest of the pipeline 
                      always uses NUMCPU parallel processes. 
                      
    
    Example: 
    ./CATNIP.sh --cfos /home/user/input/640/ --o /home/user/output  \\
        --ob yes --udflip no --lrflip yes --cellradii 3,4,5,6 --thr 5000:5000:60000  \\
         --ncpu 12 --dsfactor 9x9x7  --exclude_mask  /home/user/artifact_mask_9x9x7.nii.gz \\
         --atlasversion v5 --bg_noise_param 50,1.05 --cellsizepx 9,800
    
    Required arguments:
    /home/user/input/640/ --> 2D tiff images of the FOS channel    
    /home/user/output     --> Output will be written here
    yes                   --> Image has OB (--ob)
    no                    --> Image is not up-down flipped (--udflip)
    yes                   --> Image is left-right flipped, i.e. Cerebellum is bottom 
                              right side instead of bottom left side (--lrflip)
    9x9x7                 --> Dowsampling factor for registration   
    3,4,5,6               --> Cell radii is *pixels*  
    9,800                 --> A cell must have volume between 9 and 800 voxels
    
      
    Optional arguments:
    
    12                    --> Number of cpu to use    
    5000:5000:60000       --> Segmentation images and stats will be generated at 
                              thresholds 5000,10000,..,55000,60000
    /home/user/artifact_mask_9x9x7.nii.gz  --> Artifact (binary) mask drawn on the
                              downsampled image.                                
        
    This code is meant to run on Biowulf. If you want to run this on your local 
    computer, please install ANTs (add the bin folder to \$PATH), and Matlab MCR v912 (2022a).
    Then change the MCRROOT variables in the associated scripts.
EOF
# EOF is found above and hence cat command stops reading. 
# This is equivalent to echo but much neater when printing out.
}

if [ "$#" -lt "1" ];then
    showHelp
    exit 0
fi


# Biowulf specific commands, for local machine, comment the following line
#module load ANTs/2.2.0


check_modules antsRegistration
check_modules antsApplyTransforms
check_modules ConvertImage    
check_modules N4BiasFieldCorrection
check_modules pigz
#check_modules tiffinfo
check_modules ImageMath
#check_modules fslmaths

# -o is for short options like -v
# -l is for long options with double dash like --version
# the comma separates different long options
# -a is for long options with single dash like -version
options=$(getopt -l "cfos:,ncpu:,o:,ob:,udflip:,lrflip:,thr:,ometiff:,dsfactor:,cellradii:,exclude_mask:,atlasversion:,bg_noise_param:,mask_ovl_ratio:,cellsizepx:,slow,help" -o "h" -- "$@")

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
BG_NOISE_PARAM=50,1.05
ATLASVERSION=v5
CELLSIZEINPX=9,900
MASKOVLRATIO=0.25
WHOLEBRAIN=false  # If wholebrain flag is true, ignore hemisphere masking
REPRODUCIBLE=false  # ANTS with fixed seed and numcpu=1
    
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
--cfos) 
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
--cellsizepx) 
    shift
    export CELLSIZEINPX=$1
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
--slow)     
    export REPRODUCIBLE=true
    ;; 
--)
    shift
    break;;
esac
shift
done


#FSLOUTPUTTYPE=NIFTI

# ========================= Set up paths and check for errors =========================


OUTPUTDIR=`readlink -f $OUTPUTDIR`

OMETIFF=${CHANNEL640} # Legacy from previous pipeline, probably not needed any more


if [ x"${CHANNEL640}" == "x" ];then
    echo "ERROR: FOS channel is required with --cfos argument. Exiting."
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
    echo "WARNING: Using default 45000:5000:60000."
    THRESHOLD="45000:5000:60000"    
fi

if  [ "${ATLASVERSION}" != "v1" ] && [ "${ATLASVERSION}" != "v2" ] && [ "${ATLASVERSION}" != "v3" ] && \
 [ "${ATLASVERSION}" != "v4" ] && [ "${ATLASVERSION}" != "v5" ] && [ "${ATLASVERSION}" != "v6" ]  && \
  [ "${ATLASVERSION}" != "v7" ] && [ "${ATLASVERSION}" != "v8" ];then
    echo "ERROR: ATLASVERSION flag (--atlasversion XX) must be v1,v2,..,v8. You entered $ATLASVERSION"
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
RAND=$((RAND % 180))  # This is to disable race conditions for multiple matlab compiler calls.
                      # This is specifically useful for HPC clusters while running lots of 
                      # codes simultaneously.
#sleep $RAND
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


if [ "$ATLASVERSION" == "v1" ] || [ "$ATLASVERSION" == "v8" ];then
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
    
elif [ "$ATLASVERSION" == "v4" ];then  # v4 atlas is the wholebrain version of axial images from new 3i microscope
    if [ "$OBFLAG" == "yes" ];then    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_reference_axial.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_annotation_axial_nooutlier.nii.gz
    else    
        ATLASIMAGE=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_reference_axial_noOB.nii.gz
        ATLASLABEL=${INSTALL_PREFIX}/atlas_${ATLASVERSION}/ABA_25um_annotation_axial_nooutlier_noOB.nii.gz
    fi
    WHOLEBRAIN=true
    
elif [ "$ATLASVERSION" == "v5" ];then  # v4 atlas is the wholebrain version of axial images from new 3i microscope
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
    



    
BG_NOISE_INIT=`echo ${BG_NOISE_PARAM} |cut -d ',' -f1`
BG_NOISE_SLOPE=`echo ${BG_NOISE_PARAM} |cut -d ',' -f2`

START=$(date +%s)
echo "========================= Image Info ===============================" 2>&1 | tee -a $LOG
echo "FOS Channel                   : $CHANNEL640"      2>&1 | tee -a  $LOG
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
echo "Background noise init/slope   : ${BG_NOISE_INIT}/${BG_NOISE_SLOPE}" 2>&1 | tee -a  $LOG
if [ x"${EXCLUDE_MASK}" != "x" ];then
    echo "Exclusion mask                : ${EXCLUDE_MASK}"  2>&1 | tee -a  $LOG
fi
echo "Cell radii (in pixels)        : $CELLRADII  "     2>&1 | tee -a  $LOG
echo "Mask overlap ratio            : $MASKOVLRATIO  "  2>&1 | tee -a  $LOG
echo "Cell size range (in pixels)   : $CELLSIZEINPX  "     2>&1 | tee -a  $LOG
echo "ANTS with fixed seed          : $REPRODUCIBLE "  2>&1 | tee -a  $LOG

H=`${INSTALL_PREFIX}/image_info.sh $CHANNEL640 H`
W=`${INSTALL_PREFIX}/image_info.sh $CHANNEL640 W`
D=`${INSTALL_PREFIX}/image_info.sh $CHANNEL640 D`

echo "Image size                    : ${H}x${W}x${D} (HxWxD)"   2>&1 | tee -a  $LOG
CHANNEL640ORIG=${CHANNEL640}


# ======================== Run actual scripts ==================================



if [ "$UDFLIPFLAG" == "yes" ] || [ "$LRFLIPFLAG" == "yes" ];then
    echo "======================== Flipping Images ===========================" 2>&1 | tee -a $LOG 
    mkdir -p $OUTPUTDIR/flipped/    
    ${INSTALL_PREFIX}/FlipImages.sh $CHANNEL640 $OUTPUTDIR/flipped/ $UDFLIPFLAG $LRFLIPFLAG no $NUMCPU  2>&1 | tee -a $LOG
    CHANNEL640=$OUTPUTDIR/flipped/
    echo "====================================================================" 2>&1 | tee -a $LOG 
    
fi
echo "================ Downsample FOS channel for N4 correction =================" 2>&1 | tee -a $LOG 

# Downsample by DSFACTOR
${INSTALL_PREFIX}/Downsample3D.sh ${CHANNEL640} $OUTPUTDIR/downsampled_${DSFACTOR}.nii $DSFACTOR $ATLASIMAGE ${OMETIFF} 2>&1 | tee -a  $LOG
${INSTALL_PREFIX}/fix_header.sh $OUTPUTDIR/downsampled_${DSFACTOR}.nii  $OUTPUTDIR/downsampled_${DSFACTOR}.nii  25x25x25 2>&1 | tee -a  $LOG # Fix header, for the time being, hardcoded
cp -vf $OUTPUTDIR/downsampled_${DSFACTOR}.nii $OUTPUTDIR/downsampled_${DSFACTOR}_orig.nii 2>&1 | tee -a  $LOG
${INSTALL_PREFIX}/remove_background_noise.sh  $OUTPUTDIR/downsampled_${DSFACTOR}.nii ${BG_NOISE_INIT} $OUTPUTDIR/downsampled_${DSFACTOR}.nii ${BG_NOISE_SLOPE}  2>&1 | tee  -a $LOG
echo "================= Running N4 bias field correction  ====================" 2>&1 | tee -a $LOG 
# Run N4 in downsampled space for speed
${INSTALL_PREFIX}/binarize.sh $OUTPUTDIR/downsampled_${DSFACTOR}.nii ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii  2>&1 | tee -a $LOG 
echo "N4BiasFieldCorrection -d 3 -s 4 -i $OUTPUTDIR/downsampled_${DSFACTOR}.nii -o [ ${OUTPUTDIR}/downsampled_${DSFACTOR}_N4.nii,${OUTPUTDIR}/downsampled_${DSFACTOR}_N4Field.nii ] -c [ 50x50x50x50,0.0001] -r 1 -v 1 -x  ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii " 2>&1 | tee -a  $LOG
N4BiasFieldCorrection -d 3 -s 4 -i $OUTPUTDIR/downsampled_${DSFACTOR}.nii -o [ ${OUTPUTDIR}/downsampled_${DSFACTOR}_N4.nii,${OUTPUTDIR}/downsampled_${DSFACTOR}_N4Field.nii ] -c [ 50x50x50x50,0.0001] -r 1 -v 1  -x  ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii 2>&1 | tee -a  $LOG
echo ImageMath 3 ${OUTPUTDIR}/downsampled_${DSFACTOR}_N4Field.nii m  ${OUTPUTDIR}/downsampled_${DSFACTOR}_N4Field.nii   ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii  2>&1 | tee -a  $LOG
ImageMath 3 ${OUTPUTDIR}/downsampled_${DSFACTOR}_N4Field.nii m  ${OUTPUTDIR}/downsampled_${DSFACTOR}_N4Field.nii   ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii
echo "====================================================================" 2>&1 | tee -a $LOG 
# Upsample the N4 field
${INSTALL_PREFIX}/nii2tiff.sh  ${OUTPUTDIR}/downsampled_${DSFACTOR}_N4Field.nii ${OUTPUTDIR}/downsampled_${DSFACTOR}_N4Field.tif  float32 yes 2>&1 | tee -a  $LOG
echo "============= Upsampling bias field to original image space =============" 2>&1 | tee -a $LOG 
${INSTALL_PREFIX}/upsample_image.sh ${OUTPUTDIR}/downsampled_${DSFACTOR}_N4Field.tif ${OUTPUTDIR}/N4Field/  ${H}x${W}x${D}  nearest false true float32  2>&1 | tee -a $LOG 
echo "=============== Multiplying bias field with original image =============" 2>&1 | tee -a $LOG 
# Multiply the N4 field with the original image, this will be used for registration and segmentation
${INSTALL_PREFIX}/N4Process.sh ${CHANNEL640} ${OUTPUTDIR}/N4Field/  $OUTPUTDIR/N4/ ${DSFACTOR} 2>&1 | tee -a $LOG 

export CHANNEL640=${OUTPUTDIR}/N4/   


echo "================ Downsample bias corrected 640 image =================" 2>&1 | tee -a $LOG 
# Downsample to approximately 25um resolution, for debugging purpose
${INSTALL_PREFIX}/Downsample3D.sh ${CHANNEL640} $OUTPUTDIR/downsampled_${DSFACTOR}.nii ${DSFACTOR} $ATLASIMAGE ${OMETIFF} 2>&1 | tee -a  $LOG
echo "====================================================================" 2>&1 | tee -a $LOG 
${INSTALL_PREFIX}/fix_header.sh $OUTPUTDIR/downsampled_${DSFACTOR}.nii  $OUTPUTDIR/downsampled_${DSFACTOR}.nii  25x25x25  2>&1 | tee -a  $LOG # Fix header, for the time being, hardcoded

echo "================ Atlas registration with ANTs =================" 2>&1 | tee -a $LOG 
${INSTALL_PREFIX}/image_clamp.sh $OUTPUTDIR/downsampled_${DSFACTOR}.nii  $OUTPUTDIR/downsampled_${DSFACTOR}_brain.nii 99 true 2>&1 | tee -a  $LOG
ANTS_RANDOM_SEED=1234
if [ "${REPRODUCIBLE}" == "false" ];then
    echo ${INSTALL_PREFIX}/AntsExample.sh  $OUTPUTDIR/downsampled_${DSFACTOR}_brain.nii $ATLASIMAGE fast $OUTPUTDIR/atlasimage_reg.nii $NUMCPU   4x2x1  2>&1 | tee  -a $LOG
    ${INSTALL_PREFIX}/AntsExample.sh  $OUTPUTDIR/downsampled_${DSFACTOR}_brain.nii $ATLASIMAGE fast $OUTPUTDIR/atlasimage_reg.nii $NUMCPU   4x2x1  2>&1 | tee  -a $LOG
else
    echo ${INSTALL_PREFIX}/AntsExample.sh  $OUTPUTDIR/downsampled_${DSFACTOR}_brain.nii $ATLASIMAGE fast $OUTPUTDIR/atlasimage_reg.nii 1   4x2x1  2>&1 | tee  -a $LOG
    ${INSTALL_PREFIX}/AntsExample.sh  $OUTPUTDIR/downsampled_${DSFACTOR}_brain.nii $ATLASIMAGE fast $OUTPUTDIR/atlasimage_reg.nii 1   4x2x1  2>&1 | tee  -a $LOG
fi

echo "================== Transforming labels =========================" 2>&1 | tee -a $LOG 
# Apply the transform to the label
echo antsApplyTransforms -d 3 -i $ATLASLABEL -r $OUTPUTDIR/downsampled_${DSFACTOR}.nii -o $OUTPUTDIR/atlaslabel_def.nii -n NearestNeighbor --float -f 0 -v 1 -t $OUTPUTDIR/atlasimage_reg1Warp.nii.gz -t $OUTPUTDIR/atlasimage_reg0GenericAffine.mat   2>&1 | tee -a  $LOG
antsApplyTransforms -d 3 -i $ATLASLABEL -r $OUTPUTDIR/downsampled_${DSFACTOR}.nii -o $OUTPUTDIR/atlaslabel_def.nii -n NearestNeighbor --float -f 0 -v 1 -t $OUTPUTDIR/atlasimage_reg1Warp.nii.gz -t $OUTPUTDIR/atlasimage_reg0GenericAffine.mat   2>&1 | tee -a  $LOG
echo "====================================================================" 2>&1 | tee -a $LOG 

echo ConvertImage 3 $OUTPUTDIR/atlaslabel_def.nii $OUTPUTDIR/atlaslabel_def.nii 2  2>&1 | tee -a  $LOG
ConvertImage 3 $OUTPUTDIR/atlaslabel_def.nii $OUTPUTDIR/atlaslabel_def.nii 2  2>&1 | tee -a  $LOG



echo "====================================================================" 2>&1 | tee -a $LOG 
# Resample the label to the original space
${INSTALL_PREFIX}/nii2tiff.sh $OUTPUTDIR/atlaslabel_def.nii $OUTPUTDIR/atlaslabel_def.tif uint16 yes 2>&1 | tee  -a $LOG 
echo "================= Upsampling label to original image space =============" 2>&1 | tee -a $LOG 
${INSTALL_PREFIX}/upsample_image.sh $OUTPUTDIR/atlaslabel_def.tif $OUTPUTDIR/atlaslabel_def_origspace/ ${H}x${W}x${D} nearest false true uint16 2>&1 | tee  -a $LOG 


if [ "$WHOLEBRAIN" == "false" ];then
    echo "=============== Computing midline by transforming atlas hemisphere mask ===========" 2>&1 | tee -a $LOG
    echo "antsApplyTransforms -d 3 -i $ATLASHEMIMASK -r $OUTPUTDIR/downsampled_${DSFACTOR}.nii -o $OUTPUTDIR/hemispheremask_${DSFACTOR}.nii -n NearestNeighbor --float -f 0 -v 1 -t $OUTPUTDIR/atlasimage_reg1Warp.nii.gz -t $OUTPUTDIR/atlasimage_reg0GenericAffine.mat" 2>&1 | tee -a  $LOG
    antsApplyTransforms -d 3 -i $ATLASHEMIMASK -r $OUTPUTDIR/downsampled_${DSFACTOR}.nii -o $OUTPUTDIR/hemispheremask_${DSFACTOR}.nii -n NearestNeighbor --float -f 0 -v 1 -t $OUTPUTDIR/atlasimage_reg1Warp.nii.gz -t $OUTPUTDIR/atlasimage_reg0GenericAffine.mat   2>&1 | tee -a  $LOG

    #echo "fslmaths ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii -mas ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii -odt char"  | tee -a  $LOG
    #fslmaths ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii -mas ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii -odt char
    echo "ImageMath 3 ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii m  ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii" | tee -a $LOG
    ImageMath 3 ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii m  ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii

    # Mask the atlaslabel_def image for Generate_Stats code
    #echo fslmaths ${OUTPUTDIR}/atlaslabel_def.nii  -mas ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii  ${OUTPUTDIR}/atlaslabel_def_brain.nii 2>&1 | tee -a  $LOG
    #fslmaths ${OUTPUTDIR}/atlaslabel_def.nii  -mas ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii  ${OUTPUTDIR}/atlaslabel_def_brain.nii
    echo "ImageMath 3 ${OUTPUTDIR}/atlaslabel_def_brain.nii m ${OUTPUTDIR}/atlaslabel_def.nii ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii " |tee -a $LOG
    ImageMath 3 ${OUTPUTDIR}/atlaslabel_def_brain.nii m ${OUTPUTDIR}/atlaslabel_def.nii ${OUTPUTDIR}/hemispheremask_${DSFACTOR}.nii 

    echo "====================================================================" 2>&1 | tee -a $LOG 
    ${INSTALL_PREFIX}/nii2tiff.sh $OUTPUTDIR/hemispheremask_${DSFACTOR}.nii $OUTPUTDIR/hemispheremask_${DSFACTOR}.tif uint16 yes 2>&1 | tee -a  $LOG
    echo "============= Upsampling hemisphere mask to original image space ================" 2>&1 | tee -a $LOG 
    ${INSTALL_PREFIX}/upsample_image.sh  $OUTPUTDIR/hemispheremask_${DSFACTOR}.tif  $OUTPUTDIR/hemispheremask_origspace/ ${H}x${W}x${D} nearest false true uint16 2>&1 | tee  -a $LOG 
    echo "============== Masking image by hemisphere mask =================" 2>&1 | tee -a $LOG 
    ${INSTALL_PREFIX}/image_math.sh ${CHANNEL640} $OUTPUTDIR/hemispheremask_origspace/  $OUTPUTDIR/N4_masked/   multiply  $NUMCPU 2>&1 | tee -a $LOG 
    echo "=============== Masking label by hemisphere mask ====================" 2>&1 | tee -a $LOG 
    ${INSTALL_PREFIX}/image_math.sh $OUTPUTDIR/atlaslabel_def_origspace/  $OUTPUTDIR/hemispheremask_origspace/ $OUTPUTDIR/atlaslabel_def_origspace_masked/   multiply  $NUMCPU 2>&1 | tee -a $LOG 
    echo "====================================================================" 2>&1 | tee -a $LOG 
else
    #ln -vs ${OUTPUTDIR}/atlaslabel_def.nii ${OUTPUTDIR}/atlaslabel_def_brain.nii   2>&1 | tee -a $LOG  
    #ln -vs ${OUTPUTDIR}/atlaslabel_def_origspace/  ${OUTPUTDIR}/atlaslabel_def_origspace_masked   2>&1 | tee -a $LOG  # not a / at the end of the "masked"
    #echo fslmaths ${OUTPUTDIR}/atlaslabel_def.nii  -mas ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii  ${OUTPUTDIR}/atlaslabel_def_brain.nii |tee -a $LOG
    #fslmaths ${OUTPUTDIR}/atlaslabel_def.nii  -mas ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii  ${OUTPUTDIR}/atlaslabel_def_brain.nii
    echo "ImageMath 3  ${OUTPUTDIR}/atlaslabel_def_brain.nii m  ${OUTPUTDIR}/atlaslabel_def.nii ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii " |tee -a $LOG
    ImageMath 3  ${OUTPUTDIR}/atlaslabel_def_brain.nii m  ${OUTPUTDIR}/atlaslabel_def.nii ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii
    
    #echo fslmaths ${OUTPUTDIR}/atlasimage_reg.nii   -mas ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii  ${OUTPUTDIR}/atlasimage_reg_brain.nii|tee -a $LOG
    #fslmaths ${OUTPUTDIR}/atlasimage_reg.nii   -mas ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii  ${OUTPUTDIR}/atlasimage_reg_brain.nii
    echo "ImageMath 3 ${OUTPUTDIR}/atlasimage_reg_brain.nii m ${OUTPUTDIR}/atlasimage_reg.nii  ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii" |tee -a $LOG
    ImageMath 3 ${OUTPUTDIR}/atlasimage_reg_brain.nii m ${OUTPUTDIR}/atlasimage_reg.nii  ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii
    
    
    ${INSTALL_PREFIX}/nii2tiff.sh ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii $OUTPUTDIR/hemispheremask_${DSFACTOR}.tif uint16 yes 2>&1 | tee -a  $LOG
    echo "=============== Upsampling brainmask to original space ===========" 2>&1 | tee -a $LOG
    ${INSTALL_PREFIX}/upsample_image.sh  $OUTPUTDIR/hemispheremask_${DSFACTOR}.tif  $OUTPUTDIR/hemispheremask_origspace/ ${H}x${W}x${D} nearest false true uint16 2>&1 | tee  -a $LOG 
    echo "============== Masking image by hemisphere mask =================" 2>&1 | tee -a $LOG 
    ${INSTALL_PREFIX}/image_math.sh ${CHANNEL640} $OUTPUTDIR/hemispheremask_origspace/  $OUTPUTDIR/N4_masked/   multiply  $NUMCPU 2>&1 | tee -a $LOG 
    echo "============== Masking atlas label by hemisphere mask =================" 2>&1 | tee -a $LOG 
    ${INSTALL_PREFIX}/image_math.sh ${OUTPUTDIR}/atlaslabel_def_origspace/ $OUTPUTDIR/hemispheremask_origspace/  $OUTPUTDIR/atlaslabel_def_origspace_masked/   multiply  $NUMCPU 2>&1 | tee -a $LOG 
fi


echo "========================= Running FRST =============================" 2>&1 | tee -a $LOG 
CHANNEL640=${OUTPUTDIR}/N4_masked/
mkdir -p $OUTPUTDIR/FRST/
mkdir -p $OUTPUTDIR/FRST_seg/
echo ${INSTALL_PREFIX}/ApplyFRST.sh ${CHANNEL640} $OUTPUTDIR/FRST/ $NUMCPU   $CELLRADII $OUTPUTDIR/downsampled_${DSFACTOR}_brain.nii 2>&1 | tee  -a $LOG
${INSTALL_PREFIX}/ApplyFRST.sh ${CHANNEL640} $OUTPUTDIR/FRST/ $NUMCPU  $CELLRADII $OUTPUTDIR/downsampled_${DSFACTOR}_brain.nii 2>&1 | tee -a  $LOG
echo "=================== Computing FRST segmentation ======================" 2>&1 | tee -a $LOG 
echo "Creating FRST segmentation by thresholding"  2>&1 | tee -a $LOG 
${INSTALL_PREFIX}/ApplyFRSTseg.sh $OUTPUTDIR/FRST/ $OUTPUTDIR/FRST_seg/ "${THRESHOLD}"   2>&1 | tee -a  $LOG


echo "============== Generating stats on the cell counts =================" 2>&1 | tee -a $LOG 
${INSTALL_PREFIX}/Generate_Stats.sh $OUTPUTDIR/FRST_seg/ ${INSTALL_PREFIX}/atlas_${ATLASVERSION}/atlas_info.txt   $OUTPUTDIR/atlaslabel_def_brain.nii $DSFACTOR $OUTPUTDIR/atlaslabel_def_origspace_masked/  $CELLSIZEINPX $OUTPUTDIR/FRST_seg/FRSTseg*/  2>&1 | tee -a  $LOG

echo "============== Writing corrected FRST segmentations  with cell volume =================" 2>&1 | tee -a $LOG 
${INSTALL_PREFIX}/FRSTsegcorrect.sh ${OUTPUTDIR}/atlaslabel_def_origspace  ${OUTPUTDIR}/FRST_seg/cellvolumes/ "${THRESHOLD}" ${OUTPUTDIR}/FRST_seg/  $NUMCPU 2>&1 | tee -a  $LOG


echo "========= Generating cell segmentation heatmaps in downsampled image space =======" 2>&1 | tee -a $LOG 
mkdir ${OUTPUTDIR}/heatmaps_atlasspace/
mkdir ${OUTPUTDIR}/heatmaps_imagespace/
${INSTALL_PREFIX}/create_heatmap.sh ${CHANNEL640} ${DSFACTOR} ${OUTPUTDIR}/heatmaps_imagespace/  ${OUTPUTDIR}/downsampled_${DSFACTOR}.nii $NUMCPU ${OUTPUTDIR}/FRST_seg/cellvolumes/*.mat  2>&1 | tee -a  $LOG

echo "========= Generating cell segmentation heatmaps in atlas space =======" 2>&1 | tee -a $LOG 

# Create a brainmask in atlasspace, to be used by heatmaps_atlasspace to differentiate
# between zero values and background
antsApplyTransforms -d 3 -i ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii -r  ${ATLASIMAGE} -o ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask_atlasspace.nii -n NearestNeighbor -f 0 -v 1 -t [ ${OUTPUTDIR}/atlasimage_reg1InverseWarp.nii.gz ] -t [ ${OUTPUTDIR}/atlasimage_reg0GenericAffine.mat,1 ] --float 2>&1 | tee -a  $LOG
#fslmaths ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask_atlasspace.nii ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask_atlasspace.nii -odt char

for file in `ls $OUTPUTDIR/heatmaps_imagespace/*.nii.gz`
do 
    M=`basename $file`
    #M=`remove_ext $M`
    M=${M%.*} 
    M=${M%.*} # remove the nii.gz
    X=${OUTPUTDIR}/heatmaps_atlasspace/${M}_atlasspace.nii    
    
    echo antsApplyTransforms -d 3 -i $file -r  ${ATLASIMAGE} -o $X -n Linear -f 0 -v 1 -t [ ${OUTPUTDIR}/atlasimage_reg1InverseWarp.nii.gz ] -t [ ${OUTPUTDIR}/atlasimage_reg0GenericAffine.mat,1 ] --float 2>&1 | tee -a  $LOG
    antsApplyTransforms -d 3 -i $file -r  ${ATLASIMAGE} -o $X -n Linear -f 0 -v 1 -t [ ${OUTPUTDIR}/atlasimage_reg1InverseWarp.nii.gz ] -t [ ${OUTPUTDIR}/atlasimage_reg0GenericAffine.mat,1 ] --float 2>&1 | tee -a  $LOG
    Y=${OUTPUTDIR}/heatmaps_atlasspace/${M}_atlasspace.tif
    ${INSTALL_PREFIX}/nii2tiff.sh ${X} ${Y} float32 yes 2>&1 | tee -a  $LOG
    pigz -vf -p $NUMCPU ${X} 2>&1 | tee -a  $LOG
done


echo "====================================================================" 2>&1 | tee -a $LOG 
#FSLOUTPUTTYPE=NIFTI_GZ
for file in `ls $OUTPUTDIR/heatmaps_imagespace/*.nii.gz`
do 
    M=`basename $file`
    #M=`remove_ext $M`
    M=${M%.*} # remove the nii.gz
    M=${M%.*}
    #echo fslmaths $file -mas ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii $file 2>&1 | tee -a  $LOG    
    #fslmaths $file -mas ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii $file
    echo "ImageMath 3 $file m $file ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii" |tee -a $LOG
    ImageMath 3 $file m $file ${OUTPUTDIR}/downsampled_${DSFACTOR}_brainmask.nii
    X=${OUTPUTDIR}/heatmaps_imagespace/${M}.tif         
    ${INSTALL_PREFIX}/nii2tiff.sh ${file} ${X} float32 yes 2>&1 | tee -a  $LOG    
done

echo "====================================================================" 2>&1 | tee -a $LOG 

${INSTALL_PREFIX}/nii2tiff.sh ${OUTPUTDIR}/downsampled_${DSFACTOR}.nii ${OUTPUTDIR}/downsampled_${DSFACTOR}.tif uint16 yes 2>&1 | tee -a  $LOG


#FSLOUTPUTTYPE=NIFTI
# If mask exists, redo the csvs with the mask.
if [ x"${EXCLUDE_MASK}" != "x" ];then
    echo "=============== Correcting CSV files and heatmaps with the exclusion mask ==============" 2>&1 | tee -a $LOG 
    mkdir -p ${OUTPUTDIR}/FRST_seg_corrected/
    if [ "${IMGSPACE}" == "original" ];then
        ${INSTALL_PREFIX}/Downsample3D.sh ${EXCLUDE_MASK} ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii ${DSFACTOR} $ATLASIMAGE ${OMETIFF} 2>&1 | tee -a  $LOG
    else
        echo ConvertImage 3 ${EXCLUDE_MASK} $OUTPUTDIR/exclusion_mask_downsampled_${DSFACTOR}.nii 1 2>&1 | tee -a  $LOG
        ConvertImage 3 ${EXCLUDE_MASK} $OUTPUTDIR/exclusion_mask_downsampled_${DSFACTOR}.nii 1 
    fi
    # Extra binarization is needed because sometimes the exclusion mask is 0,255 instead of 0,1
    ${INSTALL_PREFIX}/fix_header.sh $OUTPUTDIR/exclusion_mask_downsampled_${DSFACTOR}.nii  $OUTPUTDIR/exclusion_mask_downsampled_${DSFACTOR}.nii  25x25x25  2>&1 | tee -a  $LOG # Fix header, for the time being, hardcoded
    #echo fslmaths ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii -bin ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii -odt float | tee -a  $LOG
    #fslmaths ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii -bin ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii -odt float
    ${INSTALL_PREFIX}/binarize.sh  ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii 2>&1 | tee -a  $LOG 
    ConvertImage 3 ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii  ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii 0
    
    
    ${INSTALL_PREFIX}/mask_correction.sh  ${OUTPUTDIR}/atlaslabel_def.nii  ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii ${OUTPUTDIR}/FRST_seg/ ${OUTPUTDIR}/FRST_seg_corrected/ ${MASKOVLRATIO} 2>&1 | tee -a $LOG 
    
    
    
    
    echo antsApplyTransforms -d 3 -i ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii -r ${ATLASIMAGE} -o ${OUTPUTDIR}/exclusion_mask_atlasspace.nii -n NearestNeighbor -f 0 -v 1 -t [ ${OUTPUTDIR}/atlasimage_reg1InverseWarp.nii.gz ] -t [ ${OUTPUTDIR}/atlasimage_reg0GenericAffine.mat,1 ] --float     2>&1 | tee -a  $LOG
    antsApplyTransforms -d 3 -i ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii -r ${ATLASIMAGE} -o ${OUTPUTDIR}/exclusion_mask_atlasspace.nii -n NearestNeighbor -f 0 -v 1 -t [ ${OUTPUTDIR}/atlasimage_reg1InverseWarp.nii.gz ] -t [ ${OUTPUTDIR}/atlasimage_reg0GenericAffine.mat,1 ] --float    
    
    
    # Invert mask, remove FSL dependency
    echo "invert_binary_mask ${OUTPUTDIR}/exclusion_mask_atlasspace.nii  ${OUTPUTDIR}/exclusion_mask_atlasspace.nii " |tee -a  $LOG
    invert_binary_mask ${OUTPUTDIR}/exclusion_mask_atlasspace.nii  ${OUTPUTDIR}/exclusion_mask_atlasspace.nii
    #echo fslmaths ${OUTPUTDIR}/exclusion_mask_atlasspace.nii -sub 1 ${OUTPUTDIR}/exclusion_mask_atlasspace.nii  2>&1 | tee -a  $LOG
    #fslmaths ${OUTPUTDIR}/exclusion_mask_atlasspace.nii -sub 1 ${OUTPUTDIR}/exclusion_mask_atlasspace.nii
    #echo fslmaths ${OUTPUTDIR}/exclusion_mask_atlasspace.nii -abs ${OUTPUTDIR}/exclusion_mask_atlasspace.nii 2>&1 | tee -a  $LOG
    #fslmaths ${OUTPUTDIR}/exclusion_mask_atlasspace.nii -abs ${OUTPUTDIR}/exclusion_mask_atlasspace.nii
    
    mkdir -p ${OUTPUTDIR}/heatmaps_atlasspace_corrected/
    for file in `ls ${OUTPUTDIR}/heatmaps_atlasspace/*atlasspace.nii.gz`
    do 
        Y=`basename $file`
        Y=${Y%.*}
        Y=${Y%.*} # remove the .nii.gz
        #Y=`remove_ext $Y`
        Y=${OUTPUTDIR}/heatmaps_atlasspace_corrected/${Y}        
        #echo "fslmaths $file -mas ${OUTPUTDIR}/exclusion_mask_atlasspace.nii ${Y}.nii" 2>&1 | tee -a  $LOG
        #fslmaths $file -mas ${OUTPUTDIR}/exclusion_mask_atlasspace.nii ${Y}.nii              
        echo "ImageMath 3 ${Y}.nii  m $file ${OUTPUTDIR}/exclusion_mask_atlasspace.nii" | tee -a  $LOG
        ImageMath 3 ${Y}.nii  m $file ${OUTPUTDIR}/exclusion_mask_atlasspace.nii
        
        ${INSTALL_PREFIX}/nii2tiff.sh ${Y}.nii ${Y}.tif float32 yes 2>&1 | tee -a  $LOG
        pigz -vf -p $NUMCPU ${Y}.nii 
    done
    #pigz -vf -p $NUMCPU ${OUTPUTDIR}/exclusion_mask_downsampled_${DSFACTOR}.nii  ${OUTPUTDIR}/exclusion_mask_atlasspace.nii
fi

# Clean up temporary files
rm -rf ${OUTPUTDIR}/N4Field/ 
rm -rf ${OUTPUTDIR}/N4/
if [ "$WHOLEBRAIN" == "false" ];then
    rm -rf ${OUTPUTDIR}/atlaslabel_def_origspace
fi
pigz -vf -p $NUMCPU ${OUTPUTDIR}/*.nii
END=$(date +%s)
DIFF=$(( $END - $START ))
((sec=DIFF%60, DIFF/=60, min=DIFF%60, hrs=DIFF/60))
echo "CATNIP pipeline took $hrs HRS $min MIN $sec SEC"   2>&1 | tee -a  $LOG
echo "=================================================================================="   2>&1 | tee -a  $LOG


