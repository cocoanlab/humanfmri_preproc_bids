function PREPROC = humanfmri_4_fieldmap_dicom2nifti_bids(subject_dir)

% This function saves the dicom files (subject_dir/dicoms/fmap/*) into 
% nifti files in the fmap directory (subject_dir/fmap/sub-, e.g., r01). 
%
% :Usage:
% ::
%    PREPROC = humanfmri_4_fieldmap_dicom2nifti_bids(subject_dir)
%
% :Input:
% 
% - subject_dir     the subject directory, which should contain dicom data
%
%
% :Output(PREPROC):
% ::
%     PREPROC.func_files{session_num} (4d nifti)
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

fmap_dir = filenames(fullfile(PREPROC.dicom_dirs{1}, 'fmap*'), 'char', 'absolute');

% set the directory
outdir = fullfile(subject_dir, 'fmap');
if ~exist(outdir, 'dir'), mkdir(outdir); end

cd(fmap_dir); 

dicom_imgs = filenames('*/*IMA', 'absolute');

%% PA
dicm2nii(dicom_imgs(1:2), outdir, 4, 'save_json');
out = load(fullfile(outdir, 'dcmHeaders.mat'));
f = fields(out.h);

cd(outdir);
nifti_3d = filenames([f{1} '*.nii']);

[~, subj_id] = fileparts(PREPROC.subject_dir);
output_4d_fnames = fullfile(outdir, sprintf('%s_dir_pa_epi', subj_id));
    
disp('Converting 3d images to 4d images...')
spm_file_merge(nifti_3d, [output_4d_fnames '.nii']);
    
delete(fullfile(outdir, [f{1} '*nii']))
    
% == change the json file name and save PREPROC
movefile(fullfile(outdir, [f{1} '.json']), [output_4d_fnames '.json']);

%% AP
dicm2nii(dicom_imgs(3:4), outdir, 4, 'save_json');
out = load(fullfile(outdir, 'dcmHeaders.mat'));
f = fields(out.h);

nifti_3d = filenames([f{2} '*.nii']);

[~, subj_id] = fileparts(PREPROC.subject_dir);
output_4d_fnames = fullfile(outdir, sprintf('%s_dir-ap_epi', subj_id));
    
disp('Converting 3d images to 4d images...')
spm_file_merge(nifti_3d, [output_4d_fnames '.nii']);
    
delete(fullfile(outdir, [f{2} '*nii']))
    
% == change the json file name and save PREPROC
movefile(fullfile(outdir, [f{2} '.json']), [output_4d_fnames '.json']);

PREPROC.fmap_nii_files = filenames('sub*dir*.nii', 'char');
    
h = out.h;
save([output_4d_fnames '_dcmheaders.mat'], 'h');
delete(fullfile(outdir, 'dcmHeaders.mat'));
   
save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC
disp('Done')

end