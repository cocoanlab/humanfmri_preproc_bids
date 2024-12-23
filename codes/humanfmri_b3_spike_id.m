function PREPROC = humanfmri_b3_spike_id(preproc_subject_dir, varargin)

% This function detects outliers (spikes) based on Mahalanobis distance
% and rmssd.
%
% :Usage:
% ::
%    PREPROC = humanfmri_b3_spike_id(preproc_subject_dir)
%
%
% :Input:
%
% - preproc_subject_dir     the subject directory for preprocessed data
%                           (PREPROC.preproc_outputdir)
%
%
% :Output(PREPROC):
% ::
%    PREPROC.nuisance.spike_covariates
%    PREPROC.qcdir
%    create /qc_images directory in subject_dir
%    save qc_spike_plot.png in qcdir.
%    save qc_spike_diary.txt in qcir.
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
txt_to_mat = false;

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case {'run_num'}
                run_num = varargin{i+1};
            case{'txt_to_mat'}
                txt_to_mat = true;
        end
    end
end

for subj_i = 1:numel(preproc_subject_dir)

    subject_dir = preproc_subject_dir{subj_i};
    [~,a] = fileparts(subject_dir);
    print_header('Spike and outlier detection', a);

    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC

    %% RUNS TO INCLUDE
    do_preproc = true(numel(PREPROC.preproc_func_bold_files),1);
    if ~isempty(run_num)
        do_preproc(~ismember(1:numel(PREPROC.preproc_func_bold_files), run_num)) = false;
    end

    %% DETECT OUTLIERS using canlab tools
    for run_i = 1:numel(PREPROC.preproc_func_bold_files)

        if do_preproc(run_i)

            dat = fmri_data(PREPROC.preproc_func_bold_files{run_i}, PREPROC.implicit_mask_file);
            dat.images_per_session = size(dat.dat,2);

            [~,a] = fileparts(PREPROC.preproc_func_bold_files{run_i});

            diary(fullfile(PREPROC.qcdir, ['qc_diary_' a '.txt']));
            dat = preprocess(dat, 'outliers', 'plot');  % Spike detect and globals by slice

            subplot(5, 1, 5);
            dat = preprocess(dat, 'outliers_rmssd', 'plot');  % RMSSD Spike detect
            diary off;
            sz = get(0, 'screensize'); % Wani added two lines to make this visible (but it depends on the size of the monitor)
            set(gcf, 'Position', [sz(3)*.02 sz(4)*.05 sz(3) *.45 sz(4)*.85]);
            drawnow;

            qcspikefilename = fullfile(PREPROC.qcdir, ['qc_spike_plot_' a '.png']); % Scott added some lines to actually save the spike images
            saveas(gcf,qcspikefilename);

            uout = unique(dat.covariates','rows','stable'); % Suhwan added (Nov 5, 2023): delete duplicate columns (RMSSD and mahalanobis distance)
            PREPROC.nuisance.spike_covariates{run_i} = uout'; % the first one is global signal, that I don't need.
        end

    end

    if txt_to_mat % convert txt to mat
        diary_mat_fname = fullfile(PREPROC.qcdir, ['qc_diary_', PREPROC.subject_code, '.mat']);
        if exist(diary_mat_fname, 'file')
            load(diary_mat_fname)
        end

        diary_txt_fnames = filenames(fullfile(PREPROC.qcdir, 'qc_diary*txt'));

        for run_i = 1:numel(diary_txt_fnames)
            
            text = fileread(diary_txt_fnames{run_i});
            pattern = '\d+\.?\d*'; 
            numericMatrix = cellfun(@str2double, regexp(text, pattern, 'match'));
            numericDat = unique(numericMatrix, 'stable');

            diary_mat.potential_outliers(run_i) = numericDat(2);
            diary_mat.percent_spikes(run_i) = numericDat(3);
            diary_mat.global_SNR(run_i) = numericDat(4);
            diary_mat.outliers_RMSSD_percent(run_i) = numericDat(5);
            diary_mat.outliers_RMSSD_imgs(run_i) = numericDat(6);
            
        end

        save(diary_mat_fname, 'diary_mat');
    end

end

save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC
end