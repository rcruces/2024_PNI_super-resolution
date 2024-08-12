#/bin/bash
SUBLIST="PNC002 PNC003 PNC006 PNC007 PNC009 PNC010 PNC015 PNC016 PNC018 PNC019"

## this is the actual superresolution step
for SUB in $SUBLIST; do
(   echo $SUB
    mkdir -p sub-$SUB/anat
    mkdir -p sub-$SUB/xfm
    mkdir -p sub-$SUB/tmp
    flirt -in ../../rawdata/sub-$SUB/ses-01/anat/sub-$SUB\_ses-01_acq-T1_T1map.nii.gz -ref ../../rawdata/sub-$SUB/ses-01/anat/sub-$SUB\_ses-01_acq-T1_T1map.nii.gz -out sub-$SUB/tmp/reference.nii.gz -applyisoxfm 0.25
    antsRegistrationSyNQuick.sh -d 3 -f sub-$SUB/tmp/reference.nii.gz -m ../../rawdata/sub-$SUB/ses-02/anat/sub-$SUB\_ses-02_acq-T1_T1map.nii.gz -o sub-$SUB/xfm/ses-02 -t r
    antsRegistrationSyNQuick.sh -d 3 -f sub-$SUB/tmp/reference.nii.gz -m ../../rawdata/sub-$SUB/ses-03/anat/sub-$SUB\_ses-03_acq-T1_T1map.nii.gz -o sub-$SUB/xfm/ses-03 -t r
    fslmaths sub-$SUB/tmp/reference.nii.gz -add sub-$SUB/xfm/ses-02Warped.nii.gz -add sub-$SUB/xfm/ses-03Warped.nii.gz -div 3 sub-$SUB/anat/sub-$SUB\_space-nativepro_qT1.nii.gz ) &
done
wait

## now just register other modalities to the superres

# T1w
for SUB in $SUBLIST; do
(   echo $SUB
    for SES in 01 02 03; do
        in=$(ls ../../rawdata/sub-$SUB/ses-$SES/anat/sub-$SUB\_ses-$SES\_acq-uni_T1map.nii.gz ../../rawdata/sub-$SUB/ses-$SES/anat/sub-$SUB\_ses-$SES\_acq-mprage_T1w.nii.gz)
        xfm=$(ls sub-$SUB/xfm/ses-$SES\0GenericAffine.mat)
        antsApplyTransforms -i $in -r sub-$SUB/tmp/reference.nii.gz -t $xfm -o sub-$SUB/tmp/T1w_$SES.nii.gz || antsApplyTransforms -i $in -r sub-$SUB/tmp/reference.nii.gz -o sub-$SUB/tmp/T1w_$SES.nii.gz
    done
    fslmaths sub-$SUB/tmp/T1w_01.nii.gz -add sub-$SUB/tmp/T1w_02.nii.gz -add sub-$SUB/tmp/T1w_03.nii.gz -div 3 sub-$SUB/anat/sub-$SUB\_space-nativepro_T1w.nii.gz ) &
done
wait

# T2star
for SUB in $SUBLIST; do
(   echo $SUB
    antsRegistrationSyNQuick.sh -d 3 -f sub-$SUB/anat/sub-$SUB\_space-nativepro_qT1.nii.gz -m ../../rawdata/sub-$SUB/ses-03/anat/sub-$SUB\_ses-03_T2starmap.nii.gz -o sub-$SUB/xfm/T2starmap -t r
    mv sub-$SUB/xfm/T2starmapWarped.nii.gz sub-$SUB/anat/sub-$SUB\_space-nativepro_T2star.nii.gz
done
wait


# MTR
for SUB in $SUBLIST; do
(   echo $SUB
    # run N4 on MTR images
    antsRegistrationSyNQuick.sh -d 3 -f sub-$SUB/anat/sub-$SUB\_space-nativepro_T1w.nii.gz -m ../B1correction/MTR/sub-$SUB\_ses-03_B1-corrected-MTR.nii -o sub-$SUB/xfm/MTR -t r
    mv sub-$SUB/xfm/MTRWarped.nii.gz sub-$SUB/anat/sub-$SUB\_space-nativepro_MTR.nii.gz ) &
done
wait


# DWI
for SUB in $SUBLIST; do
(   echo $SUB
    antsApplyTransforms -i ../micapipe_v0.2.0/sub-$SUB/ses-01/maps/sub-$SUB\_ses-01_space-nativepro_model-DTI_map-FA.nii.gz -r sub-$SUB/anat/sub-$SUB\_space-nativepro_qT1.nii.gz  -o sub-$SUB/tmp/ses-01_FA.nii.gz
    antsApplyTransforms -i ../micapipe_v0.2.0/sub-$SUB/ses-01/maps/sub-$SUB\_ses-01_space-nativepro_model-DTI_map-ADC.nii.gz -r sub-$SUB/anat/sub-$SUB\_space-nativepro_qT1.nii.gz  -o sub-$SUB/tmp/ses-01_ADC.nii.gz

    antsApplyTransforms -i ../micapipe_v0.2.0/sub-$SUB/ses-02/maps/sub-$SUB\_ses-02_space-nativepro_model-DTI_map-FA.nii.gz -r sub-$SUB/anat/sub-$SUB\_space-nativepro_qT1.nii.gz  -o sub-$SUB/tmp/ses-02_FA.nii.gz -t sub-$SUB/xfm/ses-020GenericAffine.mat
    antsApplyTransforms -i ../micapipe_v0.2.0/sub-$SUB/ses-02/maps/sub-$SUB\_ses-02_space-nativepro_model-DTI_map-ADC.nii.gz -r sub-$SUB/anat/sub-$SUB\_space-nativepro_qT1.nii.gz  -o sub-$SUB/tmp/ses-02_ADC.nii.gz -t sub-$SUB/xfm/ses-020GenericAffine.mat

    fslmaths sub-$SUB/tmp/ses-01_FA.nii.gz -add sub-$SUB/tmp/ses-02_FA.nii.gz -div 2 sub-$SUB/anat/sub-$SUB\_space-nativepro_FA.nii.gz || cp sub-$SUB/tmp/ses-01_FA.nii.gz sub-$SUB/anat/sub-$SUB\_space-nativepro_FA.nii.gz
    fslmaths sub-$SUB/tmp/ses-01_ADC.nii.gz -add sub-$SUB/tmp/ses-02_ADC.nii.gz -div 2 sub-$SUB/anat/sub-$SUB\_space-nativepro_ADC.nii.gz || cp sub-$SUB/tmp/ses-01_ADC.nii.gz sub-$SUB/anat/sub-$SUB\_space-nativepro_ADC.nii.gz ) &
done
wait

rm sub-*/tmp/*.nii.gz sub-*/xfm/*Warped.nii.gz


## T2star SyN reg



