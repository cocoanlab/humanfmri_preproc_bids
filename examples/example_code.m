scriptdir = '/Users/clinpsywoo/github/humanfmri_preproc_bids';
addpath(scriptdir);

study_imaging_dir = '/Users/clinpsywoo/Dropbox/projects/ongoing_projects/preproc_pipeline/CAPS2_preproc_test/Imaging';
subject_code = {'sub-caps003'};
% multiple subjects: 
% subject_code = {'sub-caps001', 'sub-caps002', 'sub-caps003', 'sub-caps004'};

% run numbers and task names
func_run_nums = [1 2 3 4]; 
func_tasks = {'CAPS', 'QUIN', 'REST', 'ODOR'};
disdaq_n = [20 20 20 20];

% preproc_subject_dir = fullfile(study_imaging_dir, 'preprocessed', subject_code);


%% A. BIDS dicom to nifti =================================================

% PART A: --------------------
% 1. dicom to nifti: bids
% 2. bids validation
% ----------------------------

% You can make these as a loop for multiple subjects

%% A-1. Make directories

humanfmri_a1_make_directories(subject_code, study_imaging_dir, func_run_nums, func_tasks);

% After this command, you have to move the directories that contain dicom files 
% into the corresponding directories. 

%% A-2. Dicom to nifti: structural

humanfmri_a2_structural_dicom2nifti_bids(subject_code, study_imaging_dir);

%% A-3. Dicom to nifti: functional

humanfmri_a3_functional_dicom2nifti_bids(subject_code, study_imaging_dir, disdaq_n);

%% A-4. Dicom to nifti: fmap

humanfmri_a4_fieldmap_dicom2nifti_bids(subject_code, study_imaging_dir);

%% Done with A Part =======================================================

% You can use the following tools

% BIDS-validator: http://incf.github.io/bids-validator/ in chrome
% Fmriprep (preprocessing tool): see http://fmriprep.readthedocs.io/en/stable/

%% B. COCOANLAB PREPROC

% PART B: --------------------
% 3. disdaq & visualization/qc (canlab)
% 4. motion correction (realignment) 
% 5. distortion correction
% 6. EPI normalization 
% 7. Smoothing
% ***(needs to be tested)***8. ICA-AROMA
% ----------------------------

%% B-1. Preproc directories

preproc_subject_dir = humanfmri_b1_preproc_directories(subject_code, study_imaging_dir);


%% B-2. Implicit mask and save means

humanfmri_b2_functional_implicitmask_savemean(preproc_subject_dir);

%% B-3. Spike id

humanfmri_b3_spike_id(preproc_subject_dir);

%% B-4. Slice timing correction if needed: You can skip this if TR is short enough

% tr = .46;
% mbf = 8;
% 
% humanfmri_b4_slice_timing(preproc_subject_dir, tr, mbf);

%% B-5. Motion correction

use_st_corrected_data = false;
use_sbref = true;
humanfmri_b5_motion_correction(preproc_subject_dir, use_st_corrected_data, use_sbref);

%% B-6. HCP distortion correction

epi_enc_dir = 'ap';
humanfmri_b6_distortion_correction(preproc_subject_dir, epi_enc_dir, use_sbref);

%% B-7. coregistration (spm_check_registration.m)

humanfmri_b7_coregistration(preproc_subject_dir, use_sbref);
% no check registration
% humanfmri_b7_coregistration(preproc_subject_dir, use_sbref, 'no_check_reg');

%% B-8. T1 Normalization

humanfmri_b8_normalization(preproc_subject_dir, use_sbref);
% no check registration
% humanfmri_b8_normalization(preproc_subject_dir, use_sbref, 'no_check_reg');

%% B-9. Smoothing

humanfmri_b9_smoothing(preproc_subject_dir);

%% B-10. ICA-AROMA

humanfmri_b10_ICA_AROMA(preproc_subject_dir);



