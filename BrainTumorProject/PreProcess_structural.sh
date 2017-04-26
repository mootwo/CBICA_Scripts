#!/usr/bin/env bash

#TODO: Include optional to provide mask for skull stripping


module unload python
module load python/2.5.2

checkandexit()
{
        # Check the supplied value, typically the return value from the
        # previous command. If the return value is not 0, then print a 
        # message to STDERR and exit.

        if [ $1 != 0 ] ; then
                # There was an error, bail out!
                /bin/echo "$2" 1>&2
                exit $1
        fi
}

echoV()
{
	if [ ${VERBOSE} -eq 1 ]
	then
		echo $1
	fi
}


usage()
{
cat << EOF
usage: $0 options

This script runs the brain tumor preprocessing pipeline on structural data

OPTIONS:
	-h show this message
	-p OUTPUT PREFIX
	-g /path/to/t1ce/image REQUIRED
	-t /path/to/t1/image OPTIONAL
	-w /path/to/t2/image OPTIONAL
	-f /path/to/flair/image OPTIONAL
	-o /path/to/output/directory
	-v verbose

EOF
}

#Defaults
t1=
t2=
t1ce=
flair=
OUTDIR=
PREFIX=
VERBOSE=0

while getopts "ht:w:g:f:o:p:v" OPTION
do
	case $OPTION in
		h)
			usage
			exit 1
			;;
		t)
			t1=$OPTARG
			;;
		w)
			t2=$OPTARG
			;;
		g)
			t1ce=$OPTARG
			;;
		f)
			flair=$OPTARG
			;;
		o)
			OUTDIR=$OPTARG
			;;
		p)	PREFIX=$OPTARG
			;;
		v)
			VERBOSE=1
			;;
		?)
			echo "Unrecognized Options. Exiting. " 1>&2      
			usage 1>&2
			exit 1
			;;
	esac
done

echoV "--->Input Arguments:"
echoV "T1 File: ${t1}"
echoV "T2 File: ${t2}"
echoV "T1CE File: ${t1ce}"
echoV "FLAIR File: ${flair}"
echoV "OUTPUT Directory: ${OUTDIR}"
echoV "PREFIX: ${PREFIX}"

#Check for required input
if [ -z ${t1ce} ] ||  [ -z ${OUTDIR} ] || [ -z ${PREFIX} ]
then
	echo "Error. Not all input found. Exiting." 1>&2
	usage 1>&2
	exit 1
fi

#If output directory doesn't exist, try to make it
if [ ! -d ${OUTDIR} ]
then
	echoV "--->Output directory not detected to exist. Making it now"
	mkdir ${OUTDIR}
	checkandexit $?
fi

#Make temporary directory
echoV "--->Creating Temporary Directory"
TMP=`mktemp -d --tmpdir=${SBIA_TMPDIR} `
checkandexit $?
echoV "--->Temporary Directory Created at ${TMP}"
checkandexit $?

#ReOrient Images
echoV "---> Reorienting images to LPS"
echoV "---> Reorienting t1ce"
t1ce_prefix=${t1ce##*/}
t1ce_prefix=${t1ce_prefix%.nii.gz}
/cbica/home/rozyckim/Scripts/ClearSFORM+ReorientLPS.sh \
	-i ${t1ce} \
	-o ${TMP}/${t1ce_prefix}_LPS.nii.gz
checkandexit $?

if [ ! -z ${t1} ]
then
	echoV "---> Reorienting t1"
	t1_prefix=${t1##*/}
	t1_prefix=${t1_prefix%.nii.gz}
	/cbica/home/rozyckim/Scripts/ClearSFORM+ReorientLPS.sh \
		-i ${t1} \
		-o ${TMP}/${t1_prefix}_LPS.nii.gz
	checkandexit $?
fi

if [ ! -z ${t2} ]
then
	echoV "---> Reorienting t2"
	t2_prefix=${t2##*/}
	t2_prefix=${t2_prefix%.nii.gz}
	/cbica/home/rozyckim/Scripts/ClearSFORM+ReorientLPS.sh \
		-i ${t2} \
		-o ${TMP}/${t2_prefix}_LPS.nii.gz
	checkandexit $?
fi

if [ ! -z ${flair} ]
then
	echoV "---> Reorienting flair"
	flair_prefix=${flair##*/}
	flair_prefix=${flair_prefix%.nii.gz}
	/cbica/home/rozyckim/Scripts/ClearSFORM+ReorientLPS.sh \
		-i ${flair} \
		-o ${TMP}/${flair_prefix}_LPS.nii.gz
	checkandexit $?
fi


#run noise correction
echoV "--->Running SUSAN NOISE CORRECTION"
echoV "---> Processing ${PREFIX}_t1ce "
t1ce_prefix=${t1ce_prefix}_LPS
echoV "/sbiasfw/external/fsl/4.1.5/bin/susan ${TMP}/${t1ce_prefix}.nii.gz 80 0 3D 1 0 ${TMP}/${t1ce_prefix}_sus.hdr"
/sbiasfw/external/fsl/4.1.5/bin/susan ${TMP}/${t1ce_prefix}.nii.gz 80 0 3D 1 0 ${TMP}/${t1ce_prefix}_sus.hdr
checkandexit $?

if [ ! -z ${t1} ]
then
	echoV "---> Processing ${PREFIX}_t1 "
	t1_prefix=${t1_prefix}_LPS
	echoV "/sbiasfw/external/fsl/4.1.5/bin/susan ${TMP}/${t1_prefix}.nii.gz 65 0 3D 1 0 ${TMP}/${t1_prefix}_sus.hdr"
	/sbiasfw/external/fsl/4.1.5/bin/susan ${TMP}/${t1_prefix}.nii.gz 65 0 3D 1 0 ${TMP}/${t1_prefix}_sus.hdr
	checkandexit $?
fi

if [ ! -z ${t2} ]
then
	echoV "---> Processing ${PREFIX}_t2"
	t2_prefix=${t2_prefix}_LPS
	echoV "/sbiasfw/external/fsl/4.1.5/bin/susan  ${TMP}/${t2_prefix}.nii.gz 20 0 3D 1 0 ${TMP}/${t2_prefix}_sus.hdr"
	/sbiasfw/external/fsl/4.1.5/bin/susan ${TMP}/${t2_prefix}.nii.gz 20 0 3D 1 0 ${TMP}/${t2_prefix}_sus.hdr
	checkandexit $?
fi

if [ ! -z ${flair} ]
then
		
	echoV "---> Processing ${PREFIX}_flair"
	flair_prefix=${flair_prefix}_LPS
	echoV "/sbiasfw/external/fsl/4.1.5/bin/susan ${TMP}/${flair_prefix}.nii.gz 65 0 3D 1 0 ${TMP}/${flair_prefix}_sus.hdr"
	/sbiasfw/external/fsl/4.1.5/bin/susan ${TMP}/${flair_prefix}.nii.gz 65 0 3D 1 0 ${TMP}/${flair_prefix}_sus.hdr
	checkandexit $?
fi




#Run Bias Correction
echoV "---> Running N3 BIAS CORRECTION"
echoV "---> Processing ${PREFIX}_t1ce"
echoV "/sbiasfw/lab/sbiaUtilities/0.3.3/centos6/bin/n3BiasCorrection.py -d ${TMP}/${t1ce_prefix}_sus.hdr -p ${t1ce_prefix}_sus_n3 -o ${TMP}"
/sbiasfw/lab/sbiaUtilities/0.3.3/centos6/bin/n3BiasCorrection.py -d ${TMP}/${t1ce_prefix}_sus.hdr -p ${t1ce_prefix}_sus_n3 -o ${TMP}
checkandexit $?

if [ ! -z ${t1} ]
then
	echoV "---> Processing ${PREFIX}_t1"
	echoV "/sbiasfw/lab/sbiaUtilities/0.3.3/centos6/bin/n3BiasCorrection.py -d ${TMP}/${t1_prefix}_sus.hdr -p ${t1_prefix}_sus_n3 -o ${TMP}"
	/sbiasfw/lab/sbiaUtilities/0.3.3/centos6/bin/n3BiasCorrection.py -d ${TMP}/${t1_prefix}_sus.hdr -p ${t1_prefix}_sus_n3 -o ${TMP}
	checkandexit $?
fi

if [ ! -z ${t2} ]
then
	echoV "---> Processing ${PREFIX}_t2"
	echoV "/sbiasfw/lab/sbiaUtilities/0.3.3/centos6/bin/n3BiasCorrection.py -d ${TMP}/${t2_prefix}_sus.hdr -p ${t2_prefix}_sus_n3 -o ${TMP}"
	/sbiasfw/lab/sbiaUtilities/0.3.3/centos6/bin/n3BiasCorrection.py -d ${TMP}/${t2_prefix}_sus.hdr -p ${t2_prefix}_sus_n3 -o ${TMP}
	checkandexit $?
fi

if [ ! -z ${flair} ]
then
	echoV "---> Processing ${PREFIX}_flair"
	echoV "/sbiasfw/lab/sbiaUtilities/0.3.3/centos6/bin/n3BiasCorrection.py -d ${TMP}/${flair_prefix}_sus.hdr -p ${flair_prefix}_sus_n3 -o ${TMP}"
	/sbiasfw/lab/sbiaUtilities/0.3.3/centos6/bin/n3BiasCorrection.py -d ${TMP}/${flair_prefix}_sus.hdr -p ${flair_prefix}_sus_n3 -o ${TMP}
	checkandexit $?
fi

#Run Flirt for non-t1ce modalities
echoV "---->Running FLIRT for AFFINE REGISTRATIONS"
if [ ! -z ${t1} ]
then
	echoV "---> Processing ${PREFIX}_t1 "
	echoV "/sbiasfw/external/fsl/4.1.5/bin/flirt -in ${TMP}/${t1_prefix}_sus_n3.hdr -ref ${TMP}/${t1ce_prefix}_sus_n3.hdr -out ${TMP}/${t1_prefix}_sus_n3_r.hdr -omat ${TMP}/${t1_prefix}_sus_n3_r.mat -searchcost mutualinfo -cost mutualinfo -dof 6 -searchrx -30 +30 -searchry -30 +30 -searchrz -30 +30 -coarsesearch 15 -finesearch 6"	
	/sbiasfw/external/fsl/4.1.5/bin/flirt -in ${TMP}/${t1_prefix}_sus_n3.hdr -ref ${TMP}/${t1ce_prefix}_sus_n3.hdr -out ${TMP}/${t1_prefix}_sus_n3_r.hdr -omat ${TMP}/${t1_prefix}_sus_n3_r.mat -searchcost mutualinfo -cost mutualinfo -dof 6 -searchrx -30 +30 -searchry -30 +30 -searchrz -30 +30 -coarsesearch 15 -finesearch 6 	
	checkandexit $?
fi

if [ ! -z ${t2} ]
then
	echoV "---> Processing ${PREFIX}_t2 "
	echoV "/sbiasfw/external/fsl/4.1.5/bin/flirt -in ${TMP}/${t2_prefix}_sus_n3.hdr -ref ${TMP}/${t1ce_prefix}_sus_n3.hdr -out ${TMP}/${t2_prefix}_sus_n3_r.hdr -omat ${TMP}/${t2_prefix}_sus_n3_r.mat -searchcost mutualinfo -cost mutualinfo -dof 6 -searchrx -30 +30 -searchry -30 +30 -searchrz -30 +30 -coarsesearch 15 -finesearch 6"
	/sbiasfw/external/fsl/4.1.5/bin/flirt -in ${TMP}/${t2_prefix}_sus_n3.hdr -ref ${TMP}/${t1ce_prefix}_sus_n3.hdr -out ${TMP}/${t2_prefix}_sus_n3_r.hdr -omat ${TMP}/${t2_prefix}_sus_n3_r.mat -searchcost mutualinfo -cost mutualinfo -dof 6 -searchrx -30 +30 -searchry -30 +30 -searchrz -30 +30 -coarsesearch 15 -finesearch 6 
	checkandexit $?
fi

if [ ! -z ${flair} ]
then
	echoV "---> Processing ${PREFIX}_flair "
	echoV "/sbiasfw/external/fsl/4.1.5/bin/flirt -in ${TMP}/${flair_prefix}_sus_n3.hdr -ref ${TMP}/${t1ce_prefix}_sus_n3.hdr -out ${TMP}/${flair_prefix}_sus_n3_r.hdr -omat ${TMP}/${flair_prefix}_sus_n3_r.mat -searchcost mutualinfo -cost mutualinfo -dof 6 -searchrx -30 +30 -searchry -30 +30 -searchrz -30 +30 -coarsesearch 15 -finesearch 6"	
	/sbiasfw/external/fsl/4.1.5/bin/flirt -in ${TMP}/${flair_prefix}_sus_n3.hdr -ref ${TMP}/${t1ce_prefix}_sus_n3.hdr -out ${TMP}/${flair_prefix}_sus_n3_r.hdr -omat ${TMP}/${flair_prefix}_sus_n3_r.mat -searchcost mutualinfo -cost mutualinfo -dof 6 -searchrx -30 +30 -searchry -30 +30 -searchrz -30 +30 -coarsesearch 15 -finesearch 6 
	checkandexit $?
fi

#TODO: Include Mask if Provided
#Skull Strip t1 image using BET, and then apply this mask to other modalities. If t1 image is absent, run skull stripping on t1ce
if [ ! -z ${t1} ]
then
	echoV "--->Running BET Skull-Stripping on T1 image. Then masking other modalities using this"
	echoV "--->Processing ${PREFIX}_t1"
	echoV "/sbiasfw/external/fsl/4.1.5/bin/bet ${TMP}/${t1_prefix}_sus_n3_r.hdr ${TMP}/SkullStrip.hdr "
	/sbiasfw/external/fsl/4.1.5/bin/bet ${TMP}/${t1_prefix}_sus_n3_r.hdr ${TMP}/SkullStrip.hdr 
	checkandexit $?
	#Copy to skull stripped file to have a skull stripped version of t1, correctly named
	cp ${TMP}/SkullStrip.hdr ${TMP}/${t1_prefix}_sus_n3_r_strip.hdr
	checkandexit $?
	cp ${TMP}/SkullStrip.img ${TMP}/${t1_prefix}_sus_n3_r_strip.img
	checkandexit $?
fi

#Apply t1 mask to t1ce
if [ ! -z ${t1} ]
then
	echoV "--->Processing ${PREFIX}_t1ce"
	echoV "/sbiasfw/external/afni/2008_07_18_1710/11_20_2009/bin/3dcalc -a ${TMP}/${t1ce_prefix}_sus_n3.hdr -b ${TMP}/SkullStrip.hdr -prefix ${TMP}/${t1ce_prefix}_sus_n3_strip.hdr -expr 'a*bool(b)'"
	/sbiasfw/external/afni/2008_07_18_1710/11_20_2009/bin/3dcalc -a ${TMP}/${t1ce_prefix}_sus_n3.hdr -b ${TMP}/SkullStrip.hdr -prefix ${TMP}/${t1ce_prefix}_sus_n3_strip.hdr -expr 'a*bool(b)'
	checkandexit $?
fi

#T1 image is absent. Calculate mask on t1ce
if [ -z ${t1} ]
then
	echoV "--->Running BET Skull-Stripping on T1C image. Then masking other modalities using this"
	echoV "--->Processing ${PREFIX}_t1ce"
	echoV "/sbiasfw/external/fsl/4.1.5/bin/bet ${TMP}/${t1ce_prefix}_sus_n3.hdr ${TMP}/${t1ce_prefix}_sus_n3_r_strip.hdr "
	/sbiasfw/external/fsl/4.1.5/bin/bet ${TMP}/${t1ce_prefix}_sus_n3.hdr ${TMP}/SkullStrip.hdr 
	checkandexit $?
	#Copy to skull stripped file to have a skull stripped version of t1, correctly named
	cp ${TMP}/SkullStrip.hdr ${TMP}/${t1ce_prefix}_sus_n3_strip.hdr
	checkandexit $?
	cp ${TMP}/SkullStrip.img ${TMP}/${t1ce_prefix}_sus_n3_strip.img
	checkandexit $?
fi

if [ ! -z ${t2} ]
then
	echoV "--->Processing ${PREFIX}_t2"
	echoV "/sbiasfw/external/afni/2008_07_18_1710/11_20_2009/bin/3dcalc -a ${TMP}/${t2_prefix}_sus_n3.hdr -b ${TMP}/SkullStrip.hdr -prefix ${TMP}/${t2_prefix}_sus_n3_strip.hdr -expr 'a*bool(b)'"
	/sbiasfw/external/afni/2008_07_18_1710/11_20_2009/bin/3dcalc -a ${TMP}/${t2_prefix}_sus_n3_r.hdr -b ${TMP}/SkullStrip.hdr -prefix ${TMP}/${t2_prefix}_sus_n3_r_strip.hdr -expr 'a*bool(b)'
	checkandexit $?
fi

if [ ! -z ${flair} ]
then
	echoV "--->Processing ${PREFIX}_flair"
	echoV "/sbiasfw/external/afni/2008_07_18_1710/11_20_2009/bin/3dcalc -a ${TMP}/${flair_prefix}_sus_n3.hdr -b ${TMP}/SkullStrip.hdr -prefix ${TMP}/${flair_prefix}_sus_n3_strip.hdr -expr 'a*bool(b)'"
	/sbiasfw/external/afni/2008_07_18_1710/11_20_2009/bin/3dcalc -a ${TMP}/${flair_prefix}_sus_n3_r.hdr -b ${TMP}/SkullStrip.hdr -prefix ${TMP}/${flair_prefix}_sus_n3_r_strip.hdr -expr 'a*bool(b)'
	checkandexit $?
fi



#move files to destination directory
echoV "Compressing Files and copying to Destination Directory"

echoV  "/sbiasfw/external/afni/2008_07_18_1710/11_20_2009/bin/nifti1_test -zn1 ${TMP}/${t1ce_prefix}_sus_n3_strip.hdr ${OUTDIR}/${PREFIX}_t1ce_pp.nii.gz" 
/sbiasfw/external/afni/2008_07_18_1710/11_20_2009/bin/nifti1_test -zn1 ${TMP}/${t1ce_prefix}_sus_n3_strip.hdr ${OUTDIR}/${PREFIX}_t1ce_pp.nii.gz  
checkandexit $?

if [ ! -z ${t1} ]
then
	echoV  "/sbiasfw/external/afni/2008_07_18_1710/11_20_2009/bin/nifti1_test -zn1 ${TMP}/${t1_prefix}_sus_n3_r_strip.hdr ${OUTDIR}/${PREFIX}_t1_pp.nii.gz" 
	/sbiasfw/external/afni/2008_07_18_1710/11_20_2009/bin/nifti1_test -zn1 ${TMP}/${t1_prefix}_sus_n3_r_strip.hdr ${OUTDIR}/${PREFIX}_t1_pp.nii.gz  
	checkandexit $?
fi


if [ ! -z ${t2} ]
then
	echoV  "/sbiasfw/external/afni/2008_07_18_1710/11_20_2009/bin/nifti1_test -zn1 ${TMP}/${t2_prefix}_sus_n3_r_strip.hdr ${OUTDIR}/${PREFIX}_t2_pp.nii.gz" 
	/sbiasfw/external/afni/2008_07_18_1710/11_20_2009/bin/nifti1_test -zn1 ${TMP}/${t2_prefix}_sus_n3_r_strip.hdr ${OUTDIR}/${PREFIX}_t2_pp.nii.gz  
	checkandexit $?
fi


if [ ! -z ${flair} ]
then
	echoV  "/sbiasfw/external/afni/2008_07_18_1710/11_20_2009/bin/nifti1_test -zn1 ${TMP}/${flair_prefix}_sus_n3_r_strip.hdr ${OUTDIR}/${PREFIX}_flair_pp.nii.gz" 
	/sbiasfw/external/afni/2008_07_18_1710/11_20_2009/bin/nifti1_test -zn1 ${TMP}/${flair_prefix}_sus_n3_r_strip.hdr ${OUTDIR}/${PREFIX}_flair_pp.nii.gz  
	checkandexit $?
fi


rm -fv ${TMP}/*
rmdir ${TMP}

