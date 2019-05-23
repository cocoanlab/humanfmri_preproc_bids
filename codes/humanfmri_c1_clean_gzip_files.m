function PREPROC = humanfmri_c1_clean_gzip_files(preproc_subject_dir, varargin)

% This function delete and gzip some intermediate preprocessed functional 
% files except for swr and wr.
%
% :Default: 
% :: 
%       Delete the following files:
%           Step 1) PREPROC.preproc_func_bold_files along with json and mat files
%                   (the same files are stored in /imaging/raw/(subjdir)/func/
%           Step 2) PREPROC.preproc_func_sbref_files (with json and mat)
%           Step 3) PREPROC.r_func_bold_files
%           Step 4) PREPROC.dc_func_sbref_files
%           Step 5) PREPROC.dcr_func_bold_files
%
%       Gzip the following files:
%           Step 6) PREPROC.wr_func_bold_files
%
% :Usage:
% ::
%      PREPROC = humanfmri_c1_clean_gzip_files(preproc_subject_dir)
%
% :Input:
% ::
%
% - preproc_subject_dir     the subject directory for preprocessed data
%                             (PREPROC.preproc_outputdir)
%
%
% :Optional Input:
% ::
%
% - steps      You can specify the steps you want to run using the 'steps'
%              option. e.g., 'steps', [1 4], then this will run only 1st 
%              (delete PREPROC.preproc_func_bold_files) and 4th steps
%              (gzip)

steps = 1:6;

step_descript = {'deleted PREPROC.preproc_func_bold_files with json and mat files', ...
    'deleted PREPROC.preproc_func_sbref_files (with json and mat files)',...
    'deleted PREPROC.r_func_bold_files', ...
    'deleted PREPROC.dc_func_sbref_files', ...
    'deleted PREPROC.dcr_func_bold_files', ...
    'gzip PREPROC.wr_func_bold_files'};

PREPROC.clean_steps{1} = [];

for i = 1:numel(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case {'gzip_only'} % in seconds
                steps = 6;
            case {'clean_only'}
                steps = 1:5;
            case {'steps'}
                steps = varargin{i+1};
        end
    end
end

for subj_i = 1:numel(preproc_subject_dir)
    
    subject_dir = preproc_subject_dir{subj_i};
    [~,a] = fileparts(subject_dir);
    print_header('Clean and gzip files', a);
    
    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC
    
    for j = 1:numel(steps)
        switch steps(j)
            case 1
                PREPROC.clean_steps{end+1} = step_descript{1};
                for ii = 1:numel(PREPROC.preproc_func_bold_files)
                    [a, b] = fileparts(PREPROC.preproc_func_bold_files{ii});
                    temp_file1 = filenames(fullfile(a, [b '.nii']));
                    temp_file2 = filenames(fullfile(a, [b '.json']));
                    temp_file3 = filenames(fullfile(a, [b '.mat']));
                    
                    try delete(temp_file1{1}); catch, end
                    try delete(temp_file2{1}); catch, end
                    try delete(temp_file3{1}); catch, end
                end
             case 2
                PREPROC.clean_steps{end+1} = step_descript{2};
                for ii = 1:numel(PREPROC.preproc_func_sbref_files)
                    [a, b] = fileparts(PREPROC.preproc_func_sbref_files{ii});
                    temp_file1 = filenames(fullfile(a, [b '.nii']));
                    temp_file2 = filenames(fullfile(a, [b '.json']));
                    temp_file3 = filenames(fullfile(a, [b '.mat']));
                    
                    try delete(temp_file1{1}); catch, end
                    try delete(temp_file2{1}); catch, end
                    try delete(temp_file3{1}); catch, end
                end
            case 3
                PREPROC.clean_steps{end+1} = step_descript{3};
                delete(PREPROC.r_func_bold_files{:});
            case 4
                PREPROC.clean_steps{end+1} = step_descript{4};
                delete(PREPROC.dcr_func_bold_files{:});
            case 5
                PREPROC.clean_steps{end+1} = step_descript{5};
                delete(PREPROC.dc_func_sbref_files{:});
            case 6
                PREPROC.clean_steps{end+1} = step_descript{6};
                for ii = 1:numel(PREPROC.preproc_func_sbref_files)
                    gzip(PREPROC.wr_func_bold_files{ii});
                end
                delete(PREPROC.wr_func_bold_files{:});
        end
    end
            
end
    
save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC
    
end