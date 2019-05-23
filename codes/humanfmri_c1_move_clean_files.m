function PREPROC = humanfmri_c1_move_clean_files(preproc_subject_dir, varargin)

% ***Warning: this is not done yet. Don't use this. We are thinking not
% including this function, which seems less useful.***
%
% This function gzip functional files except for swr and wr.
%
% :Usage:
% ::
%      PREPROC = humanfmri_c1_move_clean_files(preproc_subject_dir)
%
% :Optional Input:
% ::
%

do_clean = true;
do_gzip = true;

for i = 1:numel(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case {'gzip_only'} % in seconds
                do_clean = false;
            case {'clean_only'}
                do_gzip = false;
        end
    end
end

for subj_i = 1:numel(preproc_subject_dir)
    
    subject_dir = preproc_subject_dir{subj_i};
    [~,a] = fileparts(subject_dir);
    print_header('Clean and gzip files', a);
    
    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC
    
    for i = session_num
        % move preprocessed files
        [~, f1] = fileparts(PREPROC.swrao_func_files{i});
        [~, f2] = fileparts(PREPROC.wrao_func_files{i});
        [~, r] = fileparts(fileparts(PREPROC.swrao_func_files{i}));
        mkdir(fullfile(preproc_dir, r))
        
        if do_move
            movefile(PREPROC.swrao_func_files{i}, fullfile(preproc_dir, r, [f1 '.nii']));
            movefile(fullfile(fileparts(PREPROC.swrao_func_files{i}), [f1 '.mat']), fullfile(preproc_dir, r, [f1 '.mat']));
            PREPROC.swrao_func_files{i} = fullfile(preproc_dir, r, [f1 '.nii']);
            movefile(PREPROC.wrao_func_files{i}, fullfile(preproc_dir, r, [f2 '.nii']));
            movefile(fullfile(fileparts(PREPROC.wrao_func_files{i}), [f2 '.mat']), fullfile(preproc_dir, r, [f2 '.mat']));
            PREPROC.wrao_func_files{i} = fullfile(preproc_dir, r, [f2 '.nii']);
        end
        
        % gzip wra and func_files except for swrao_func_files
        if do_gzip
            gzip(PREPROC.func_files{i});
            gzip(PREPROC.o_func_files{i});
            gzip(PREPROC.ao_func_files{i});
            gzip(PREPROC.rao_func_files{i});
            gzip(PREPROC.wrao_func_files{i});
        end
    end
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC
    
end