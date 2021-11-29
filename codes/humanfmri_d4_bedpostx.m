function PREPROC = humanfmri_d4_bedpostx(preproc_subject_dir)

% This function estimate diffusion parameters using fsl's bedpostx.
%
% :Usage:
% ::
%    PREPROC = humanfmri_d4_bedpostx(preproc_subject_dir)
%
%    e.g. 
%       humanfmri_d4_bedpostx(preproc_subject_dir)
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
%     PREPROC.dwi_bedpostx_dir                       bedpostx output directory
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
    print_header('bedpostx', a);
    
    bpxdir = fullfile(PREPROC.preproc_dwi_dir, 'bpxdir');
    if ~exist(bpxdir, 'dir'), mkdir(bpxdir); end
    copyfile(PREPROC.dwi_cleaned_nii_file, fullfile(bpxdir, 'data.nii'));
    copyfile(PREPROC.dwi_eddy.brainmask, fullfile(bpxdir, 'nodif_brain_mask.nii'));
    copyfile(PREPROC.dwi_bvec_files{1}, fullfile(bpxdir, 'bvecs'));
    copyfile(PREPROC.dwi_bval_files{1}, fullfile(bpxdir, 'bvals'));
    PREPROC.dwi_bedpostx_dir = fullfile(PREPROC.preproc_dwi_dir, 'bpxdir.bedpostX');
    
    system(['export FSLOUTPUTTYPE=NIFTI; bedpostx ' PREPROC.dwi_bedpostx_dir]);
    
    PREPROC = save_load_PREPROC(preproc_subject_dir{subj_i}, 'save', PREPROC);
end

end