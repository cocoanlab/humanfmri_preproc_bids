function PREPROC = humanfmri_a1_make_directories(subject_code, study_imaging_dir, func_run_nums, tasks)

% The function creates directories for dicom files
%
% :Usage:
% ::
%    subject_dir = humanfmri_a1_make_directories(subject_code, study_imaging_dir, varargin)
%
% :Inputs:
% ::
% 
% - subject_code       the subject id
%                      (e.g., subject_code = {'sub-caps001', 'sub-caps002'});
% - study_imaging_dir  the directory information for the study imaging data
%                      (e.g., study_imaging_dir = '/NAS/data/CAPS2/Imaging')
% - func_run_nums      The run num of functional data directory that you
%                      want to create. If you want to create run01,
%                      run02, func_run_nums should be 1:2
%                      If each subject has different numbers of runs, you
%                      can use cell array 
%                           e.g., func_run_nums{1} = 1:4;
%                                 func_run_nums{2} = 1:2;
%                      
% - func_tasks         Task names or other information 
%                           e.g., func_tasks = {'CAPS', 'ODOR'}
%                      If participants have different orders of the tasks,
%                      you can use the cell array to specify it. 
%                           e.g., func_tasks{1} = {'CAPS', 'ODOR'};
%                                 func_tasks{2} = {'ODOR', 'CAPS'};
%                      If one run has multiple task data, you can use
%                      func_run_nums to specify it. 
%                           e.g., func_run_nums = [1 1 2 2];
%
% * this creates bold and sbref directories for the functional runs. If you
% don't have sbref images, just delete those directories. 
%
% :Example:
% ::
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
    tasks_cell{1} = tasks;
    func_run_nums_cell{1} = func_run_nums;
else
    subject_codes = subject_code;
    
    if ischar(tasks) % if tasks is char
        for subj_i = 1:numel(subject_codes)
            tasks_cell{subj_i} = tasks; 
        end
    elseif numel(subject_codes) ~= numel(tasks) % tasks is cell, but multiple tasks
        for subj_i = 1:numel(subject_codes)
            tasks_cell{subj_i} = tasks; 
        end
    else % if tasks is cell and each cell for each subject
        tasks_cell = tasks;
    end
    
    if ~iscell(func_run_nums) % if func_run_nums is not in the cell
        for subj_i = 1:numel(subject_codes)
            func_run_nums_cell{subj_i} = func_run_nums;
        end
    end
end

% loop for subjects. it could be one subject

for subj_i = 1:numel(subject_codes)
    
    subject_dir = fullfile(study_imaging_dir, 'raw', subject_codes{subj_i});
    
    % anat directory
    dicomdir{1, 1} = fullfile(subject_dir, 'dicom');
    dicomdir{2, 1} = fullfile(subject_dir, 'dicom', 'anat');
    for i = 1:2, mkdir(dicomdir{i}); end
    
    % func directory
    j = 2;
    for i = 1:numel(func_run_nums)
        j = j + 1;
        dicomdir{j, 1} = fullfile(subject_dir, 'dicom', sprintf('func_task-%s_run-%02d_bold', tasks_cell{subj_i}{i}, func_run_nums_cell{subj_i}(i)));
        mkdir(dicomdir{j});
        
        j = j + 1;
        dicomdir{j, 1} = fullfile(subject_dir, 'dicom', sprintf('func_task-%s_run-%02d_sbref', tasks_cell{subj_i}{i}, func_run_nums_cell{subj_i}(i)));
        mkdir(dicomdir{j});
    end
    
    % fmap directory
    dicomdir{j+1, 1} = fullfile(subject_dir, 'dicom', 'fmap');
    mkdir(dicomdir{j+1});
    
    PREPROC.study_imaging_dir = study_imaging_dir;
    PREPROC.study_rawdata_dir = fullfile(study_imaging_dir, 'raw');
    PREPROC.subject_code = subject_codes{subj_i};
    PREPROC.subject_dir = subject_dir;
    PREPROC.dicom_dirs = dicomdir;
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC
    
end

end