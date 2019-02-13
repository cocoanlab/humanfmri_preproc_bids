%% SETUP: Path
study_imaging_dir = '/Volumes/sein/hbmnas/data/SEMIC/imaging'; % In sein
path_github_toolbox{1} = fullfile('/Volumes/sein/github','canlab');
path_github_toolbox{2} = fullfile('/Volumes/sein/github','cocoanlab'); % for dicm2nii, should add cocoanlab later than canlab
path_github_toolbox{3} = fullfile('/Volumes/sein/github','external_toolbox/spm12');
%including canlab tool and cocoan tool, % but it is not recommended 
for path_i = 1:length(path_github_toolbox); addpath(genpath(path_github_toolbox{path_i})); end
%% SETUP: preproc_subject_dir and subject code 
subj_idx = 1:59; % [1:34, 43:54] or [2,3,4, 5, 21];
projName = 'semic'; % project name
[preproc_subject_dir, subject_code] = make_subject_dir_code(study_imaging_dir, projName,subj_idx);
%% SETUP: run numbers and task names
func_run_nums = [1 2 3 4 5 6 7 8 9];
func_tasks = {'resting', 'movement', 'main', 'main', 'main', 'movement', 'main', 'main', 'main'};
if length(func_run_nums) == length(func_tasks)
    disp('done');
    run_n = length(func_run_nums); % number of number        
else
    warning('Length of ''func_run_nums'' and ''func_tasks'' are different. It must be equal. Please check.');
end
%% SETUP: set the disdaq
NOfTR=18; % number of TR you want to exclude
disdaq_n = repmat(NOfTR, 1, run_n); %(number of TR, 1, number of run);
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
%% A-2. Dicom to nifti: structural and functional
% A-2. Dicom to nifti: anat(T1)
humanfmri_a2_structural_dicom2nifti_bids(subject_code, study_imaging_dir);

% A-3. Dicom to nifti: functional(Run 1~9)
humanfmri_a3_functional_dicom2nifti_bids(subject_code, study_imaging_dir, disdaq_n,'no_check_disdaq');
%humanfmri_a3_functional_dicom2nifti_bids(subject_code{1,sub_i}, study_imaging_dir, disdaq_n);

% A-4. Dicom to nifti: fmap(Distortion correction)
humanfmri_a4_fieldmap_dicom2nifti_bids(subject_code, study_imaging_dir);
%% Done with A Part =======================================================
% You can use the following tools
% BIDS-validator: http://incf.github.io/bids-validator/ in chrome
% Fmriprep (preprocessing tool): see http://fmriprep.readthedocs.io/en/stable/
%% B. COCOANLAB PREPROC

% PART B: --------------------
% 3. disdaq & visualization/qc (canlab)
% 4. motion correction (realignment)
% 5. T1 normalization
% 6. Smoothing
% ----------------------------
% 7. (optional) ICA-AROMA
% ----------------------------

%% PART3:
% B-1. Preproc directories
study_imaging_dir = '/Volumes/sein/hbmnas/data/SEMIC/imaging';
subj_idx = 1:59; % [1:34, 43:54] or [2,3,4, 5, 21];
projName = 'semic'; % project name
[preproc_subject_dir, subject_code] = make_subject_dir_code(study_imaging_dir, projName,subj_idx);

% set the each preproc dir
% preproc_subject_dir{1} = fullfile(study_imaging_dir,'preprocessed',subject_code{1,sub_i});
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
%% B-6. distortion correction
epi_enc_dir = 'ap';
use_sbref = true;
humanfmri_b6_distortion_correction(p1, epi_enc_dir, use_sbref,'overwritten','run_num',1:9);
%% PART 4
% B-7. coregistration (spm_check_registration.m)
humanfmri_b7_coregistration(preproc_subject_dir, use_sbref, 'no_check_reg');

% humanfmri_b7_coregistration(preproc_subject_dir, use_sbref,'no_dc','run_num',1:9);
% humanfmri_b7_coregistration(preproc_subject_dir, use_sbref);
%% B-8-1. T1 Normalization
humanfmri_b8_normalization(preproc_subject_dir, use_sbref);

% humanfmri_b8_normalization(preproc_subject_dir, use_sbref,'no_dc','run_num',1:9);
% humanfmri_b8_normalization(preproc_subject_dir, use_sbref, 'no_check_reg');
%% B-10. Smoothing
% 'fwhm' = 5 (defaults)
humanfmri_b9_smoothing(preproc_subject_dir,'run_num',1:9);
%humanfmri_b9_smoothing(preproc_subject_dir,'run_num',1:9,'fwhm',5);
%% B-11. ICA-AROMA ()
% =========================================================================
% :: WARNING ::
%
% : real-time SYNC systems (e.g., Dropbox and synology cloud station)
%  may cause error during running MELODIC and ICA-AROMA
%
% =========================================================================
aroma_dir = '/Volumes/sein/github/external_toolbox/ICA-AROMA';
conda_dir = '/Users/admin/anaconda2/bin';
humanfmri_b10_ICA_AROMA(preproc_subject_dir, 'ica_aroma_dir', aroma_dir,'anaconda_dir', conda_dir);
%% Manual check

% for each subject
% 1) check qc_images
% 2) check_registration for coreg and normalization
spm_check_registration(PREPROC.coreg_anat_file, PREPROC.dc_func_sbref_files{1});
spm_check_registration(which('keuken_2014_enhanced_for_underlay.img'), PREPROC.wcoreg_anat_file{1});
%% C. COCOANLAB PREPROC

% PART C: --------------------
% 1. move_clean_files 
% 2. Framewise displacement 
% 3. Nuisance matrix

%% C-1
% this function is not done yet. 
%% C-2 FD
humanfmri_c2_get_framewise_displacement(preproc_subject_dir,'type','Power');
%% C-3 Nuisance matrix 
humanfmri_c3_make_nuisance_regressors(preproc_subject_dir,'regressors',{'24Move','Spike','WM_CSF'});
%humanfmri_c3_make_nuisance_regressors(preproc_subject_dir,'regressors',{'24Move','Spike','WM_CSF'},'img',[,field name in PREPROC]);