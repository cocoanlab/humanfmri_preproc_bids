function PREPROC = humanfmri_b7_coregistration(preproc_subject_dir, use_sbref)

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
%                           for coregistration
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

for subj_i = 1:numel(preproc_subject_dir)

    subject_dir = preproc_subject_dir{subj_i};
    cd(subject_dir);
    
    [~,a] = fileparts(subject_dir);
    print_header('Coregistration: ', a);

    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC
    
    def = spm_get_defaults('coreg');
    
    if use_sbref
        matlabbatch{1}.spm.spatial.coreg.estwrite.ref = PREPROC.dc_func_sbref_files(1);
    else
        matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {PREPROC.mean_r_func_bold_files};
    end
    matlabbatch{1}.spm.spatial.coreg.estwrite.source = PREPROC.anat_nii_files;
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions = def.estimate;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions = def.write;
    
    PREPROC.coreg_job = matlabbatch{1};
    
    spm('defaults','fmri');
    spm_jobman('initcfg');
    spm_jobman('run', {matlabbatch});
    
    [b, c] = fileparts(PREPROC.anat_nii_files{1});
    
    movefile(fullfile(b, ['r' c '.nii']), PREPROC.preproc_anat_dir);
    
    PREPROC.coreg_anat_file = fullfile(PREPROC.preproc_anat_dir, ['r' c '.nii']);
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC
    
    if use_sbref
        spm_check_registration(PREPROC.coreg_anat_file, PREPROC.dc_func_sbref_files{1});
    else
        spm_check_registration(PREPROC.coreg_anat_file, PREPROC.mean_r_func_bold_files);
    end
    
end

end
