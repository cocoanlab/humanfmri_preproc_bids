function PREPROC = humanfmri_d2_eddycurrent_correction(preproc_subject_dir)

% This function applies the eddy current correction for diffusion data using fsl's eddy.
%
% :Usage:
% ::
%    PREPROC = humanfmri_d2_eddycurrent_correction(preproc_subject_dir)
%
%    e.g. 
%       humanfmri_d2_eddycurrent_correction(preproc_subject_dir)
%
% :Input:
% 
% - preproc_subject_dir     the subject directory for preprocessed data
%                           (PREPROC.preproc_outputdir)
%
% :Optional Input:
%
% :Output:
% ::
%     PREPROC.dwi_distortion_correction_out          fmap combined
%     PREPROC.dwi_eddy_correction_idxfile            index file for eddy    
%     PREPROC.dwi_eddy.brainmask
%                     .eddy_out                      eddy outputs
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
    print_header('eddy correction', a);
    
    PREPROC.dwi_eddy.meanfmap = fullfile(PREPROC.preproc_dwi_dir, 'eddy_mean.nii');
    PREPROC.dwi_eddy.brainmask = fullfile(PREPROC.preproc_dwi_dir, 'eddy_mean_mask.nii');
    system(['export FSLOUTPUTTYPE=NIFTI; fslmaths ', [PREPROC.dwi_topup.topup_unwarped '.nii'], ' -Tmean ', PREPROC.dwi_eddy.meanfmap]);
    system(['export FSLOUTPUTTYPE=NIFTI; bet ', PREPROC.dwi_eddy.meanfmap, ' ', PREPROC.dwi_eddy.meanfmap, ' -n -m -f 0.3']);
    dwi_vol = spm_vol(PREPROC.dwi_nii_files{1});
    PREPROC.dwi_eddy_correction_idxfile = fullfile(PREPROC.preproc_dwi_dir, 'eddy_idx.txt');
    writematrix(ones(1, numel(dwi_vol)), PREPROC.dwi_eddy_correction_idxfile, 'Delimiter', ' ');
    PREPROC.dwi_eddy.eddy_out = fullfile(PREPROC.preproc_dwi_dir, 'eddy_out');
    system(['export FSLOUTPUTTYPE=NIFTI;' ...
        ' eddy' ...
        ' --imain=' PREPROC.dwi_nii_files{1} ...
        ' --mask=' PREPROC.dwi_eddy.brainmask ...
        ' --index=' PREPROC.dwi_eddy_correction_idxfile ...
        ' --acqp=' PREPROC.dwi_distortion_correction_parameter ...
        ' --bvecs=' PREPROC.dwi_bvec_files{1} ...
        ' --bvals=' PREPROC.dwi_bval_files{1} ...
        ' --topup=' PREPROC.dwi_topup.topup_out ...
        ' --out=' PREPROC.dwi_eddy.eddy_out ...
        ' --data_is_shelled']); % assumes multishell data
    PREPROC.dwi_cleaned_nii_file = [PREPROC.dwi_eddy.eddy_out '.nii'];
    
    eddy_quad <eddy_output_basename> -idx <eddy_index_file> -par <eddy_acqparams_file> -m <nodif_mask> -b <bvals>
    system(['export FSLOUTPUTTYPE=NIFTI;' ...
        ' eddy_quad' ...
        ' ' PREPROC.dwi_eddy.eddy_out ...
        ' -idx ' PREPROC.dwi_eddy_correction_idxfile ...
        ' -par ' PREPROC.dwi_distortion_correction_parameter ...
        ' -m ' PREPROC.dwi_eddy.brainmask ...
        ' -b ' PREPROC.dwi_bval_files{1}]); % assumes multishell data
    open(fullfile([PREPROC.dwi_eddy.eddy_out '.qc'], 'qc.pdf'));
    
    PREPROC = save_load_PREPROC(preproc_subject_dir{subj_i}, 'save', PREPROC);
end

end