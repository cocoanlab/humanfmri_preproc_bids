% ========================================================= %
%                   Possible combinations                   %
% --------------------------------------------------------- %
% 1. 24 parameter + spike covatiates + linear drift         %
% 2. 24 parameter + spike covariates + WM and CSF + linear  %
% drfit                                                     %
% 3. linear drift                                           %
% ========================================================= %
function humanfmri_c3_make_nuisance_regressors(preproc_subject_dir,varargin)

% This funtion is for making and saving nuisance mat files using PREPROC
% files.
%
% :Usage:
%   [filename, fullpath] = make_nuisance_mat(PREPROC,varargin)
%
% :Input:
% ::
%   - preproc_subject_dir: the subject directory for preprocessed data
%                             (PREPROC.preproc_outputdir)
%
% :Optional input
% ::
%   - 'regressors': parameter you want to include
%                   (defaults: 'regressors','{'24Move','Spike','WM_CSF'};)
%                   -> lists of regressors
%                       1. {24Move}: 24 movement parameters
%                       2. {Spike} : spike covariates
%                       3. {WM_CSF}: WM and CSF
%
%   - 'img': if you want to estimate WM and CSF in specific imgs, you can
%            specify field name in PREPROC struture
%           (defaults: 'img','swr_func_bold_files' )
%
%
% :Output:
% ::
%   - PREPROC.nuisacne_descriptions
%   - PREPROC.nuisance_dir
%   - PREPROC.nuisance_files
%   - save 'nuisance mat files' in PREPROC.nuisacne_dir 
%
%
% :Exmaples:
%   - make_nuisance_regressors(PREPROC,'regressors',{'24Move','Spike','WM_CSF'})
%   - make_nuisance_regressors(PREPROC,'img','swr_func_bold_files')
%
%
% ..
%     Author and copyright information:
%
%     Copyright (C) Jan 2019  Suhwan Gim
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

%% parse varagin
do_24params = false;
do_spike_covariates = false;
do_wm_csf = false;
reg_idx = {'24Move','Spike','WM_CSF'}; % defaults

do_specify_img = false;
fieldname = 'swr_func_bold_files';
for i = 1:numel(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case {'regressors'} % in seconds
                reg_idx = varargin{i+1};
            case {'img'}
                fieldname = varargin{i+1};
                do_specify_img = true;
        end
    end
end
%% 
for subj_i = 1:numel(preproc_subject_dir)
    % load PREPROC and Print header
    subject_dir = preproc_subject_dir{subj_i};
    PREPROC = save_load_PREPROC(subject_dir, 'load'); 
    print_header('Make and save nuisance regressors: ', PREPROC.subject_code);
    %% set the nuisance regressors
    disp(':: List of nuisance regresosrs' )
    for j = 1:length(reg_idx)
        switch reg_idx{j}
            case {'24Move','24MoveParams'}
                do_24params = true;
                disp('- 24 movement parameters');
            case {'Spike','Spike_covariates'}
                do_spike_covariates = true;
                disp('- Spike covariates');
            case {'WM_CSF','WMCSF','WhiteMatter_CSF'}
                do_wm_csf = true;
                disp('- White Matter and CSF');
        end
    end
    disp('----------------------------------------------')
    %% set directory
    subj_dir = PREPROC.preproc_outputdir;
    nuisance_dir = fullfile(subj_dir, 'nuisance_mat');
    if ~exist(nuisance_dir, 'dir'), mkdir(nuisance_dir); end
    %% make nuisance.mat
    % warning('No nuisance files. Please check') input('');
    for img_i = 1:numel(PREPROC.nuisance.mvmt_covariates)
        R = [];
        disp(['Run Number   : ' num2str(img_i)]);
        disp('-------------------------------------------');
        disp(['Nuisance file name: ', sprintf('nuisance_run%d.mat', img_i)]);
        disp('-------------------------------------------');
        % 1. 24 movement parameters
        if do_24params
            R = [[PREPROC.nuisance.mvmt_covariates{img_i} PREPROC.nuisance.mvmt_covariates{img_i}.^2 ...
                [zeros(1,6); diff(PREPROC.nuisance.mvmt_covariates{img_i})] [zeros(1,6); diff(PREPROC.nuisance.mvmt_covariates{img_i})].^2]];
        end
        % 2. spike_covariates
        if do_spike_covariates
            R = [R  PREPROC.nuisance.spike_covariates{img_i}];
        end
        % 3. extract and add WM(value2)_CSF(value3)
        if do_wm_csf
            
            if do_specify_img
                eval(['images_by_run = PREPROC.' fieldname]);
            else %defaults
                images_by_run = PREPROC.swr_func_bold_files;
            end
            [~,img_name]=fileparts(images_by_run{img_i});
            disp(['Img File name: ' img_name]);
            [~, components] = extract_gray_white_csf(fmri_data(images_by_run{img_i}));
            % but, see canlab_connectivity_preproc
            R = [R double(components{2}) double(components{3})];
        end
        
        % 4. finally, add linear drift
        R = [R zscore((1:size(R,1))')];
        
        % 5. Save
        savename{img_i} = fullfile(nuisance_dir, sprintf('nuisance_run%d.mat', img_i));
        fprintf('\nsaving... %s\n\n', savename{img_i});
        save(savename{img_i}, 'R');
        
    end
    reg_idx{length(reg_idx)+1} = 'linear drift';
    
    % Save PROPROC
    PREPROC.nuisacne_descriptions = reg_idx;
    PREPROC.nuisance_dir = nuisance_dir;
    PREPROC.nuisance_files = savename;
    
    save_load_PREPROC(subj_dir, 'save', PREPROC); % save PREPROC
end

end

