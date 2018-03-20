study_imaging_dir = '/Volumes/accumbens/hbmnas/data/FAST/imaging';
subject_code = 'sub-fast002';

% run numbers and task names
func_run_nums = [1 2 3 4 5 6 7 8 9];
func_tasks = {'resting', 'wordgen', 'fastfmri', 'wordgen', 'fastfmri', 'wordgen', 'fastfmri', 'wordgen', 'fastfmri'};
disdaq_n = repmat(20, 1, 9);

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
% d=datetime('now')
% A-2. Dicom to nifti: anat(T1)

humanfmri_a2_structural_dicom2nifti_bids(subject_code, study_imaging_dir);

% A-3. Dicom to nifti: functional(Run 1~9)

humanfmri_a3_functional_dicom2nifti_bids(subject_code, study_imaging_dir, disdaq_n);

% A-4. Dicom to nifti: fmap(Distortion correction)

humanfmri_a4_fieldmap_dicom2nifti_bids(subject_code, study_imaging_dir);

% d=[d datetime('now')]

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
% B-1. Preproc directories
study_imaging_dir = '/Volumes/accumbens/hbmnas/data/FAST/imaging';
subject_code = {'sub-fast002'};

preproc_subject_dir = humanfmri_b1_preproc_directories(subject_code, study_imaging_dir);

% B-2. Implicit mask and save means

humanfmri_b2_functional_implicitmask_savemean(preproc_subject_dir);

% B-3. Spike id

humanfmri_b3_spike_id(preproc_subject_dir);

% B-4. Slice timing correction if needed: You can skip this if TR is short enough

% tr = .46;
% mbf = 8;
% 
% humanfmri_b4_slice_timing(preproc_subject_dir, tr, mbf);

% B-5. Motion correction

use_st_corrected_data = false;
use_sbref = true;
humanfmri_b5_motion_correction(preproc_subject_dir, use_st_corrected_data, use_sbref);
% d=[d datetime('now')]

%% B-6. distortion correction
epi_enc_dir = 'ap';
humanfmri_b6_distortion_correction(preproc_subject_dir, epi_enc_dir, use_sbref)

%% PART 4
% B-7. coregistration (spm_check_registration.m)

use_sbref = true;
humanfmri_b7_coregistration(preproc_subject_dir, use_sbref);
%humanfmri_b7_coregistration(preproc_subject_dir, use_sbref, 'no_check_reg');

%% B-8-1. T1 Normalization

humanfmri_b8_normalization(preproc_subject_dir, use_sbref);
% humanfmri_b8_normalization(preproc_subject_dir, use_sbref, 'no_check_reg');

%% B-10. Smoothing
humanfmri_b9_smoothing(preproc_subject_dir);

%% B-11. ICA-AROMA (currently not using)

% humanfmri_b10_ICA_AROMA(preproc_subject_dir, 'ica_aroma_dir', '/Volumes/accumbens/Resource/ICA-AROMA', ...
%     'anaconda_dir', '/Users/admin/anaconda/bin');

%% Manual check

% for each subject
% 1) check qc_images
% 2) check_registration for coreg and normalization
spm_check_registration(PREPROC.coreg_anat_file, PREPROC.dc_func_sbref_files{1});
spm_check_registration(which('keuken_2014_enhanced_for_underlay.img'), PREPROC.wcoreg_anat_file{1});
