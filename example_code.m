% macbook
codedir = '/Users/clinpsywoo/github/humanfmri_preproc_bids';
% imac
% codedir = '/Users/clinpsywoo/Nas/Resource/github_nas/cocoanlab/humanfmri_preproc_bids';
addpath(codedir);

study_imaging_dir = '/Users/clinpsywoo/Dropbox/projects/ongoing_projects/preproc_pipeline/CAPS2_preproc_test/Imaging';
subject_code = {'sub-caps003'};

func_run_nums = [1 2 3 4];
disdaq_n = [20 20 20 20];

func_tasks = {'CAPS', 'QUIN', 'REST', 'ODOR'};

% preproc_subject_dir = fullfile(study_imaging_dir, 'preprocessed', subject_code);

%% A. BIDS dicom to nifti =================================================

%% A-1. Make directories

humanfmri_a1_make_directories(subject_code, study_imaging_dir, func_run_nums, func_tasks);

%% A-2. Dicom to nifti: structural

humanfmri_a2_structural_dicom2nifti_bids(subject_code, study_imaging_dir);

%% A-3. Dicom to nifti: functional

humanfmri_a3_functional_dicom2nifti_bids(subject_code, study_imaging_dir, disdaq_n);

%% A-4. Dicom to nifti: fmap

humanfmri_a4_fieldmap_dicom2nifti_bids(subject_code, study_imaging_dir);

%% Done with A Part =======================================================

% BIDS-validator: http://incf.github.io/bids-validator/ in chrome

% Fmriprep: see http://fmriprep.readthedocs.io/en/stable/

%% B. COCOANLAB PREPROC: using EPI-NORM/SPM

% Proposed pipeline
% ----------
% 1. dicom to bids
% 2. bids validation
% 3. disdaq & visualization/qc (canlab) - snr, plot, spike_id (html) 
% 4. motion correction (realignment) - (Inrialign??)
% 5. EPI normalization  (EPI -> TPM mni)
% 6. Smoothing
% 7. ICA-AROMA
% ----------


%% B-1. Preproc directories

preproc_subject_dir = humanfmri_b1_preproc_directories(subject_code, study_imaging_dir);


%% B-2. HCP distortion correction

epi_enc_dir = 'ap';
do_sbref = 1;
humanfmri_b2_distortion_correction(preproc_subject_dir, epi_enc_dir, do_sbref);

%% B-3. Implicit mask and save means

humanfmri_b3_functional_implicitmask_savemean(preproc_subject_dir);

%% B-4. Spike id

humanfmri_b4_spike_id(preproc_subject_dir);

%% B-5. Slice timing correction if needed: You can skip this if TR is short enough

% tr = .46;
% mbf = 8;
% 
% humanfmri_b5_slice_timing(preproc_subject_dir, tr, mbf);


%% B-6. Motion correction

use_st_corrected_data = 0;
humanfmri_b6_motion_correction(preproc_subject_dir, use_st_corrected_data);

%% B-7. EPI Normalization

use_sbref = 1;
humanfmri_b7_EPI_normalization(preproc_subject_dir, use_sbref);

%% B-8. Smoothing

humanfmri_b8_smoothing(preproc_subject_dir);

%% B-9. ICA-AROMA

humanfmri_b9_ICA_AROMA(preproc_subject_dir);

%% B-10. Move and clean files 

humanfmri_b10_move_clean_files(preproc_subject_dir);



