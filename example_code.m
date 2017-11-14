% codedir = '/Users/clinpsywoo/github/humanfmri_preproc_bids';
% imac
codedir = '/Users/clinpsywoo/Nas/Resource/github_nas/cocoanlab/humanfmri_preproc_bids';
addpath(codedir);

study_imaging_dir = '/Users/clinpsywoo/Dropbox/projects/ongoing_projects/preproc_pipeline/CAPS2_preproc_test/Imaging';
subject_code = 'sub-caps003';
subject_dir = fullfile(study_imaging_dir, 'raw', subject_code);

func_run_nums = [1 2 3 4];
disdaq_n = [20 20 20 20];

func_tasks = {'CAPS', 'QUIN', 'REST', 'ODOR'};

%% 1. Make directories

humanfmri_1_make_directories(subject_code,study_imaging_dir, 'func_run_nums', func_run_nums,  'func_tasks', func_tasks);

%% 2. Dicom to nifti: structural

humanfmri_2_structural_dicom2nifti_bids(subject_dir);

%% 3. Dicom to nifti: functional

humanfmri_3_functional_dicom2nifti_bids(subject_dir, disdaq_n);

%% 4. Dicom to nifti: fmap

humanfmri_4_fieldmap_dicom2nifti_bids(subject_dir);

%% Done with bids

%% HCP distortion correction

humanfmri_5_distortion_correction(subject_dir);

PREPROC = humanfmri_functional_2_implicitmask_savemean(subject_dir, 1:4);

PREPROC = humanfmri_structural_2_coregistration(subject_dir);

% humanfmri_structural_3_reorientation(subject_dir)

PREPROC = humanfmri_structural_5_segment(subject_dir, 'woreorient')