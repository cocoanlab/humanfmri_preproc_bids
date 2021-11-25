function PREPROC = humanfmri_d3_dtifit_registration(preproc_subject_dir, epi_enc_dir)

% This function applys diffusion tensor model for dwi data using fsl's dtifit,
% and get registration parameter from dwi to MNI.
%
% :Usage:
% ::
%    PREPROC = humanfmri_d3_dtifit_registration(preproc_subject_dir, epi_enc_dir)
%
%    e.g. 
%       humanfmri_d3_dtifit_registration(preproc_subject_dir, epi_enc_dir)
%
% :Input:
% 
% - preproc_subject_dir     the subject directory for preprocessed data
%                           (PREPROC.preproc_outputdir)
%
% - epi_enc_dir     EPI phase encoding direction: Now this works only for
%                   A->P or P->A. Input should be 'ap' or 'pa'. See the
%                   example above.
%
% :Optional Input:
%
% :Output:
% ::  
%     PREPROC.dwi_dtifit.dtifit_out                  dtifit outputs
%     PREPROC.coreg_anat_file_betfordwi
%     PREPROC.epireg_out
%     PREPROC.fnirt_T1toMNI_warpfield
%     PREPROC.fnirt_MNItoT1warpfield
%     
%
% ..
%     Author and copyright information:
%
%     Copyright (C) Nov 2021  Jae-Joong Lee
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

%% add fsl path 
setenv('PATH', [getenv('PATH') ':/usr/local/fsl/bin']);

%% Load PREPROC
for subj_i = 1:numel(preproc_subject_dir)

    PREPROC = save_load_PREPROC(preproc_subject_dir{subj_i}, 'load'); % load PREPROC       
    
    %% Generate brain mask
    
    [~,a] = fileparts(preproc_subject_dir{subj_i});
    print_header('dtifit', a);
    
    PREPROC.dwi_dtifit.dtifit_out = fullfile(PREPROC.preproc_dwi_dir, 'dtifit_out');
    system(['export FSLOUTPUTTYPE=NIFTI;' ...
        ' dtifit' ...
        ' --data=' PREPROC.dwi_eddy.eddy_out '.nii' ...
        ' --mask=' PREPROC.dwi_eddy.brainmask ...
        ' --bvecs=' PREPROC.dwi_bvec_files{1} ...
        ' --bvals=' PREPROC.dwi_bval_files{1} ...
        ' --out=' PREPROC.dwi_dtifit.dtifit_out]);
    
    PREPROC.coreg_anat_file_betfordwi = fullfile(PREPROC.preproc_anat_dir, [PREPROC.subject_code, '_T1w_bet.nii']);
    system(['export FSLOUTPUTTYPE=NIFTI; bet ', PREPROC.coreg_anat_file, ' ', bet_name, ' -f 0.5']);
    
    if strcmpi(epi_enc_dir, 'ap')
        pedir = '-y';
    elseif strcmpi(epi_enc_dir, 'pa')
        pedir = 'y';
    end
    
    dwi_cleaned = spm_vol([PREPROC.dwi_eddy.eddy_out '.nii']);
    wh_b0 = find(importdata(PREPROC.dwi_bval_files{1}) == 0);
    dwi_cleaned_b0vol = dwi_cleaned(wh_b0(1));
    dwi_cleaned_b0dat = spm_read_vols(dwi_cleaned_b0vol);
    PREPROC.epireg_ref_firstb0 = [PREPROC.dwi_eddy.eddy_out '_firstb0.nii'];
    dwi_cleaned_b0vol.fname = PREPROC.epireg_ref_firstb0;
    spm_write_vol(dwi_cleaned_b0vol, dwi_cleaned_b0dat);
    
    PREPROC.epireg_out = fullfile(PREPROC.preproc_dwi_dir, 'epireg_out');
    PREPROC.epireg_DWItoT1 = [PREPROC.epireg_out '.mat'];
    system(['export FSLOUTPUTTYPE=NIFTI;' ...
        ' epi_reg' ...
        ' --pedir=' pedir ...
        ' --epi=' PREPROC.epireg_ref_firstb0 ...
        ' --t1=' PREPROC.coreg_anat_file ...
        ' --t1brain=' PREPROC.coreg_anat_file_betfordwi ...
        ' --out=' PREPROC.epireg_out]);
    
    % Linear then non-linear registration to MNI
    system(['export FSLOUTPUTTYPE=NIFTI;' ...
        ' flirt' ...
        ' -interp spline' ...
        ' -dof 12' ...
        ' -in ' PREPROC.coreg_anat_file_betfordwi ...
        ' -ref /usr/local/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz' ...
        ' -omat ' fullfile(PREPROC.preproc_dwi_dir, 'T1toMNI_init.mat')]);
    % calculate the just the warp for the surface transform - need it because
    % sometimes the brain is outside the bounding box of warfield
    PREPROC.fnirt_T1toMNI_warpfield = fullfile(PREPROC.preproc_dwi_dir, 'T1toMNI_warpfield.nii');
    system(['export FSLOUTPUTTYPE=NIFTI;' ...
        ' fnirt' ...
        ' --in=' PREPROC.coreg_anat_file...
        ' --ref=/usr/local/fsl/data/standard/MNI152_T1_2mm.nii.gz' ...
        ' --refmask=/usr/local/fsl/data/standard/MNI152_T1_2mm_brain_mask.nii.gz' ...
        ' --aff=' fullfile(PREPROC.preproc_dwi_dir, 'T1toMNI_init.mat') ...
        ' --cout=' fullfile(PREPROC.preproc_dwi_dir, 'T1toMNI_warpcoef.nii') ...
        ' --fout=' PREPROC.fnirt_T1toMNI_warpfield ...
        ' --config=/usr/local/fsl/etc/flirtsch/T1_2_MNI152_2mm.cnf']);
    % merge transforms
    PREPROC.merged_DWItoMNI = fullfile(PREPROC.preproc_dwi_dir, 'DWItoMNI_warpfield.nii');
    system(['export FSLOUTPUTTYPE=NIFTI;' ...
        ' convertwarp' ...
        ' --ref=/usr/local/fsl/data/standard/MNI152_T1_2mm.nii.gz' ...
        ' --warp1=' PREPROC.fnirt_T1toMNI_warpfield ...
        ' --premat=' PREPROC.epireg_DWItoT1 ...
        ' --out=' PREPROC.merged_DWItoMNI ...
        ' --relout']);
    % inverse
    PREPROC.merged_MNItoDWI = fullfile(PREPROC.preproc_dwi_dir, 'MNItoDWI_warpfield.nii');
    system(['export FSLOUTPUTTYPE=NIFTI;' ...
        ' invwarp' ...
        ' -w ' PREPROC.merged_DWItoMNI ...
        ' -o ' PREPROC.merged_MNItoDWI ...
        ' -r ' PREPROC.epireg_ref_firstb0]);
    
    PREPROC = save_load_PREPROC(preproc_subject_dir{subj_i}, 'save', PREPROC);
end

end