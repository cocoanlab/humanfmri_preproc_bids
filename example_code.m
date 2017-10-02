codedir = '/Users/clinpsywoo/github/humanfmri_preproc_bids';
addpath(codedir);

study_imaging_dir = '/Users/clinpsywoo/Dropbox/projects/ongoing_projects/preproc_pipeline/CAPS2_preproc_test/Imaging';
subject_code = 'caps001';
subject_dir = fullfile(study_imaging_dir, subject_code);

func_run_nums = [1 1 2 2 3 3 4 4];
disdaq_n = [20 0 20 0 20 0 20 0];

func_tasks = {'CAPS', 'CAPS_sbref', 'QUIN', 'QUIN_sbref', 'REST', 'REST_sbref', 'ODOR', 'ODOR_sbref'};

%% 1. Make directories
humanfmri_1_make_directories(subject_code, study_imaging_dir, 'func_run_nums', func_run_nums,  'func_tasks', func_tasks);

%% 2. Dicom to nifti: structural

humanfmri_2_structural_dicom2nifti_bids(subject_dir);

%%
humanfmri_3_functional_dicom2nifti_bids(subject_dir, disdaq_n);



