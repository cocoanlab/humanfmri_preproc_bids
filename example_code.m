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

%% A. BIDS dicom to nifti =================================================

%% A-1. Make directories

humanfmri_a1_make_directories(subject_code, study_imaging_dir, 'func_run_nums', func_run_nums,  'func_tasks', func_tasks);

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
% 5. EPI normalization  (EPI -> EPI mni)
% 6. Smoothing
% 7. ICA-AROMA
% 8. temporal filtering (hpf/bpf, etc.)
% ----------

%% B-1. Preproc directories

preproc_subject_dir = humanfmri_b1_preproc_directories(subject_code, study_imaging_dir);


%% B-1. HCP distortion correction

epi_enc_dir = 'ap';
humanfmri_b2_distortion_correction(preproc_subject_dir, epi_enc_dir)

%%

PREPROC = humanfmri_functional_2_implicitmask_savemean(subject_dir, 1:4);

PREPROC = humanfmri_structural_2_coregistration(subject_dir);

% humanfmri_structural_3_reorientation(subject_dir)

PREPROC = humanfmri_structural_5_segment(subject_dir, 'woreorient')