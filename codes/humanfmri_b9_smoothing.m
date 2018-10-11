function PREPROC = humanfmri_b9_smoothing(preproc_subject_dir, varargin)

% This function does smoothing on the functional image for one run. 
%
% :Usage:
% ::
%    PREPROC = humanfmri_b8_smoothing(preproc_subject_dir, varargin)
%
%
% :Input:
% ::
%
% - preproc_subject_dir     the subject directory for preprocessed data
%                             (PREPROC.preproc_outputdir)
%
% :Optional Input:
% ::
%    'fwhm', 5      full-width half max for the smoothing kernel
%
%
% :Output(PREPROC):
% :: 
%     PREPROC.swrao_func_files
%     PREPROC.smoothing_job 
%     save 'swra_func_files.png' in qcdir
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

fwhm = 5; % default fwhm
run_num = [];

for i = 1:numel(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case {'fwhm'} % in seconds
                fwhm = varargin{i+1};
            case {'run_num'}
                run_num = varargin{i+1};
        end
    end
end

for subj_i = 1:numel(preproc_subject_dir)

    subject_dir = preproc_subject_dir{subj_i};
    [~,a] = fileparts(subject_dir);
    print_header(['Smoothing: FWHM ' num2str(fwhm) 'mm'], a);

    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC
    
    %% RUNS TO INCLUDE
    do_preproc = true(numel(PREPROC.r_func_bold_files),1);
    if ~isempty(run_num)
        do_preproc(~ismember(1:numel(PREPROC.r_func_bold_files), run_num)) = false;
        % delete existed output files
        for z = 1:numel(run_num)
            exist_file = prepend_a_letter(PREPROC.wr_func_bold_files(run_num), ones(size(PREPROC.wr_func_bold_files(run_num))), 's');
            if exist(exist_file{z})
                delete(exist_file{z})
            end
        end
    end
    
    matlabbatch = {};
    matlabbatch{1}.spm.spatial.smooth.prefix = 's';
    matlabbatch{1}.spm.spatial.smooth.dtype = 0; % data type; 0 = same as before
    matlabbatch{1}.spm.spatial.smooth.im = 0; % implicit mask; 0 = no
    matlabbatch{1}.spm.spatial.smooth.fwhm = repmat(fwhm, 1, 3); % override whatever the defaults were with this
    matlabbatch{1}.spm.spatial.smooth.data = PREPROC.wr_func_bold_files(do_preproc);
    
    % Save the job
    PREPROC.smoothing_job = matlabbatch;
    PREPROC.swr_func_bold_files = prepend_a_letter(PREPROC.wr_func_bold_files, ones(size(PREPROC.wr_func_bold_files)), 's');

    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC

    spm('defaults','fmri');
    spm_jobman('initcfg');
    spm_jobman('run', matlabbatch);

    for run_i = 1:numel(PREPROC.swr_func_bold_files)    %find(do_preproc)'
        dat = fmri_data(PREPROC.swr_func_bold_files{run_i});
        mdat = mean(dat);

        [~, b] = fileparts(PREPROC.swr_func_bold_files{run_i });
        mdat.fullpath = fullfile(PREPROC.preproc_mean_func_dir, ['mean_' b '.nii']);
        PREPROC.mean_swr_func_bold_files{run_i,1} = mdat.fullpath; % output
        write(mdat);
    end
    
    mean_swr_func_bold_png = fullfile(PREPROC.qcdir, 'mean_swr_func_bold.png'); % Scott added some lines to actually save the spike images
    canlab_preproc_show_montage(PREPROC.mean_swr_func_bold_files(do_preproc), mean_swr_func_bold_png);
    drawnow;
    
end