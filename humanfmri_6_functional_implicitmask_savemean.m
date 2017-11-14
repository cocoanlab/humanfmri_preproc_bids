function PREPROC = humanfmri_6_functional_implicitmask_savemean(subject_dir)

% This function creates and saves implicit mask (top 95% of voxels above
% the mean value) and mean functional images (before any preprocessing) in 
% the subject direcotry. The mean functional images can be used for coregistration.
% If you want to use multiple run data, you can simply put multiple numbers
% in session_num. e.g., session_num = 1:10 (run1 to 10).
%
% :Usage:
% ::
%        humanfmri_6_functional_implicitmask_savemean(subject_dir)
%
% :Input:
% ::
%    - subject_dir            subject directory
%
%
% :Output(PREPROC):
% ::
%    PREPROC.implicit_mask_file
%    PREPROC.mean_before_preproc
%    saves implicit_mask.nii and mean_func_before_preproc_image.nii in subject_dir
%
% ..
%     Author and copyright information:
%
%     Copyright (C) Apr 2017  Choong-Wan Woo
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

PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC

PREPROC.preproc_outputdir = fullfile(PREPROC.study_imaging_dir, 'preprocessed', PREPROC.subject_code);
if ~exist(PREPROC.preproc_outputdir), mkdir(PREPROC.preproc_outputdir); end

[~, ~, ~, ~, outputname] = fmri_mask_thresh_canlab(char(PREPROC.func_bold_files),...
    fullfile(PREPROC.preproc_outputdir, 'implicit_mask.nii'));

PREPROC.implicit_mask_file = outputname;

PREPROC.preproc_func_dir = fullfile(PREPROC.preproc_outputdir, 'func'); 
mkdir(PREPROC.preproc_func_dir);

PREPROC.preproc_anat_dir = fullfile(PREPROC.preproc_outputdir, 'anat'); 
mkdir(PREPROC.preproc_anat_dir);

for i = 1:numel(PREPROC.func_bold_files)
    dat = fmri_data(char(PREPROC.func_bold_files{i}), PREPROC.implicit_mask_file);
    mdat = mean(dat);
    [~, b] = fileparts(PREPROC.func_bold_files{i});
    
    mdat.fullpath = fullfile(PREPROC.preproc_func_dir, ['mean_beforepreproc_' b '.nii']);
    PREPROC.mean_before_preproc{i,1} = mdat.fullpath;
    write(mdat);
end

save_load_PREPROC(PREPROC.preproc_outputdir, 'save', PREPROC); % save PREPROC

end