function PREPROC = humanfmri_b8_normalization(preproc_subject_dir, use_sbref, varargin)

% This function does normalization for the functional data.
%
% :Usage:
% ::
%    PREPROC = humanfmri_b8_normalization(preproc_subject_dir)
%
%
% :Input:
% 
% - preproc_subject_dir     the subject directory for preprocessed data
%                             (PREPROC.preproc_outputdir)
% - use_sbref               1:use sbref image for the normalization
%                           0:use the first functional image for the normalization
%
%
% :Optional Input:
%
% - 'T1norm' : do T1 norm (default)
% - 'EPInorm' : do EPI norm (but not using EPI, but using TPM.nii)
% - 'lesion_mask' : do masking before segmentation -- can be used for lesion data
% - 'no_check_reg' : The default is to check regitration of the output
%                    images. If you want to skip it, then use this option.
% - 'no_dc'          if you did not run distortion correction, please use 
%                    this option.
%
% :Output(PREPROC):
% :: 
%
%    PREPROC.wr_func_bold_files
%    PREPROC.mean_wr_func_bold_files
%    PREPROC.norm_job
%    saves mean_wr_func_bold.png in /qcdir
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

% default
do_check = true;
do_t1norm = true;
do_epinorm = false;
use_mask = false;
use_dc = true;
run_num = [];

% options
for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case {'no_check_reg'}
                do_check = false;
            case {'no_dc'}
                use_dc = false;
            case {'T1norm'}
                do_t1norm = true;
                do_epinorm = false;
            case {'EPInorm'}
                do_t1norm = false;
                do_epinorm = true;
            case {'lesion_mask'}
                use_mask = true;
                mask = varargin{i+1};
            case {'run_num'}
                run_num = varargin{i+1};
        end
    end
end

for subj_i = 1:numel(preproc_subject_dir)

    subject_dir = preproc_subject_dir{subj_i};
    [~,a] = fileparts(subject_dir);
    cd(subject_dir);
    
    print_header('Segmentation and Normalization ', a);
    
    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC
    
    %% Segmentation and warping
    
    load(which('segment_job.mat'));
    
    for i = 1:6
        matlabbatch{1}.spm.spatial.preproc.tissue(i).tpm{1} = [which('TPM.nii') ',' num2str(i)];
    end
    
    if do_epinorm
    
        if use_sbref
            if use_dc
                matlabbatch{1}.spm.spatial.preproc.channel.vols{1} = PREPROC.dc_func_sbref_files{1};
            else
                matlabbatch{1}.spm.spatial.preproc.channel.vols{1} = PREPROC.preproc_func_sbref_files{1};
            end
        else
            if use_dc
                matlabbatch{1}.spm.spatial.preproc.channel.vols{1} = [PREPROC.dcr_func_bold_files{1} ',1'];
            else
                matlabbatch{1}.spm.spatial.preproc.channel.vols{1} = [PREPROC.r_func_bold_files{1} ',1'];
            end
        end
        
        
    elseif do_t1norm
    
        if use_mask
            dat = fmri_data(PREPROC.coreg_anat_file, PREPROC.coreg_anat_file);
            
            % smoothing the mask a little bit (with .5 mm FWHM kernel)
            dat_mask = fmri_data(mask, PREPROC.coreg_anat_file);
            dat_mask = preprocess(dat_mask, 'smooth', .5); % smoothing
            dat.dat = dat.dat .* double(dat_mask.dat==0);
            
            [a, b] = fileparts(PREPROC.coreg_anat_file);
            dat.fullpath = fullfile(a, ['masked_' b '.nii']);
            write(dat);
            
            PREPROC.masked_coreg_anat_file = dat.fullpath;
            
            matlabbatch{1}.spm.spatial.preproc.channel.vols{1} = PREPROC.masked_coreg_anat_file;
        else
            matlabbatch{1}.spm.spatial.preproc.channel.vols{1} = PREPROC.coreg_anat_file;
        end
    
    end
    
    [b,c] = fileparts(matlabbatch{1}.spm.spatial.preproc.channel.vols{1});
    deformation_nii = fullfile(b, ['y_' c '.nii']);
    
    matlabbatch{2}.spm.spatial.normalise.write.subj.def = {deformation_nii};
    
    %% RUNS TO INCLUDE
    do_preproc = true(numel(PREPROC.r_func_bold_files),1);
    if ~isempty(run_num)
        do_preproc(~ismember(1:numel(PREPROC.r_func_bold_files), run_num)) = false;
        % delete existed output files
        if use_dc
            existed_file = prepend_a_letter(PREPROC.dcr_func_bold_files(run_num), ones(size(PREPROC.dcr_func_bold_files(run_num))), 'w');
        else
            existed_file = prepend_a_letter(PREPROC.r_func_bold_files(run_num), ones(size(PREPROC.r_func_bold_files(run_num))), 'w');
        end
        for z = 1:numel(existed_file)
            if exist(existed_file{z})
                delete(existed_file{z})
            end
        end
    end
    
    if use_dc
        matlabbatch{2}.spm.spatial.normalise.write.subj.resample = PREPROC.dcr_func_bold_files(do_preproc);
    else
        matlabbatch{2}.spm.spatial.normalise.write.subj.resample = PREPROC.r_func_bold_files(do_preproc);
    end
    
    matlabbatch{2}.spm.spatial.normalise.write.woptions.bb = [-78  -112   -70
                                                              78    76    85];                                                      
    matlabbatch{2}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
    matlabbatch{2}.spm.spatial.normalise.write.woptions.interp = 4;
    matlabbatch{2}.spm.spatial.normalise.write.woptions.prefix = 'w';
    
    spm('defaults','fmri');
    spm_jobman('initcfg');
    spm_jobman('run', {matlabbatch});

    PREPROC.norm_job = matlabbatch;
    PREPROC.deformation_file = deformation_nii;
    for ii = 1:5
        PREPROC.segmentation{ii} = fullfile(b, ['c' num2str(ii) c '.nii']);
    end
    
    if use_dc
        PREPROC.wr_func_bold_files = prepend_a_letter(PREPROC.dcr_func_bold_files, ones(size(PREPROC.dcr_func_bold_files)), 'w');
    else
        PREPROC.wr_func_bold_files = prepend_a_letter(PREPROC.r_func_bold_files, ones(size(PREPROC.r_func_bold_files)), 'w');
    end
    
    for run_i = find(do_preproc)' %1:numel(PREPROC.wr_func_bold_files)
        dat = fmri_data(PREPROC.wr_func_bold_files{run_i});
        mdat = mean(dat);

        [~, b] = fileparts(PREPROC.wr_func_bold_files{run_i });
        mdat.fullpath = fullfile(PREPROC.preproc_mean_func_dir, ['mean_' b '.nii']);
        PREPROC.mean_wr_func_bold_files{run_i,1} = mdat.fullpath; % output
        write(mdat);
    end
    
    mean_wr_func_bold_png = fullfile(PREPROC.qcdir, 'mean_wr_func_bold.png'); 
    canlab_preproc_show_montage(PREPROC.mean_wr_func_bold_files, mean_wr_func_bold_png);
    drawnow;
    
    close all;
    
    seg_png = fullfile(PREPROC.qcdir, 'segmentation.png'); 
    canlab_preproc_show_montage(PREPROC.segmentation, seg_png);
    drawnow;
    
    %% warping anatomical image
    clear matlabbatch;
    
    matlabbatch{1}.spm.spatial.normalise.write.subj.def = {deformation_nii};
    matlabbatch{1}.spm.spatial.normalise.write.subj.resample = {PREPROC.coreg_anat_file};
    
    matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78  -112   -70
                                                              78    76    85];                                                      
    matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
    matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
    matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w';
    
    spm('defaults','fmri');
    spm_jobman('initcfg');
    spm_jobman('run', {matlabbatch});
    
    PREPROC.wcoreg_anat_file = prepend_a_letter({PREPROC.coreg_anat_file}, ones(size(PREPROC.coreg_anat_file)), 'w');
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC

end

if do_check
    spm_check_registration(which('keuken_2014_enhanced_for_underlay.img'), PREPROC.wcoreg_anat_file{1});
end

end
