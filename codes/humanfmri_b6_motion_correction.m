function PREPROC = humanfmri_b6_motion_correction(preproc_subject_dir, use_st_corrected_data, use_sbref)

% This function does motion correction (realignment) on functional data.
%
% :Usage:
% ::
%      PREPROC = humanfmri_b6_motion_correction(preproc_subject_dir, use_st_corrected_data)
%
%
% :Input:
% 
% - preproc_subject_dir     the subject directory for preprocessed data
%                             (PREPROC.preproc_outputdir)
% - use_st_corrected_data   1: use adc_func_bold_files
%                           0: use dc_func_bold_files 
%                              (without slice timing correction)
%
% :Output(PREPROC):
% ::
%   PREPROC.realign_job
%   PREPROC.rao_func_files
%   PREPROC.mvmt_param_files
%   PREPROC.nuisance.mvmt_covariates
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


for subj_i = 1:numel(preproc_subject_dir)

    subject_dir = preproc_subject_dir{subj_i};
    cd(subject_dir);
    
    [~,a] = fileparts(subject_dir);
    print_header('Motion correction (realignment)', a);

    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC

    %% DEFAULT
    def = spm_get_defaults('realign');
    matlabbatch = {};
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions = def.estimate;
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions = def.write;
    
    % change a couple things
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm = 0; % do not register to mean (twice as long)
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask = 0; % do not mask (will set data to zero at edges!)
    
    if use_st_corrected_data
        data = PREPROC.adc_func_bold_files;
    else
        data = PREPROC.dc_func_bold_files;
    end
    
    %% run realign for EACH run
    % for run_i = 1:numel(data)
    %
    %   if use_sbref
    %      data_run = [PREPROC.dc_func_sbref_files(run_i);data(run_i)];
    %   end
    %
    %   matlabbatch{1}.spm.spatial.realign.estwrite.data{1} = data_run;
    %
    %   PREPROC.realign_job{run_i} = matlabbatch{1};
    %
    %   PREPROC.r_func_bold_files{run_i} = prepend_a_letter(data(run_i), ones(size(data(run_i))), 'r');
    %
    %   % RUN
    %   spm('defaults','fmri');
    %   spm_jobman('initcfg');
    %   spm_jobman('run', {matlabbatch});
    %
    %   [d, f] = fileparts(PREPROC.dc_func_sbref_files{run_i});
    %   PREPROC.mvmt_param_files{run_i} = fullfile(d, ['rp_' f '.txt']);
    %   temp_mvmt = textread(PREPROC.mvmt_param_files{run_i});
    %
    %   PREPROC.nuisance.mvmt_covariates{run_i} = temp_mvmt(2:end,:); % remove sbref
    %
    % end

    %% run realign ACROSS runs 
    if use_sbref
        data_all = [PREPROC.dc_func_sbref_files(1);data];
    else
        data_all = data;
    end

    matlabbatch{1}.spm.spatial.realign.estwrite.data{1} = data_all;

    PREPROC.realign_job = matlabbatch{1};

    PREPROC.r_func_bold_files = prepend_a_letter(data, ones(size(data)), 'r');
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC

    %% RUN
    spm('defaults','fmri');
    spm_jobman('initcfg');
    spm_jobman('run', {matlabbatch});

    %% Save realignment parameter
    
    if use_sbref
        [d, f] = fileparts(PREPROC.dc_func_sbref_files{1});
    else
        [d, f] = fileparts(data{1});
    end
    
    PREPROC.mvmt_param_files = fullfile(d, ['rp_' f '.txt']);
    temp_mvmt = textread(PREPROC.mvmt_param_files);
    PREPROC.nuisance.all_mvmt = temp_mvmt(2:end); 

    for run_i = 1:numel(data)
        
        images_per_session = numel(spm_vol(data{run_i}));
        
        if run_i == 1, kk = 2; else, kk = 1; end
        PREPROC.nuisance.mvmt_covariates{run_i} = temp_mvmt(kk:(images_per_session+kk-1),:);
        temp_mvmt(1:(images_per_session+kk-1),:) = [];
    end
    
    %% Save mean realigned file

    % for run_i = 1:numel(PREPROC.r_func_bold_files)
    %   dat = fmri_data(char(PREPROC.r_func_bold_files{run_i }), PREPROC.implicit_mask_file);
    %   mdat = mean(dat);
    %   [~, b] = fileparts(PREPROC.r_func_bold_files{run_i });
    %
    %   mdat.fullpath = fullfile(PREPROC.preproc_mean_func_dir, ['mean_' b '.nii']);
    %   PREPROC.mean_r_func_bold_files_run{run_i ,1} = mdat.fullpath;
    %   write(mdat);
    % end

    %% save mean image across all runs
    dat = fmri_data(char(PREPROC.r_func_bold_files{:}), PREPROC.implicit_mask_file);
    mdat = mean(dat);
    
    [~, b] = fileparts(PREPROC.r_func_bold_files{1});
    b(strfind(b, '_run'):end) = [];
    
    mdat.fullpath = fullfile(PREPROC.preproc_mean_func_dir, ['mean_' b '.nii']);
    PREPROC.mean_r_func_bold_files = mdat.fullpath;
    write(mdat);
    
    %% save mean_r_func_bold_png
    
    canlab_preproc_show_montage(PREPROC.mean_r_func_bold_files);
    drawnow;
    
    mean_r_func_bold_png = fullfile(PREPROC.qcdir, 'mean_r_func_bold.png'); % Scott added some lines to actually save the spike images
    saveas(gcf,mean_r_func_bold_png);
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC

end

end
