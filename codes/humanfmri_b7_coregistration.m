function PREPROC = humanfmri_b7_coregistration(preproc_subject_dir, use_sbref, varargin)

% This function does coregistration between anatomical T1 image and 
% mean_ra_functional or sbref images (functional images after realigned).
%
% :Usage:
% ::
%      PREPROC = humanfmri_b7_coregistration(preproc_subject_dir)
%
%
% :Input:
% 
% - preproc_subject_dir     the subject directory for preprocessed data
%                             (PREPROC.preproc_outputdir)
% - use_sbref               true or false. 
%                           if true, the first image of sbref will be used 
%                              for coregistration
%                           if false, the first image of the functional
%                              images (dcr_func( will be used. 
%
% :Optional input:
% - 'no_dc'                 if you did not run distortion correction before 
%                           coregistration, please use this option.
%
% - 'no_check_reg'          no check regisration. If you want to run all
%                           the subject without any interaction, this will 
%                           be helpful.
%
% :Output(PREPROC):
% ::
%   PREPROC.coreg_job
%   PREPROC.coreg_anat_file
%   
% ..
%     Author and copyright information:
%
%     Copyright (C) Jan 2018  Choong-Wan Woo
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

do_check = true;
use_dc = true;
use_ss = false;

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case {'no_check_reg'}
                do_check = false;
            case {'no_dc'}
                use_dc = false;
            case {'skullstrip'}
                use_ss = true;
        end
    end
end

for subj_i = 1:numel(preproc_subject_dir)

    subject_dir = preproc_subject_dir{subj_i};
    cd(subject_dir);
    
    [~,a] = fileparts(subject_dir);
    print_header('Coregistration: ', a);

    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC
    
    [~, c] = fileparts(PREPROC.anat_nii_files{1});
    copyfile(PREPROC.anat_nii_files{1}, PREPROC.preproc_anat_dir);
    
    PREPROC.coreg_anat_file = fullfile(PREPROC.preproc_anat_dir, [c '.nii']);
    if use_ss
        anat_vol = spm_vol(PREPROC.coreg_anat_file);
        anat_dat = spm_read_vols(anat_vol);
        disp('FSL BET is working for skullstripping on T1w');
        system(sprintf('export FSLOUTPUTTYPE=NIFTI; bet %s %s -f 0.3', ...
            PREPROC.coreg_anat_file, PREPROC.coreg_anat_file));
    end
    
    def = spm_get_defaults('coreg');
    
    if use_sbref 
        if use_dc
            matlabbatch{1}.spm.spatial.coreg.estimate.ref = PREPROC.dc_func_sbref_files(1);
        else
            matlabbatch{1}.spm.spatial.coreg.estimate.ref = PREPROC.preproc_func_sbref_files(1);
        end
    else
        if use_dc
            matlabbatch{1}.spm.spatial.coreg.estimate.ref = {[PREPROC.dcr_func_bold_files{1} ',1']};
        else
            matlabbatch{1}.spm.spatial.coreg.estimate.ref = {[PREPROC.r_func_bold_files{1} ',1']};
        end
    end
    
    matlabbatch{1}.spm.spatial.coreg.estimate.source = {PREPROC.coreg_anat_file};
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions = def.estimate;
    
    PREPROC.coreg_job = matlabbatch{1};
    
    spm('defaults','fmri');
    spm_jobman('initcfg');
    spm_jobman('run', {matlabbatch});

    if use_ss
        spm_write_vol(spm_vol(PREPROC.coreg_anat_file), anat_dat);
    end
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC
    
    if do_check
        if use_sbref
            if use_dc
                original = PREPROC.dc_func_sbref_files{1};
            else
                original = PREPROC.preproc_func_sbref_files{1};
            end
        else
            if use_dc
                original = [PREPROC.dcr_func_bold_files{1} ',1'];
            else
                original = [PREPROC.r_func_bold_files{1} ',1'];
            end
        end
        spm_check_registration(PREPROC.coreg_anat_file, original);
    end
    
end

end
