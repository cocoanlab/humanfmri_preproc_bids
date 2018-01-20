# Cocoprep v1.0: [Cocoanlab](https://cocoanlab.github.io)'s fMRI data preprocessing pipeline

This repository includes a set of matlab functions for fMRI data preprocessing. Currently, this includes tools for a) dicom to nifti in the BIDS ([Brain Imaging Data Structure](http://bids.neuroimaging.io)) format, using [dicm2nii](https://www.mathworks.com/matlabcentral/fileexchange/42997-dicom-to-nifti-converter--nifti-tool-and-viewer) (which has been a little bit modified, and therefore it is included in this toolbox), b) distortion correction using [fsl](https://fsl.fmrib.ox.ac.uk)'s [topup](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/topup), c) outlier detection and data quality check using some useful [Canlab](http://wagerlab.colorado.edu/) tools ([github](https://github.com/canlab)), d) slice-timing, realignment, T1 (default) or EPI normalization, and smoothing using SPM12 tools, and e) a recent tool for motion correction, [ICA-AROMA](https://github.com/rhr-pruim/ICA-AROMA).



## Installation
	
You can download this github repository using the following command line. 

	$ git clone https://github.com/cocoanlab/humanfmri_preproc_bids

## Dependency

1. Canlab Core: [https://github.com/canlab/CanlabCore](https://github.com/canlab/CanlabCore)
2. dicm2nii.m: ([link](https://www.mathworks.com/matlabcentral/fileexchange/42997-dicom-to-nifti-converter--nifti-tool-and-viewer)): We modified the original toolbox a little bit to make the output data fully BIDS-compatible. For this reason, please use the dicm2nii toolbox in our repository (in /external), instead of the original one. 
3. FSL: [https://fsl.fmrib.ox.ac.uk](https://fsl.fmrib.ox.ac.uk)
4. SPM12: [http://www.fil.ion.ucl.ac.uk/spm/software/spm12](http://www.fil.ion.ucl.ac.uk/spm/software/spm12)
5. ICA-AROMA: [https://github.com/rhr-pruim/ICA-AROMA](https://github.com/rhr-pruim/ICA-AROMA)
6. Anaconda: [https://www.anaconda.com/download/#macos](https://www.anaconda.com/download/#macos)

## Getting started

There are two example codes that might be helpful for you to start with.

- example\_code.m (Wani made it)
- example\_CAPS2.m (Jaejoong made it for his study)


## Contributors (so far)

- [Choong-Wan (Wani) Woo](https://github.com/wanirepo) (cocoanlab, director) 
- [Jaejoong Lee](https://github.com/jaejoonglee92) (cocoanlab, grad student)
- [Catherine Cho](https://github.com/naturalcici) (cocoanlab, postdoc)


## Notes

<br>

- This repository is not fully tested yet. At least, it works well in our computer environment and fmri data sqeuence and structure. However, it doesn't mean that this tool should work for your data and your computational environment. 
- The main target users of this toolbox are cocoan lab people, but we're sharing our codes publicly anyway because this tool could be helpful for other labs and people. If you see bugs or issues in our code, please feel free to let us know. We will do our best to resolve the issues, but cannot guarantee to solve all the issues (given that we are a small lab). If you can contribute to the code, that would also be great. Thanks!!

<br> 
Main strengths of this toolbox:

- This toolbox works well with a large number of images (when we tested heudiconv and bidskit on our dataset a while ago, dcm2niix (in python) was failed because of the size of our data (2600 images per run), but dicm2nii.m works fine. 
- This toolbox includes some useful steps from the CANlab preprocessing pipeline.
- You can run distortion correction (using fsl's topup) and ICA-AROMA in matlab. We couldn’t test ICA-AROMA fully yet, but it seems running well. We couldn’t finish the testing because the current data were too big (2600 images per run) to run ICA on it. 
- EPI norm: You can run direct EPI normalization to mni with our tool (see Calhoun et al, 2017, *Human Brain Mapping*). One thing I should note is that for the mni template, we’re using spm12's TPM.nii because we found it works much better than using old EPI.nii. You can also run T1 norm as well (it's default). 
- Flexible slice timing: the current tools works for Multiband data, and also you can easily skip that part, if you want.


