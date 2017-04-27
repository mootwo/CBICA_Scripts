#!/bin/bash

module unload BrainTumorModeling_CoupledSolver
module load BrainTumorModeling_CoupledSolver/1.2.1

module unload hopspack
module load hopspack/2.0.2

module unload itk
module load itk/4.7.0

module unload glistr
module load glistr/3.1.0

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



usage()
{
cat << EOF
usage: $0 OPTIONS

This script runs Glistr
-t /path/to/t1_image
-w /path/to/t2_image
-c /path/to/t1ce_image
-f /path/to/flair_image 
-s /path/to/glistr seed file
-p /path/to/glistr point file
-o /path/to/output directory (also sge log directory)
-h show this message


EOF
}


	

#parse command line arguments
while getopts "ht:w:c:f:s:p:o:" OPTION #TODO: Add verbose Option
do
	case $OPTION in
		h)
			usage
			exit 1
			;;
		t)
			t1_path=$OPTARG
			;;
		w)
			t2_path=$OPTARG
			;;
		c)
			t1ce_path=$OPTARG
			;;
		f)
			flair_path=$OPTARG
			;;
		s)
			seed_file=$OPTARG
			;;
		p)
			point_file=$OPTARG
			;;
		o)
			outDir=$OPTARG
			;;
		?)
			echo "Unrecognized Option"  1>&2      
			usage 1>&2
			exit 1
			;;
	esac
done



#check input arguments
if [ -z ${t1_path} ] || [ -z ${t2_path} ] || [ -z ${t1ce_path} ] || [ -z ${flair_path} ] || [ -z ${seed_file} ] || [ -z ${point_file} ]
then
	echo "ERROR: Not all required input found!"
	usage 1>&2
	exit 1
fi


argFlag=0
if [ ! -f ${t1_path} ]
then
	echo "ERROR: T1 Image Not Found!" 1>&2
	echo "T1 Path: ${t1_path}" 1>&2
	argFlag=1
fi

if [ ! -f ${t2_path} ]
then
	echo "ERROR: T2 Image Not Found!" 1>&2
	echo "T2 Path: ${t2_path}" 1>&2
	argFlag=1
fi

if [ ! -f ${t1ce_path} ]
then
	echo "ERROR: T1CE Image Not Found!" 1>&2
	echo "T1CE Path: ${t1ce_path}" 1>&2
	argFlag=1
fi

if [ ! -f ${flair_path} ]
then
	echo "ERROR: Flair Image Not Found!" 1>&2
	echo "Flair Path: ${flair_path}" 1>&2
	argFlag=1	
fi

if [ ! -f ${seed_file} ]
then
	echo "ERROR: Seed File Not Found!" 1>&2
	echo "Point File Path: ${seed_file}" 1>&2
	argFlag=1	
fi

if [ ! -f ${point_file} ]
then
	echo "ERROR: Point File Not Found!" 1>&2
	echo "Point File Path: ${point_file}" 1>&2
	argFlag=1	
fi


if [ ! ${argFlag} -eq 0 ]
then
	echo "ERROR: Not all input found" 1>&2
	usage
	exit 1
fi



#print input arguments
echo "INPUT ARGUMENTS"
echo "T1 Image: ${t1_path}"
echo "T2 Image: ${t2_path}"
echo "T1ce Image: ${t1ce_path}"
echo "Flair Image: ${flair_path}"
echo "Glistr Seed File: ${seed_file}"
echo "Glistr Point File: ${point_file}"
echo "Output Directory: ${outDir}"



echo "---->	Creating Output Directory"
if [ ! -d ${outDir} ]
then
	mkdir ${outDir}
	checkandexit $?
fi


#Making Temporary Direcotry
echo "--->Creating Temporary Directory"
TMP=`mktemp -d --tmpdir=${SBIA_TMPDIR} `
checkandexit $?
echo "--->Temporary Directory Created at ${TMP}"


#set up directory to run glistr from
echo "---->	Setting Up Directory and files to run glistr"
g_baseDir=${TMP}/glistr
mkdir ${g_baseDir}
checkandexit $?

#prepare glistr output directory
g_outDir=${g_baseDir}/glistrOut
mkdir ${g_outDir}
checkandexit $?

#copy necessary files to glistr base directory and generate features file
echo "----> Copying Files To Temp Dir"
seed_name=${seed_file##*/}
cp ${seed_file} ${g_baseDir}/${seed_name}
checkandexit $?

point_name=${point_file##*/}
cp ${point_file} ${g_baseDir}/${point_name}
checkandexit $?

#T1
t1_name=$( basename ${t1_path} )
cp ${t1_path}  ${g_baseDir}/${t1_name}
checkandexit $?
echo ${t1_name} > ${g_baseDir}/features.lst
checkandexit $?

#T1CE
t1ce_name=$( basename ${t1ce_path} )
cp ${t1ce_path}  ${g_baseDir}/${t1ce_name}
checkandexit $?
echo ${t1ce_name} >> ${g_baseDir}/features.lst
checkandexit $?

#T2
t2_name=$( basename ${t2_path} )
cp ${t2_path}  ${g_baseDir}/${t2_name}
checkandexit $?
echo ${t2_name} >> ${g_baseDir}/features.lst
checkandexit $?

#FLAIR
flair_name=$( basename ${flair_path} )
cp ${flair_path}  ${g_baseDir}/${flair_name}
checkandexit $?
echo ${flair_name} >> ${g_baseDir}/features.lst
checkandexit $?

echo "---->	Running Glistr"
 GLISTR \
	--featureslist ${g_baseDir}/features.lst \
	--seed_info ${g_baseDir}/${seed_name} \
	--point_info ${g_baseDir}/${point_name} \
	--atlas_folder atlas_jakob_with_cere_type --num_omp_threads 3 --num_itk_threads 3 --num_hop_threads 1 \
	--outputdir ${g_outDir} 
checkandexit $?


#the function called here checks glistr output files for corruption
outFile=${g_outDir}/scan_label_map.nii.gz
if [ ! -f ${outFile} ]
then
	echo "Error! Glistr Output Not Detected! Exiting" 1>&2
	exit 1
fi

echo "---->	Glistr Completed"
echo "----> Copying Files to Output Directory"
cp -r ${g_outDir}/* ${outDir}
checkandexit $?


echo "----> Removing Temporary Directory"
rm -rf ${TMP}
checkandexit $?



