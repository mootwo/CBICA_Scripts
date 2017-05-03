#!/bin/bash

#This script runs flirt with 6 dof on a subject to a target (ideally same subject).

#TODO: Construct command by building a long string, so as to avoid using many if statements

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

This script runs flirt with 6 dof between an input and target

OPTIONS:
	-h show this message
	-i input path
	-r reference path
	-o output path
	-m Keep Transformation Matrix? (default no)

EOF
}

#Defaults
VERBOSE=0
OUTMAT=0

while getopts "hi:o:r:vm" OPTION
do
	case $OPTION in
		h)
			usage
			exit 1
			;;
		i)
			inPath=$OPTARG
			;;
		o)
			outPath=$OPTARG
			;;
		r)
			refPath=$OPTARG
			;;
		v)
			VERBOSE=1
			;;
		m)
			OUTMAT=1
			;;
		?)
			echo "Unrecognized Options. Exiting. " 1>&2      
			usage 1>&2
			exit 1
			;;
	esac
done

echoV "--->Input Arguments:"
echoV "In Path: ${inPath}"
echoV "Ref Path: ${refPath}"
echoV "Out Path: ${outPath}"

#Check for required input
if [ ! -f ${inPath} ] ||  [ ! -f ${refPath} ] || [ -z ${outPath} ] 
then
	echo "Error. Not all input found. Exiting." 1>&2
	usage 1>&2
	exit 1
fi

OUTDIR=$( dirname ${outPath} )
#If output directory doesn't exist, try to make it
if [ ! -d ${OUTDIR} ]
then
	echoV "--->Output directory not detected to exist. Making it now"
	mkdir ${OUTDIR}
	checkandexit $?
fi

#Make temporary directory
echoV "--->Creating Temporary Directory"
TMP=`mktemp -d --tmpdir=${CBICA_TMPDIR} `
checkandexit $?
echoV "--->Temporary Directory Created at ${TMP}"
checkandexit $?


if [ ${OUTMAT} -eq 0 ]
then
	/sbiasfw/external/fsl/4.1.5/bin/flirt \
		-in ${inPath} \
		-ref ${refPath} \
		-out ${outPath} \
		-searchcost mutualinfo \
		-cost mutualinfo \
		-dof 6 \
		-searchrx -30 +30 \
		-searchry -30 +30 \
		-searchrz -30 +30 \
		-coarsesearch 15 \
		-finesearch  6	

else
	bn=$( basename ${outPath} )
	bn=${bn%.nii.gz}
	bn=${bn%.hdr}

	/sbiasfw/external/fsl/4.1.5/bin/flirt \
		-in ${inPath} \
		-ref ${refPath} \
		-out ${outPath} \
		-omat ${OUTDIR}/${bn}.mat \
		-searchcost mutualinfo \
		-cost mutualinfo \
		-dof 6 \
		-searchrx -30 +30 \
		-searchry -30 +30 \
		-searchrz -30 +30 \
		-coarsesearch 15 \
		-finesearch 6 	

fi

