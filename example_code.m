% datdir = '/Volumes/habenula/hbmnas/data/Pain_Sound_test';
codedir = '/Users/clinpsywoo/github/humanfmri_preproc_bids';
addpath(codedir);

study_imaging_dir = '/Users/clinpsywoo/Dropbox/projects/ongoing_projects/preproc_pipeline/CAPS2_preproc_test/Imaging';
subject_code = 'caps001';
func_run_nums = [1 1 2 2 3 3 4 4];
func_tasks = {'CAPS', 'CAPS_sbref', 'QUIN', 'QUIN_sbref', 'REST', 'REST_sbref', 'ODOR', 'ODOR_sbref'};

%% 1. Make directories
PREPROC = humanfmri_1_make_directories(subject_code, study_imaging_dir, 'func_run_nums', func_run_nums,  'func_tasks', func_tasks);


%% 2. Dicom to nifti

humanfmri_structural_1_dicom2nifti(subject_dir);
humanfmri_functional_1_dicom2nifti(subject_dir, 1:4, 22);

%%

% HCP distortion correction

PREPROC = humanfmri_functional_2_implicitmask_savemean(subject_dir, 1:4);

PREPROC = humanfmri_structural_2_coregistration(subject_dir);

% humanfmri_structural_3_reorientation(subject_dir)

PREPROC = humanfmri_structural_5_segment(subject_dir, 'woreorient')