#!/usr/bin/env bash


usage()
{
cat << EOF
usage: $0 OPTIONS

This Program Converts dicom images to nifti using dcm2nii
-i /path/to/input/directory
-o /path/to/output directory (also sge log directory)
-v Verbose
-h show this message


EOF
} 


echoV()
{
	if [ ${VERBOSE} -eq 1 ]
	then
		echo $1
	fi
}

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

#Defaults
VERBOSE=0

#parse command line arguments
while getopts "hi:o:v" OPTION
do
	case $OPTION in
		h)
			usage
			exit 1
			;;
		i)
			inDir=$OPTARG
			;;
		o)
			outDir=$OPTARG
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
echoV "	   --->inDir:",${inDir}
echoV "    --->outDir:",${outDir}

#Check for Input
if [ -z ${inDir} ] || [ -z ${outDir} ]
then
	echo "Input Arguments Not Detected! Exiting!" 1>&2
	usage 1>&2
	exit 1
fi

#Check Suffix of Dicom Files
echoV "--->Checking Suffix of Dicom Files"
file=`command ls -1 ${inDir}/* | egrep -v ".csv|.txt|.log|.xml"`
checkandexit $?
ext=${file##*.}
#If not one of the two most common file extensions, should have no extension
if [ ! "${ext}" = "dcm" ] && [ ! "${ext}" = "bz2" ]
then
	ext=
	echoV "--->No File Extension Detected"
else
	echoV "--->File Extension: ${ext}"
fi


#Make temporary directory
echoV "--->Creating Temporary Directory"
TMP=`mktemp -d --tmpdir=${SBIA_TMPDIR} `
checkandexit $?
echoV "--->Temporary Directory Created at ${TMP}"

echoV "--->Copying Dicom Files to Temporary Directory"
cp ${inDir}/* ${TMP}
checkandexit $?

echoV "--->Checking if dicom files are compressed"
if [ "${ext}" = "bz2" ]
then
	echoV "--->Files are Corempressed. Decompressing"
	bunzip2 ${TMP}/*
	checkandexit $?
fi

echoV "--->Converting Dicoms"
mkdir ${TMP}/Nifti
checkandexit $?
/cbica/software/external/mricron/7.7.12/dcm2nii \
	-r N \
	-o ${TMP}/Nifti \
	${TMP}/*
checkandexit $?

echoV "--->Conversion Completed."
echoV "--->Converted Files:"
if [ ${VERBOSE} -eq 1 ]
then
	for f in `command ls -1t ${TMP}/Nifti/*`
	do
		echo "	--->$(basename ${f})"
	done
fi

echoV "--->Copying Output Files to Destination Directory"
for f in `command ls -1t ${TMP}/Nifti/*`
do
	echo ${f}
done | xargs -I SOURCE cp SOURCE ${outDir} 
checkandexit $?

echoV "--->Removing Temporary Direotory"
if [ ${VERBOSE} -eq 1 ]
then
	rm -rfv ${TMP}/*
	checkandexit $?
else
	rm -rf ${TMP}/*
	checkandexit $?
fi


	
