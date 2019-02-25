%% NAS addpath
addpath(genpath('/cocoanlab/Resources/github_nas'));

%% SETUP(1): Set run numbe, task names, and number of disdaq (Usually same for the every subject)
func_run_nums = [1 2 3 4 5 6 7];
run_n = length(func_run_nums);
func_tasks = {'FT', 'Story', 'Story', 'Story', 'Story', 'Story', 'FT'};
disdaq_n = repmat(18, 1, run_n); %(number of TR, 1, number of run);

%% SETUP(2): Making directory and subject code
study_imaging_dir = '/Volumes/wissen/hbmnas/data/PiCo/imaging';

subj_idx = [10, 24, 27:31]; % [1:34, 43:54] or [2,3,4, 5, 21];
projName = 'pico'; % project name
[preproc_subject_dir, subject_code] = make_subject_dir_code(study_imaging_dir, projName,subj_idx);

num_sub = length(subject_code);
%% A. BIDS dicom to nifti =================================================
% PART A: --------------------
% 1. dicom to nifti: bids
% 2. bids validation
% ----------------------------

% You can make these as a loop for multiple subjects

%% A-1. Make directories
for i=1:num_sub
    humanfmri_a1_make_directories(subject_code{1,i}, study_imaging_dir, func_run_nums, func_tasks);
end

% After this command, you have to move the directories that contain dicom files 
% into the corresponding directories. 

%% Move Directories
addpath('/Volumes/wissen/hbmnas/data/PiCo/imaging/preproc_script')
for i = 1:num_sub
    move_dicom_to_raw(subject_code{1,i}, study_imaging_dir, run_n);
end

%% A-2. Dicom to nifti: structural and functional 
d=datetime('now');

for i=1:num_sub
    % A-2. Dicom to nifti: anat(T1)
    
    humanfmri_a2_structural_dicom2nifti_bids(subject_code{1,i}, study_imaging_dir);
    
    % A-3. Dicom to nifti: functional(Run 1~9)
    
    %humanfmri_a3_functional_dicom2nifti_bids(subject_code, study_imaging_dir, disdaq_n);
    humanfmri_a3_functional_dicom2nifti_bids(subject_code{1,i}, study_imaging_dir, disdaq_n, 'no_check_disdaq');
    
    % A-4. Dicom to nifti: fmap(Distortion correction)
    
    %humanfmri_a4_fieldmap_dicom2nifti_bids(subject_code, study_imaging_dir);
    humanfmri_a4_fieldmap_dicom2nifti_bids(subject_code{1,i}, study_imaging_dir);
    
    d=[d datetime('now')];
end
%% Done with A Part =======================================================

% You can use the following tools

% BIDS-validator: http://incf.github.io/bids-validator/ in chrome
% Fmriprep (preprocessing tool): see http://fmriprep.readthedocs.io/en/stable/

%% B. COCOANLAB PREPROC

% PART B: --------------------
% 3. disdaq & visualization/qc (canlab)
% 4. motion correction (realignment) 
% 5. EPI normalization 
% 6. Smoothing
% 7. ICA-AROMA 
% ----------------------------

%% PART3: 
% d=datetime('now')

% B-1. Preproc directories

humanfmri_b1_preproc_directories(subject_code, study_imaging_dir); %'forced_save', 'no_save'

%% B-2. Implicit mask and save means

humanfmri_b2_functional_implicitmask_savemean(preproc_subject_dir);

%% B-3. Spike id
humanfmri_b3_spike_id(preproc_subject_dir);

%%
% B-4. Slice timing correction if needed: You can skip this if TR is short enough

% tr = .46;
% mbf = 8;
% 
% humanfmri_b4_slice_timing(preproc_subject_dir, tr, mbf);

%% B-5. Motion correction

use_st_corrected_data = false;
use_sbref = true;
humanfmri_b5_motion_correction(preproc_subject_dir, use_st_corrected_data, use_sbref);

%% B-6. distortion correction    
epi_enc_dir = 'ap';
use_sbref = true;
humanfmri_b6_distortion_correction(preproc_subject_dir, epi_enc_dir, use_sbref, 'run_num', 1:7)

%% PART 4
% B-7. coregistration (spm_check_registration.m)

use_sbref = true;
humanfmri_b7_coregistration(preproc_subject_dir, use_sbref);
%humanfmri_b7_coregistration(preproc_subject_dir, use_sbref, 'no_check_reg');

%% B-8-1. T1 Normalization

use_sbref = true;
humanfmri_b8_normalization(preproc_subject_dir, use_sbref);
% humanfmri_b8_normalization(preproc_subject_dir, use_sbref, 'no_check_reg');

%% B-10. Smoothing

humanfmri_b9_smoothing(preproc_subject_dir);

%% Step C: Check Framewise Displacement and make Nuisance Regressors

% humanfmri_c1_move_clean_files
% C-2
humanfmri_c2_get_framewise_displacement(preproc_subject_dir)

%% C-3
humanfmri_c3_make_nuisance_regressors(preproc_subject_dir)
%make_nuisance_regressors(PREPROC,'regressors',{'24Move','Spike','WM_CSF'})
%make_nuisance_regressors(PREPROC,'img','swr_func_bold_files')
%% DONE %%