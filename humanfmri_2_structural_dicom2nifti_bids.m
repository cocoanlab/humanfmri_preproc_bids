function PREPROC = humanfmri_2_structural_dicom2nifti_bids(subject_dir)

% This function saves the dicom files into nifti and jason files in the anat
% image directory (subject_dir/anat). 
%
% :Usage:
% ::
%    PREPROC = humanfmri_2_structural_dicom2nifti_bids(subject_dir)
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
% :Example:
%  
%   subject_dir = '/Users/clinpsywoo/Dropbox/projects/ongoing_projects/preproc_pipeline/CAPS2_preproc_test/Imaging/caps001';
%   PREPROC = humanfmri_2_structural_dicom2nifti_bids(subject_dir)
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

outdir = fullfile(PREPROC.subject_dir, 'anat');
datdir = fullfile(PREPROC.subject_dir, 'dicom', 'anat');

if ~exist(outdir, 'dir')
    mkdir(outdir);
end

dicom_imgs = filenames(fullfile(datdir, '*IMA')); % depth 1
if isempty(dicom_imgs), dicom_imgs = filenames(fullfile(datdir, '*/*IMA')); end % depth 2
if isempty(dicom_imgs), dicom_imgs = filenames(fullfile(datdir, '*/*/*IMA')); end % depth 3
if isempty(dicom_imgs), error('Can''t find dicom files. Please check.'); end

dicm2nii(dicom_imgs, outdir, 4, 'save_json');
out = load(fullfile(outdir, 'dcmHeaders.mat'));
f = fields(out.h);

info.source = f{1};
[~, subj_id] = fileparts(PREPROC.subject_dir);
info.target = ['sub-' subj_id '_T1w'];

filetype = {'nii', 'json'};

for i = 1:numel(filetype)
    source_file = fullfile(outdir, [info.source '.' filetype{i}]);
    target_file = fullfile(outdir, [info.target '.' filetype{i}]);
    movefile(source_file, target_file);
    
    eval(['PREPROC.anat_' filetype{i} '_files = {''' target_file '''};']);
end

eval(['h = out.h.' info.source ';']);
save(fullfile(outdir, 'anat_dcm_headers.mat'), 'h');
delete(fullfile(outdir, 'dcmHeaders.mat'));

save_load_PREPROC(PREPROC.subject_dir, 'save', PREPROC); % save PREPROC

end
