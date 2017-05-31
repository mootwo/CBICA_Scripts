# -*- coding: utf-8 -*-
"""
Created on Wed May 10 12:57:22 2017

Quick calculation of mahalanobis distance on randomly generated feature vectors.
I want to see whether the number of low values decreases as the dimensionality increases?

@author: RozyckiM
"""

import numpy as np
from scipy.spatial.distance import mahalanobis

#Let's go from 3 to 100 features and see how mahalanobis distribution changes
nRange = np.arange(3,110,10)
X = np.zeros([1000,len(nRange)])
count = 0 
for n in nRange:
    print n
    inputArray = np.random.normal(size=[1000,n])
    
    cov = np.cov(np.transpose(inputArray))
    mean = np.mean(inputArray,axis=0)
    covInv = np.linalg.inv(cov)
    distPure = np.empty(len(inputArray))
    for i in range(len(inputArray)):
        #distPure[i] = mahalanobis(inputArray[i,:],mean,covInv)
        distPure[i] = np.linalg.norm(inputArray[i,:] - mean)
        
    X[:,count] = distPure
    count = count + 1
        
        
plt.boxplot(X)