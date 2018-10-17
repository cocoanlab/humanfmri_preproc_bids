function PREPROC = humanfmri_b5_motion_correction(preproc_subject_dir, use_st_corrected_data, use_sbref, varargin)

% This function does motion correction (realignment) on functional data.
%
% :Usage:
% ::
%      PREPROC = humanfmri_b5_motion_correction(preproc_subject_dir, use_st_corrected_data)
%
%
% :Input:
% 
% - preproc_subject_dir     the subject directory for preprocessed data
%                             (PREPROC.preproc_outputdir)
% - use_st_corrected_data   1: use a_func_bold_files
%                           0: use preproc_func_bold_files 
%                              (without slice timing correction)
%
% :Output(PREPROC):
% ::
%   PREPROC.realign_job
%   PREPROC.r_func_bold_files
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

run_num = [];

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case {'run_num'}
                run_num = varargin{i+1};
        end
    end
end

for subj_i = 1:numel(preproc_subject_dir)

    subject_dir = preproc_subject_dir{subj_i};
    cd(subject_dir);
    
    [~,a] = fileparts(subject_dir);
    print_header('Motion correction (realignment)', a);

    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC
    
    %% RUNS TO INCLUDE
    do_preproc = true(numel(PREPROC.preproc_func_bold_files),1);
    if ~isempty(run_num)
        if ~use_sbref
            warning('With run_num, you will end up using a different image as a reference.');
            warning('Please consider to use SBREF as your reference image.');
            warning('OR you could also provide a reference image, but this has not been implemented yet.');
            error('Sorry about that.');
        else
            do_preproc(~ismember(1:numel(PREPROC.preproc_func_bold_files), run_num)) = false;
        end
    end

    %% DEFAULT
    def = spm_get_defaults('realign');
    matlabbatch = {};
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions = def.estimate;
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions = def.write;
    
    % change a couple things
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm = 0; % do not register to mean (twice as long)
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask = 0; % do not mask (will set data to zero at edges!)
    
    if use_st_corrected_data
        data = PREPROC.a_func_bold_files(do_preproc);
    else
        data = PREPROC.preproc_func_bold_files(do_preproc);
    end
    
    %% run realign ACROSS runs 
    if use_sbref
        data_all = [PREPROC.preproc_func_sbref_files(1);data];
    else
        data_all = data;
    end

    matlabbatch{1}.spm.spatial.realign.estwrite.data{1} = data_all;

    PREPROC.realign_job = matlabbatch{1};

    PREPROC.r_func_bold_files(do_preproc,1) = prepend_a_letter(data, ones(size(data)), 'r');
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC

    %% If there is run_num, change the mvmt file name to save the original mvmt
    if ~isempty(run_num)
        [d, f] = fileparts(PREPROC.mvmt_param_files);
        movefile(PREPROC.mvmt_param_files, fullfile(d, [f '_original.txt']));
        
        % delete the already exist 'rsub-f*bold.nii' files
        for z = 1:numel(run_num)
            if exist(PREPROC.r_func_bold_files{run_num(z)})
                delete(PREPROC.r_func_bold_files{run_num(z)})
            end
        end     
    end
    
    %% RUN
    spm('defaults','fmri');
    spm_jobman('initcfg');
    spm_jobman('run', {matlabbatch});

    %% Save realignment parameter
    
    if use_sbref
        [d, f] = fileparts(PREPROC.preproc_func_sbref_files{1});
    else
        [d, f] = fileparts(data{1});
    end
    
    PREPROC.mvmt_param_files = fullfile(d, ['rp_' f '.txt']);
    temp_mvmt = textread(PREPROC.mvmt_param_files);
    % PREPROC.nuisance.all_mvmt = temp_mvmt(2:end,:); 
    
    k = 0;
    for run_i = find(do_preproc)'
        
        k = k + 1;
        images_per_session = numel(spm_vol(data{k}));
        
        if run_i == 1, kk = 2; else, kk = 1; end
        
        PREPROC.nuisance.mvmt_covariates{run_i} = temp_mvmt(kk:(images_per_session+kk-1),:);
        temp_mvmt(1:(images_per_session+kk-1),:) = [];
        
        % save plot
        create_figure('mvmt', 2, 1)
        subplot(2,1,1);
        plot(PREPROC.nuisance.mvmt_covariates{run_i}(:,1:3));
        legend('x', 'y', 'z');
        
        subplot(2,1,2);
        plot(PREPROC.nuisance.mvmt_covariates{run_i}(:,4:6));
        legend('pitch', 'roll', 'yaw');

        sz = get(0, 'screensize'); % Wani added two lines to make this visible (but it depends on the size of the monitor)
        set(gcf, 'Position', [sz(3)*.02 sz(4)*.05 sz(3) *.45 sz(4)*.85]);
        drawnow;
        
        [~,a] = fileparts(PREPROC.preproc_func_bold_files{run_i});
        
        mvmt_qcfile = fullfile(PREPROC.qcdir, ['qc_mvmt_' a '.png']); % Scott added some lines to actually save the spike images
        saveas(gcf,mvmt_qcfile);
        close all;
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
    
    mean_r_func_bold_png = fullfile(PREPROC.qcdir, 'mean_r_func_bold.png'); % Scott added some lines to actually save the spike images
    canlab_preproc_show_montage(PREPROC.mean_r_func_bold_files, mean_r_func_bold_png);
    drawnow;
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC

end

end
