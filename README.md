# Cocoprep v1.0: [Cocoanlab](https://cocoanlab.github.io)'s fMRI data preprocessing pipeline

This repository includes a set of matlab functions for fMRI data preprocessing. Currently, this includes tools for a) dicom to nifti in the BIDS ([Brain Imaging Data Structure](http://bids.neuroimaging.io)) format, using [dicm2nii](https://www.mathworks.com/matlabcentral/fileexchange/42997-dicom-to-nifti-converter--nifti-tool-and-viewer) (which has been a little bit modified, and therefore it is included in this toolbox), b) distortion correction using [fsl](https://fsl.fmrib.ox.ac.uk)'s [topup](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/topup), c) outlier detection and data quality check using some useful [Canlab](http://wagerlab.colorado.edu/) tools ([github](https://github.com/canlab)), d) slice-timing, realignment, EPI normalization, and smoothing using SPM12 tools, and e) a recent tool for motion correction, [ICA-AROMA](https://github.com/rhr-pruim/ICA-AROMA).

<br>

**Note: This repository is not fully tested yet. At least, it works well in our computer environment and fmri data sqeuence and structure. However, it doesn't mean that this tool should work for your data and your computational environment. The main target users of this toolbox are cocoan lab people, but we're making this public because we thought that this tool might be helpful for others. If you see bugs or issues in our code, please feel free to let us know. We will do our best to solve the issues, but cannot guarantee to solve all the issues (given that we are a small lab). If you can contribute to the code, that would also be great. Thanks!!

## Installation
	
You can download this github repository using the following command line. 

	$ git clone https://github.com/cocoanlab/humanfmri_preproc_bids

## Dependency

1. Canlab Core [https://github.com/canlab/CanlabCore](https://github.com/canlab/CanlabCore)
2. FSL [https://fsl.fmrib.ox.ac.uk](https://fsl.fmrib.ox.ac.uk)
3. SPM12 [http://www.fil.ion.ucl.ac.uk/spm/software/spm12](http://www.fil.ion.ucl.ac.uk/spm/software/spm12)
4. ICA-AROMA [https://github.com/rhr-pruim/ICA-AROMA](https://github.com/rhr-pruim/ICA-AROMA)

## Getting started

There are two example codes that might be helpful for you to start with.

example\_code.m (Wani made it)
example\_CAPS2.m (Jaejoong made it for his study)


## Contributors (so far)

[Choong-Wan (Wani) Woo](https://github.com/wanirepo) (cocoanlab, director) 
[Jaejoong Lee](https://github.com/jaejoonglee92) (cocoanlab, grad student)
[Catherine Cho](https://github.com/naturalcici) (cocoanlab, postdoc)





