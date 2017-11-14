function PREPROC = humanfmri_1_make_directories(subject_code, study_imaging_dir, varargin)

% The function creates directories for dicom files
%
% :Usage:
% ::
%    subject_dir = humanfmri_1_make_directories(subject_code, study_imaging_dir, varargin)
%
% :Inputs:
% ::
% 
%   - subject_code       the subject code you want to use 
%                         (e.g., subject_code = 'CAPS2_s001');
%   - study_imaging_dir  the directory information for the study imaging data
%                         (e.g., study_imaging_dir = '/NAS/data/CAPS2/Imaging')
%
% :Optional inputs:
% ::
% 
%   - func_run_nums      The run num of functional data directory that you
%                        want to create. If you want to create run01,
%                        run02, func_run_nums should be [1 2]
%   - func_tasks         Task names or other information (e.g., sbref
%                        images) that you want to use. 
%                           e.g., func_tasks = {'CAPS', 'CAPS_SBREF', 'ODOR', 'ODOR_SBREF'};
%                        If one run has multiple task data, you can use
%                        func_run_nums to specify it. 
%                           e.g., func_run_nums = [1 1 2 2];
%
%   *** This function will create and save PREPROC in PREPRO2C.mat in subject_dir
%
% :Example:
% ::
%
% 
% study_imaging_dir = '/Users/clinpsywoo/Dropbox/projects/ongoing_projects/preproc_pipeline/CAPS2_preproc_test/Imaging';
% subject_code = 'caps001';
% func_run_nums = [1 1 2 2 3 3 4 4];
% func_tasks = {'CAPS', 'CAPS_SBREF', 'QUIN', 'QUIN_SBREF', 'REST', 'REST_SBREF', 'ODOR', 'ODOR_SBREF'};
%
% PREPROC = humanfmri_1_make_directories(subject_code, study_imaging_dir, 'func_run_nums', func_run_nums,  'func_tasks', func_tasks);
% 

func_run_nums = 1;
tasks = {'empty'};

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            % functional commands
            case {'func_run_nums'}
                func_run_nums = varargin{i+1};
            case {'func_tasks'}
                tasks = varargin{i+1};
        end
    end
end

subject_dir = fullfile(study_imaging_dir, 'raw', subject_code);

% anat directory
dicomdir{1, 1} = fullfile(subject_dir, 'dicom');
dicomdir{2, 1} = fullfile(subject_dir, 'dicom', 'anat');
for i = 1:2, mkdir(dicomdir{i}); end

% func directory
j = 2;
for i = 1:numel(func_run_nums)
    j = j + 1;
    dicomdir{j, 1} = fullfile(subject_dir, 'dicom', sprintf('func_task-%s_run-%02d_bold', tasks{i}, func_run_nums(i)));
    mkdir(dicomdir{j});
    
    j = j + 1;
    dicomdir{j, 1} = fullfile(subject_dir, 'dicom', sprintf('func_task-%s_run-%02d_sbref', tasks{i}, func_run_nums(i)));
    mkdir(dicomdir{j});
end

% fmap directory
dicomdir{j+1, 1} = fullfile(subject_dir, 'dicom', 'fmap');
mkdir(dicomdir{j+1});

PREPROC.study_imaging_dir = study_imaging_dir;
PREPROC.subject_code = subject_code;
PREPROC.subject_dir = subject_dir;
PREPROC.dicom_dirs = dicomdir;

save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC

end