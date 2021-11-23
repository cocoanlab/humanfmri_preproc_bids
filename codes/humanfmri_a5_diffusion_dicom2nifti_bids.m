function PREPROC = humanfmri_a5_diffusion_dicom2nifti_bids(subject_code, study_imaging_dir, varargin)

% This function saves the dicom files into nifti and jason files in the dwi
% image directory (subject_dir/dwi). 
%
% :Usage:
% ::
%    PREPROC = humanfmri_a5_diffusion_dicom2nifti_bids(subject_code, study_imaging_dir)
%
%
% :Input:
% 
% - subject_code    the subject id
%                   (e.g., subject_code = {'sub-caps001', 'sub-caps002'});
% - study_imaging_dir  the directory information for the study imaging data
%                      (e.g., study_imaging_dir = '/NAS/data/CAPS2/Imaging')
%
% :Optional input:
% - 'dicom_pattern'         expression pattern of dicom files
%                           (default: *IMA)
%
% :Output(PREPROC):
%
%   PREPROC.dwi_files (in nifti)
%
% :Example:
%  
%   PREPROC = humanfmri_a2_structural_dicom2nifti_bids(subject_code, study_imaging_dir)
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

dicom_pattern = '*IMA';

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case {'dicom_pattern'}
                dicom_pattern = varargin{i+1};
        end
    end
end

if ~iscell(subject_code)
    subject_codes{1} = subject_code;
else
    subject_codes = subject_code;
end


for subj_i = 1:numel(subject_codes)
    
    subject_dir = fullfile(study_imaging_dir, 'raw', subject_codes{subj_i});
    
    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC
    
    outdir = fullfile(PREPROC.subject_dir, 'dwi');
    datdir = fullfile(PREPROC.subject_dir, 'dicom', 'dwi');
    
    if ~exist(outdir, 'dir')
        mkdir(outdir);
    end
    
    [imgdir, subject_id] = fileparts(subject_dir);
    studydir = fileparts(imgdir);
    
    outdisdaqdir = fullfile(studydir, 'disdaq_dcmheaders', subject_id);
    if ~exist(outdisdaqdir, 'dir'), mkdir(outdisdaqdir); end
    
    dicom_imgs = filenames(fullfile(datdir, dicom_pattern)); % depth 1
    if isempty(dicom_imgs) || sum(contains(dicom_imgs, 'no matches found'))==1, dicom_imgs = filenames(fullfile(datdir, '*/*IMA')); end % depth 2
    if isempty(dicom_imgs) || sum(contains(dicom_imgs, 'no matches found'))==1, dicom_imgs = filenames(fullfile(datdir, '*/*/*IMA')); end % depth 3
    if isempty(dicom_imgs) || sum(contains(dicom_imgs, 'no matches found'))==1, error('Can''t find dicom files. Please check.'); end
    
    dicm2nii(dicom_imgs, outdir, 4, 'save_json');
    out = load(fullfile(outdir, 'dcmHeaders.mat'));
    f = fields(out.h);
    
    %% **** 3d to 4d ****
    
    cd(outdir);
    
    nifti_3d = filenames([f{1} '_*.nii']);
    
    disp('Converting 3d images to 4d images...')
    spm_file_merge(nifti_3d, [f{1} '.nii']);
    
    system(['cd ' outdir '; rm ' f{1} '_*.nii']);
    
    info.source = f{1};
    [~, subj_id] = fileparts(PREPROC.subject_dir);
    info.target = [subj_id '_dwi'];
    
    %%
    
    filetype = {'nii', 'json', 'bval', 'bvec', 'mat'};
    
    for i = 1:numel(filetype)
        source_file = fullfile(outdir, [info.source '.' filetype{i}]);
        target_file = fullfile(outdir, [info.target '.' filetype{i}]);
        system(['mv ' source_file ' ' target_file]);
        
        if i ~= 5
            eval(['PREPROC.dwi_' filetype{i} '_files = {''' target_file '''};']);
        end
    end
    
    eval(['h = out.h.' info.source ';']);
    output_dcmheaders_fnames = fullfile(outdisdaqdir, sprintf('%s_dwi', subj_id));
    save([output_dcmheaders_fnames '_dcmheaders.mat'], 'h');
    system(['rm ' fullfile(outdir, 'dcmHeaders.mat')]);
    
    save_load_PREPROC(PREPROC.subject_dir, 'save', PREPROC); % save PREPROC
end

end
