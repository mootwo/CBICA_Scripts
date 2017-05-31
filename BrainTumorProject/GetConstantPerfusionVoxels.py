#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Created on Tue May 30 13:22:05 2017

@author: RozyckiM
"""


import os, sys
import numpy as np
#sys.path.append('/mnt/sbiasfw/external/python/canopy/2.7.9/Canopy_64bit/User/lib/python2.7/site-packages/')
import nibabel as nb
import getopt

 
 
def findConstantVoxels(inPath,refPath,outDir):
    
    #Read nifti file
    print "Loading input nifti files"
    inNifti = nb.nifti1.load(inPath)
    refNifti = nb.nifti1.load(refPath) #The refernce image that perfusion is registered to.
    refImage = refNifti.get_data()
    #Need to reshape data to have a vector at every timepoint
    I = inNifti.get_data() #Need to flatten, since each voxel counts as a sample
    N = len(np.ravel(I[:,:,:,0]))
    numT = I.shape[3]
    inArray = np.zeros([N,numT]) #The timepoints are the features. We will reduce these to 5 or so.
    
    for t in range(numT):
        inArray[:,t] = np.ravel(I[:,:,:,t])
    
    outArray = np.zeros_like(inArray[:,0])
    stdArray = np.std(inArray,axis=1) #Take standard deviation along columns ,which are timepoints
    constVox = np.where( (stdArray == 0)  & ~(inArray[:,0] == 0) )
    outArray[constVox] = 1
    
    
    
    
    #Now write out nifti for first 5 components
    bn=os.path.basename(inPath)
    bn = bn.replace('.nii.gz','')
    
    #Should load header of t1ce image
    outImage = nb.nifti1.Nifti1Image(outArray.reshape(refImage.shape),refNifti.affine,header=refNifti.header)
    nb.nifti1.save(outImage,outDir + '/' + bn + '_constVox.nii.gz')
    
    
    return 0






def parseArguments(arguments):
	print "arguments:",arguments
	try:
		opts, args = getopt.getopt(arguments,"i:r:o:")
	except getopt.GetoptError as err:
	    	print str(err) # will print something like "option -a not recognized"
       		sys.exit(2)

	for o,a in opts:
         if o == "-i":
             inputImage = a
         elif o == "-r":
             refImage = a
         elif o == "-o":
             outputDir = a 				
         else:
             assert False, "unhandled option"

	return inputImage,refImage,outputDir



if __name__ == '__main__':

     I,R,O = parseArguments(sys.argv[1:])
     print "inputImage:",I
     print "refImage:",R
     print "outputDir:",O


     findConstantVoxels(I,R,O)
