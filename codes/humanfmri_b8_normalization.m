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
% - 'no_check_reg' : The default is to check regitration of the output
%                    images. If you want to skip it, then use this option.
% - 'T1norm' : do T1 norm (default)
% - 'EPInorm' : do EPI norm (but not using EPI, but using TPM.nii)
% - 'lesion_mask' : do masking before segmentation -- can be used for lesion data
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

% options
for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case {'no_check_reg'}
                do_check = false;
            case {'T1norm'}
                do_t1norm = true;
                do_epinorm = false;
            case {'EPInorm'}
                do_t1norm = false;
                do_epinorm = true;
            case {'lesion_mask'}
                use_mask = true;
                mask = varargin{i+1};
        end
    end
end

for subj_i = 1:numel(preproc_subject_dir)

    subject_dir = preproc_subject_dir{subj_i};
    [~,a] = fileparts(subject_dir);
    cd(subject_dir);
    
    print_header('Segmentation and Normalization ', a);
    
    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC
    
    %% Segmentation
    
    load(which('segment_job.mat'));
    
    for i = 1:6
        matlabbatch{1}.spm.spatial.preproc.tissue(i).tpm{1} = [which('TPM.nii') ',' num2str(i)];
    end
    
    if do_epinorm
    
        if use_sbref
            matlabbatch{1}.spm.spatial.preproc.channel.vols{1} = PREPROC.dc_func_sbref_files{1};
        else
            matlabbatch{1}.spm.spatial.preproc.channel.vols{1} = [PREPROC.r_func_bold_files{1} ',1'];
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
    matlabbatch{2}.spm.spatial.normalise.write.subj.resample = PREPROC.r_func_bold_files;
    
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
    PREPROC.wr_func_bold_files = prepend_a_letter(PREPROC.r_func_bold_files, ones(size(PREPROC.r_func_bold_files)), 'w');
    
    for run_i = 1:numel(PREPROC.wr_func_bold_files)
        dat = fmri_data(PREPROC.wr_func_bold_files{run_i});
        mdat = mean(dat);

        [~, b] = fileparts(PREPROC.wr_func_bold_files{run_i });
        mdat.fullpath = fullfile(PREPROC.preproc_mean_func_dir, ['mean_' b '.nii']);
        PREPROC.mean_wr_func_bold_files{run_i,1} = mdat.fullpath; % output
        write(mdat);
    end
    
    canlab_preproc_show_montage(PREPROC.mean_wr_func_bold_files);
    drawnow;
    
    mean_wr_func_bold_png = fullfile(PREPROC.qcdir, 'mean_wr_func_bold.png'); % Scott added some lines to actually save the spike images
    saveas(gcf,mean_wr_func_bold_png);
    
    close all;
    canlab_preproc_show_montage(PREPROC.segmentation);
    drawnow;
    
    seg_png = fullfile(PREPROC.qcdir, 'segmentation.png'); % Scott added some lines to actually save the spike images
    saveas(gcf,seg_png);    
    
    % warping anatomical image
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
    
    PREPROC.wcoreg_anat_file = prepend_a_letter({PREPROC.coreg_anat_file}, ones(size(PREPROC.r_func_bold_files)), 'w');
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC

end

if do_check
    spm_check_registration(which('keuken_2014_enhanced_for_underlay.img'), PREPROC.wcoreg_anat_file);
end

end
