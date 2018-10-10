# High_Variance_Objects

Experiment used a subset of Seibert et al 2016 (BioRxiv) stimuli of highly variable object category images. Main part of analysis uses Linear Discriminant analysis to decode presented image from EEG data. Categories used: animals, boats, cars, chairs, faces, fruit, planes, tables. Stimuli were presented at three rates: 1Hz, 2Hz, 4Hz, to compare the effect of presentation length.

HighVarObjs_rsa.mat is the main analysis script - produces confusion matrices.

prepare_highvarobjs_data.m turns xDiva EEG matlab files to a format usable by the MatclassRSA toolbox used to train and test the machine learning classificatoin algorithm.