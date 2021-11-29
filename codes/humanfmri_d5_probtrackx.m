function PREPROC = humanfmri_d5_probtrackx(preproc_subject_dir, seed_mask)

% This function estimate structural connectivity using fsl's probtrackx.
%
% :Usage:
% ::
%    PREPROC = humanfmri_d5_probtrackx(preproc_subject_dir)
%
%    e.g. 
%       humanfmri_d5_probtrackx(preproc_subject_dir)
%
% :Input:
% 
% - preproc_subject_dir     the subject directory for preprocessed data
%                           (PREPROC.preproc_outputdir)
% - seed_mask               seed mask (e.g., Schaefer atlas)
%
% :Optional Input:
%
% :Output:
% ::  
%     PREPROC.dwi_probtrackx_dir                     probtrackx output directory
%     PREPROC.dwi_probtrackx_seedmask                seed mask (parcellation) for structural connectome
%     PREPROC.dwi_probtrackx_mat                     raw structural connectome
%     PREPROC.dwi_probtrackx_waytotal                total number of tracts for each ROI
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
    
    %%
    
    PREPROC.dwi_probtrackx_seedmask = seed_mask;
    
    [~,a] = fileparts(preproc_subject_dir{subj_i});
    print_header('probtrackx', a);
    
    seed_dir = fullfile(PREPROC.preproc_dwi_dir, 'seed_dir');
    if ~exist(seed_dir, 'dir'), mkdir(seed_dir); end
    seed_vol = spm_vol(PREPROC.dwi_probtrackx_seedmask);
    seed_dat = spm_read_vols(seed_vol);
    u_seed = unique(seed_dat(seed_dat~=0));
    for u_i = 1:numel(u_seed)
        seed_dat_each = seed_dat == u_seed(u_i);
        seed_vol_each = seed_vol;
        seed_vol_each.fname = fullfile(seed_dir, sprintf('seed_split_%.4d.nii', u_i));
        seed_vol_each.dt = [2 0];
        spm_write_vol(seed_vol_each, seed_dat_each);
    end
    seed_vol_list = filenames(fullfile(seed_dir, 'seed_split_*.nii'), 'char');
    seed_vol_list_file = fullfile(PREPROC.preproc_dwi_dir, 'seed_split_list.txt');
    writematrix(seed_vol_list, seed_vol_list_file);
    
    PREPROC.dwi_probtrackx_dir = fullfile(PREPROC.preproc_dwi_dir, 'probtrackx');
    system(['export FSLOUTPUTTYPE=NIFTI;' ...
        ' probtrackx2' ...
        ' --samples=' PREPROC.dwi_bedpostx_dir '/merged' ...
        ' --mask=' PREPROC.dwi_eddy.brainmask ...
        ' --seed=' seed_vol_list_file ...
        ' --xfm=' PREPROC.merged_MNItoDWI ...
        ' --invxfm=' PREPROC.merged_DWItoMNI ...
        ' --loopcheck' ...
        ' --onewaycondition' ...
        ' --forcedir' ...
        ' --opd' ...
        ' --network' ...
        ' --dir=' PREPROC.dwi_probtrackx_dir]);
    PREPROC.dwi_probtrackx_mat = fullfile(PREPROC.dwi_probtrackx_dir, 'fdt_network_matrix');
    PREPROC.dwi_probtrackx_waytotal = fullfile(PREPROC.dwi_probtrackx_dir, 'waytotal');
    
    figure;
    A = load(PREPROC.dwi_probtrackx_mat, '-ASCII');
    w = load(PREPROC.dwi_probtrackx_waytotal, '-ASCII');
    imagesc(A ./ w, [0 0.2]);
    colorbar;
    title('Structural connectome, normalized'); 
    xlabel('ROI');
    ylabel('ROI');
    set(gca, 'FontSize', 16);
    set(gcf, 'color', 'w');

    PREPROC = save_load_PREPROC(preproc_subject_dir{subj_i}, 'save', PREPROC);
end

end