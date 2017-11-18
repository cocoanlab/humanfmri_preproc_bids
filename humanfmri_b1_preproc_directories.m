function preproc_subject_dir = humanfmri_b1_preproc_directories(subject_code, study_imaging_dir)

% This function creates directories for data preprocessing
%
% :Usage:
% ::
%    preproc_subject_dir = humanfmri_b1_preproc_directories(subject_code, study_imaging_dir)
%
% :Input:
% 
% - subject_code    the subject id
%                   (e.g., subject_code = {'sub-caps001', 'sub-caps002'});
% - study_imaging_dir  the directory information for the study imaging data
%                      (e.g., study_imaging_dir = '/NAS/data/CAPS2/Imaging')
%
%
% :Output:
% ::
%     preproc_subject_dir{}    new subject directory (PREPROC.preproc_outputdir)
%     
%     This also saves PREPROC in both subject_dir and preproc_subject_dir.
%
% ..
%     Author and copyright information:
%
%     Copyright (C) Nov 2017  Choong-Wan Woo
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
% ..



if ~iscell(subject_code)
    subject_codes{1} = subject_code;
else
    subject_codes = subject_code;
end

for subj_i = 1:numel(subject_codes)
    
    subject_dir = fullfile(study_imaging_dir, 'raw', subject_codes{subj_i});
    
    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC
    
    %% create preproc directories
    
    PREPROC.preproc_outputdir = fullfile(PREPROC.study_imaging_dir, 'preprocessed', PREPROC.subject_code);
    if ~exist(PREPROC.preproc_outputdir, 'dir'), mkdir(PREPROC.preproc_outputdir); end
    
    PREPROC.preproc_func_dir = fullfile(PREPROC.preproc_outputdir, 'func');
    if ~exist(PREPROC.preproc_func_dir, 'dir'), mkdir(PREPROC.preproc_func_dir); end

    PREPROC.preproc_mean_func_dir = fullfile(PREPROC.preproc_outputdir, 'mean_func');
    if ~exist(PREPROC.preproc_mean_func_dir, 'dir'), mkdir(PREPROC.preproc_mean_func_dir); end
    
    PREPROC.preproc_anat_dir = fullfile(PREPROC.preproc_outputdir, 'anat');
    if ~exist(PREPROC.preproc_anat_dir, 'dir'), mkdir(PREPROC.preproc_anat_dir); end
    
    PREPROC.preproc_fmap_dir = fullfile(PREPROC.preproc_outputdir, 'fmap');
    if ~exist(PREPROC.preproc_fmap_dir, 'dir'), mkdir(PREPROC.preproc_fmap_dir); end
    
    PREPROC.qcdir = fullfile(PREPROC.preproc_outputdir, 'qc_images');
    if ~exist(PREPROC.qcdir, 'dir'), mkdir(PREPROC.qcdir); end
    
    preproc_subject_dir{subj_i} = PREPROC.preproc_outputdir;
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % load PREPROC
    save_load_PREPROC(preproc_subject_dir{subj_i}, 'save', PREPROC); % load PREPROC
end

end