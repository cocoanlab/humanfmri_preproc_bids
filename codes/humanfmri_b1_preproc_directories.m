function preproc_subject_dir = humanfmri_b1_preproc_directories(subject_code, study_imaging_dir, varargin)

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

run_num = [];
do_savepreproc_inpreprocdir = false;

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case {'run_num'}
                run_num = varargin{i+1};
            case {'forced_save'}
                do_savepreproc_inpreprocdir = true;
        end
    end
end

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
    
    fnames = [];
    if ~isempty(run_num)
        for i = 1:numel(run_num), fnames = [fnames; filenames(sprintf('%srun-%02d*', [fileparts(PREPROC.func_bold_files{1}) '/*'], run_num(i)))]; end
        % update the files of run_num
        for i = 1:size(fnames,1), copyfile(fnames{i}, PREPROC.preproc_func_dir); end
    else
        copyfile([fileparts(PREPROC.func_bold_files{1}) '/*'], PREPROC.preproc_func_dir);
    end
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % load PREPROC
    
    if isempty(run_num) || do_savepreproc_inpreprocdir
        save_load_PREPROC(preproc_subject_dir{subj_i}, 'save', PREPROC); % load PREPROC
    end
    
end

end