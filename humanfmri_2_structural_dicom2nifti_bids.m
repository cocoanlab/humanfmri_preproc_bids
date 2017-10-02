function PREPROC = humanfmri_2_structural_dicom2nifti_bids(PREPROC)

% This function saves the dicom files into nifti and jason files in the anat
% image directory (subject_dir/anat). 
%
% :Usage:
% ::
%    PREPROC = humanfmri_2_structural_dicom2nifti_bids(PREPROC)
%
%
% :Input:
% 
% - PREPROC       PREPROC is saved in subject_dir. It should contain 
%                 information about subject_dir and dicom_dirs. It is 
%                 automatically saved in the previous step
%                 (humanfmri_1_make_directories.m).
%
% :Output(PREPROC):
%
%   PREPROC.anat_files (in nifti)
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

outdir = fullfile(PREPROC.subject_dir, 'anat');
datdir = fullfile(PREPROC.subject_dir, 'dicom', 'anat');

if ~exist(outdir, 'dir')
    mkdir(outdir);
end

[~, h] = dicm2nii(filenames(fullfile(datdir, '*IMA')), outdir, 4);
f = fields(h);

PREPROC.subject_dir = subject_dir;
PREPROC.anat_files = {fullfile(outdir, [f{1} '.nii'])};

save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC

end