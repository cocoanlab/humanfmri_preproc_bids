function PREPROC = humanfmri_b9_ICA_AROMA(preproc_subject_dir, varargin)

% This function runs ICA-AROMA using python.
% (github: https://github.com/rhr-pruim/ICA-AROMA)
%
% :Usage:
% ::
%    PREPROC = humanfmri_b9_ICA_AROMA(preproc_subject_dir)
%
%
% :Input:
% ::
%
% - preproc_subject_dir     the subject directory for preprocessed data
%                             (PREPROC.preproc_outputdir)
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
%     Copyright (C) Nov 2017  Choong-Wan Woo and Jaejoon Lee
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

% you can change the default for your computer
ica_aroma_dir = '/Users/clinpsywoo/github/ICA-AROMA';
anaconda_dir = '/Users/clinpsywoo/anaconda/bin';

for i = 1:numel(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case {'ica_aroma_dir'} % in seconds
                ica_aroma_dir = varargin{i+1};
            case {'anaconda_dir'}
                anaconda_dir = varargin{i+1};
        end
    end
end

%% Path setup!

setenv('PATH', [getenv('PATH') ':/usr/local/fsl/bin']);
setenv('FSLOUTPUTTYPE','NIFTI_GZ');

setenv('FSLDIR', '/usr/local/fsl');
fsldir = getenv('FSLDIR');
fsldirmpath = sprintf('%s/etc/matlab',fsldir);
path(path, fsldirmpath);
clear fsldir fsldirmpath;

addpath(genpath(ica_aroma_dir));
addpath(genpath(anaconda_dir))

ica_aroma = fullfile(ica_aroma_dir, 'ICA_AROMA.py');

for subj_i = 1:numel(preproc_subject_dir)

    subject_dir = preproc_subject_dir{subj_i};
    [~,a] = fileparts(subject_dir);
    print_header('ICA-AROMA', a);

    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC

    for run_i = 1:numel(PREPROC.swr_func_bold_files)
        
        [d, f] = fileparts(PREPROC.swr_func_bold_files{run_i});
        mvmt_fname = fullfile(d, ['mvmt_' f '.txt']);
        dlmwrite(mvmt_fname, PREPROC.nuisance.mvmt_covariates{run_i});

        system([anaconda_dir '/python2.7 ' ica_aroma ' -in ' PREPROC.swr_func_bold_files{run_i} ' -out ' PREPROC.preproc_func_dir ' -mc ' mvmt_fname ' -tr ' num2str(PREPROC.TR)]);
    end

end







% 
% matlabbatch{9}.spm.spatial.smooth.data(1) = cfg_dep('Normalise: Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{8}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
%   matlabbatch{9}.spm.spatial.smooth.fwhm = [6 6 6];
%   matlabbatch{9}.spm.spatial.smooth.dtype = 0;
%   matlabbatch{9}.spm.spatial.smooth.im = 0;
%   matlabbatch{9}.spm.spatial.smooth.prefix = 's';

for subj_i = 1:numel(preproc_subject_dir)

    subject_dir = preproc_subject_dir{subj_i};
    [~,a] = fileparts(subject_dir);
    print_header(['Smoothing: FWHM ' num2str(fwhm) 'mm'], a);

    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC
    
    matlabbatch = {};
    matlabbatch{1}.spm.spatial.smooth.prefix = 's';
    matlabbatch{1}.spm.spatial.smooth.dtype = 0; % data type; 0 = same as before
    matlabbatch{1}.spm.spatial.smooth.im = 0; % implicit mask; 0 = no
    matlabbatch{1}.spm.spatial.smooth.fwhm = repmat(fwhm, 1, 3); % override whatever the defaults were with this
    matlabbatch{1}.spm.spatial.smooth.data = PREPROC.wr_func_bold_files;
    
    % Save the job
    PREPROC.smoothing_job = matlabbatch;
    PREPROC.swr_func_bold_files = prepend_a_letter(PREPROC.wr_func_bold_files, ones(size(PREPROC.wr_func_bold_files)), 's');

    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC

    spm('defaults','fmri');
    spm_jobman('initcfg');
    spm_jobman('run', matlabbatch);

    for run_i = 1:numel(PREPROC.swr_func_bold_files)
        dat = fmri_data(PREPROC.swr_func_bold_files{run_i});
        mdat = mean(dat);

        [~, b] = fileparts(PREPROC.swr_func_bold_files{run_i });
        mdat.fullpath = fullfile(PREPROC.preproc_mean_func_dir, ['mean_' b '.nii']);
        PREPROC.mean_swr_func_bold_files{run_i,1} = mdat.fullpath; % output
        write(mdat);
    end
    
    canlab_preproc_show_montage(PREPROC.mean_swr_func_bold_files);
    drawnow;
    
    mean_swr_func_bold_png = fullfile(PREPROC.qcdir, 'mean_swr_func_bold.png'); % Scott added some lines to actually save the spike images
    saveas(gcf,mean_swr_func_bold_png);

end