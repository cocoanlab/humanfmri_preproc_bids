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
% :Optional inputs:
%
% - 'run_num'       You can use this optional input, when you want to start
%                   preproc for data only from some specific runs.
%                   With 'run_num' option, we recommend using 'no_save'
%                   option together. Because without no_save, it will
%                   replace PREPROC.mat with a new mat file in the
%                   preproc dir. 
%
% - 'forced_save'   With this option, this will overwrite PREPROC.mat
%                   without checking whether the file exists or not
%
% - 'no_save'       With this option, this function won't save PREPROC.mat
%                   in the preproc dir
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
do_save = true;
forced_save_inpreprocdir = false;

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case {'run_num'}
                run_num = varargin{i+1};
            case {'forced_save'}
                forced_save_inpreprocdir = true;
            case {'no_save'}
                do_save = false;
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
        
    PREPROC.preproc_dwi_dir = fullfile(PREPROC.preproc_outputdir, 'dwi');
    if ~exist(PREPROC.preproc_dwi_dir, 'dir'), mkdir(PREPROC.preproc_dwi_dir); end
    
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
      
    if forced_save_inpreprocdir % with forced save option, it will save it in any case. 
        save_load_PREPROC(preproc_subject_dir{subj_i}, 'save', PREPROC); % save PREPROC
    else
        if do_save % without forced save option, it will see whether PREPROC.mat exists in the preproc dir
            if exist(fullfile(preproc_subject_dir{subj_i}, 'PREPROC.mat'), 'file') % if it exists, it will ask how to proceed.
                warning('PREPROC.mat already exists in preproc dir.');
                s = input('How do you want to proceed? (o) overwrite, (Enter) do not save: ', 's'); 
                if s == 'o'
                    save_load_PREPROC(preproc_subject_dir{subj_i}, 'save', PREPROC); % save PREPROC
                end % with "enter" it will do nothing
            else
                save_load_PREPROC(preproc_subject_dir{subj_i}, 'save', PREPROC); % save PREPROC
            end
        end
    end
    
end

end