function PREPROC = humanfmri_8_coregistration(preproc_subject_dir)

% This function does coregistration of a structural image to the mean 
% functional image. Mean functional image can be a mean image of each run.
%
% :Usage:
% ::
%       PREPROC = humanfmri_8_coregistration(preproc_subject_dir)
%
% :Input:
% :: 
%       subject_dir           directory for the subject
%
% :Output(PREPROC):
% ::
%    PREPROC.r_anat_files
%    PREPROC.anat_preproc_descript
%

% Load PREPROC

PREPROC = save_load_PREPROC(preproc_subject_dir, 'load'); % load PREPROC

coregsource = PREPROC.anat_nii_files{1};

coregdef = spm_get_defaults('coreg');

coreg_job = {};
coreg_job{1}.spm.spatial.coreg.estwrite.eoptions = coregdef.estimate;
coreg_job{1}.spm.spatial.coreg.estwrite.roptions = coregdef.write;
coreg_job{1}.spm.spatial.coreg.estwrite.ref{1} = PREPROC.mean_before_preproc;
coreg_job{1}.spm.spatial.coreg.estwrite.source{1} = coregsource;
% 
% coreg_job{1}.spatial{1}.coreg{1}.estwrite
% coreg_job{1}.spatial{1}.coreg{1}.estwrite.roptions = coregdef.write;
% coreg_job{1}.spatial{1}.coreg{1}.estwrite.ref{1} = PREPROC.mean_before_preproc;
% coreg_job{1}.spatial{1}.coreg{1}.estwrite.source{1} = coregsource;

r_anat_files = prepend_a_letter(PREPROC.anat_files, 1, 'r');
PREPROC.r_anat_files = r_anat_files(1);

PREPROC.anat_preproc_descript = char({'r:coregistered'; 'o:reoriented';'w:normalized'});

save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC

spm('defaults','fmri');
spm_jobman('initcfg');

spm_jobman('run', {coreg_job});

end