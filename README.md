# noseTipClassification
Using spin images and SVMs for nose tip classification


Code for classifiying the points for the 3D faces in the FRGCv2 dataset as whether they belong to the nose tip or not. The tip of the nose is an important location on the face. This 'landmark' location is useful for applications relating to face cropping, alignment, pose estimation and so on.

The code uses matlab to extract geometric features from 3D face points, called spin images, and classifies the local shape descriptor using Support Vector Machines. The task is that of binary classification  and achieves 91% accuracy on the defined test set.
