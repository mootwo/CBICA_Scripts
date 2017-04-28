#!/bin/bash

checkandexit()
{
        # Check the supplied value, typically the return value from the
        # previous command. If the return value is not 0, then print a 
        # message to STDERR and exit.

        if [ $1 != 0 ] ; then
                # There was an error, bail out!
                /bin/echo "$2" 1>&2
                echo "$2"
                exit $1
        fi
}

#Checks whether two images  are idenitcal in content, not necessarily in header. Returns 0 if subtraction
#yields no differences
checkVolumes()
{
file1=$1
file2=$2

TMP=`mktemp -d --tmpdir=${SBIA_TMPDIR} `

3dcalc -a ${file1} -b ${file2} -prefix ${TMP}/diff.nii.gz -expr 'a-b'

n=`3dBrickStat -non-zero -count ${TMP}/diff.nii.gz`
if [ ${n} -eq 0 ]
then
	return 0
else
	return 1
fi

rm -rf ${TMP}

}

