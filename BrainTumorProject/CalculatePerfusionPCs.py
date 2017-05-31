#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Created on Fri Apr  7 13:09:39 2017

@author: RozyckiM
"""

import os, sys
import numpy as np
from sklearn.decomposition import PCA
#sys.path.append('/mnt/sbiasfw/external/python/canopy/2.7.9/Canopy_64bit/User/lib/python2.7/site-packages/')
import nibabel as nb
import getopt

 
 
def run_PCA_Perfusion(inPath,refPath,outDir):
    
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
    
    print "Running PCA"
    p = PCA(n_components=5 )
    p.fit(inArray) #Calculate principal components
    outArray = p.fit_transform(inArray) #Our original data projected onto the new components
    
    #Now write out nifti for first 5 components
    bn=os.path.basename(inPath)
    bn = bn.replace('.nii.gz','')
    
    for i in range(5):
        #Should load header of t1ce image
        outImage = nb.nifti1.Nifti1Image(outArray[:,i].reshape(refImage.shape),refNifti.affine,header=refNifti.header)
        nb.nifti1.save(outImage,outDir + '/' + bn + '_PCA_' + str(i) + '.nii.gz')
    
    
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


     run_PCA_Perfusion(I,R,O)
