#!/usr/bin/env bash

module unload python
module load python/2.5.2

#Process perf
function checkandexit {

        if [ $? -ne 0 ]
       	then
		exit 1
	fi
}

usage()
{
cat << EOF
usage: $0 options

This script runs the brain tumor preprocessing pipeline on perfusion images

OPTIONS:
	-h show this message
	-s subjectID with timepoint suffix {0,1,2}
	-i /path/to/perf/image
	-t /path/to/processed/reference/t1ce/file to register perfusion image to and skull-strip with
	-o /path/to/output/directory

EOF
}


perf=
t1ce=
OUTDIR=
SUBID=

while getopts "hi:t:o:s:" OPTION
do
	case $OPTION in
		h)
			usage
			exit 1
			;;
		i)
			perf=$OPTARG
			;;
		t)
			t1ce=$OPTARG
			;;
		o)
			OUTDIR=$OPTARG
			;;
		s)	
			SUBID=$OPTARG
			;;
		?)
			usage
			exit
			;;
	esac
done

echo "PERF FILE:" ${perf}
echo "T1CE FILE:" ${t1ce}
echo "Output Dir:" ${OUTDIR}
echo "Subject ID:" ${SUBID}


if [ -z ${perf} ] || [ -z ${t1ce} ] || [ -z ${OUTDIR} ] || [ -z ${SUBID} ]
then
	usage
	exit 1
fi


PID=$$
TMP=${SBIA_TMPDIR}/brain_tumor_${SUBID}_${PID}
if [ -d ${TMP} ]
then
	rm -rfv ${TMP}
fi

echo "Making TempDir at: ${TMP} "
mkdir ${TMP}

echo "Splitting Perfusion Image"
echo /sbiasfw/external/fsl/4.1.5/bin/fslsplit ${perf} ${TMP}/${SUBID}_perf_vol -t
/sbiasfw/external/fsl/4.1.5/bin/fslsplit ${perf} ${TMP}/${SUBID}_perf_vol -t
checkandexit

echo "Registering first perfusion timepoint to t1ce image"
echo /sbiasfw/external/fsl/4.1.5/bin/flirt -in ${TMP}/${SUBID}_perf_vol0000.hdr -ref ${t1ce} -out ${TMP}/${SUBID}_perf_vol0000_r.hdr -omat ${TMP}/${SUBID}_perf_r.mat -searchcost mutualinfo -cost mutualinfo -dof 6 -searchrx -30 +30 -searchry -30 +30 -searchrz -30 +30 -coarsesearch 15 -finesearch 6 
/sbiasfw/external/fsl/4.1.5/bin/flirt -in ${TMP}/${SUBID}_perf_vol0000.hdr -ref ${t1ce} -out ${TMP}/${SUBID}_perf_vol0000_r.hdr -omat ${TMP}/${SUBID}_perf_r.mat -searchcost mutualinfo -cost mutualinfo -dof 6 -searchrx -30 +30 -searchry -30 +30 -searchrz -30 +30 -coarsesearch 15 -finesearch 6
checkandexit

echo "Applying registration matrix to other timepoints"

for i in `ls -1 ${TMP}/${SUBID}_perf_vol????.hdr`
do
	n=${i%.hdr}
	echo outputfile ${n}_r.hdr
	/sbiasfw/external/fsl/4.1.5/bin/flirt -in ${i} -ref ${t1ce} -out ${n}_r.hdr -applyxfm -init ${TMP}/${SUBID}_perf_r.mat 
	/sbiasfw/external/afni/2008_07_18_1710/11_20_2009/bin/3dcalc -a ${n}_r.hdr -b ${t1ce} -prefix ${n}_r_strip.hdr -expr 'a*bool(b)'
done

#merge final volumes together and delete extra files
echo "Merging t1ce aligned, skull-stripped perfusion timepoints"
echo fslmerge -t ${TMP}/${SUBID}_perf_r_strip.hdr ${TMP}/${SUBID}_perf_vol????_r_strip.hdr
/sbiasfw/external/fsl/4.1.5/bin/fslmerge -t ${TMP}/${SUBID}_perf_r_strip.hdr ${TMP}/${SUBID}_perf_vol????_r_strip.hdr
checkandexit

/sbiasfw/external/afni/2008_07_18_1710/11_20_2009/bin/nifti1_test -zn1 ${TMP}/${SUBID}_perf_r_strip.hdr ${TMP}/${SUBID}_perf_r_strip
checkandexit

echo "Copying Processed File to Output Directory"
if [ ! -e ${OUTDIR} ]
then
	mkdir -p ${OUTDIR}
fi

mv ${TMP}/${SUBID}_perf_r_strip.nii.gz ${OUTDIR}/${SUBID}_perf_pp.nii.gz

rm -fv ${file}_perf_vol*
rm -fv ${TMP}/${SUBID}_perf_r_strip.hdr ${TMP}/${SUBID}_perf_r_strip.img
rm -rfv ${TMP}
