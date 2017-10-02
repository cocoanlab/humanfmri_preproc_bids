function PREPROC = humanfmri_3_functional_dicom2nifti_bids(subject_dir, disdaq_n)

% This function saves the dicom files (subject_dir/dicoms/func/r**) into 
% nifti files in the Functional image directory (subject_dir/func/sub-, e.g., r01). 
%
% :Usage:
% ::
%    PREPROC = humanfmri_functional_1_dicom2nifti(subject_dir, session_n, disdaq_n)
%
%    e.g. 
%       session_num = 1;
%       disdaq = 5;
%       PREPROC = humanfmri_functional_1_dicom2nifti(subject_dir, session_num, disdaq);
%
% :Input:
% 
% - subject_dir     the subject directory, which should contain dicom data
%                   within the '/Functional/dicom/r##' directory 
%                   (e.g., subject_dir/Functional/dicom/r01)
% - session_number  the number of session, e.g., session_number = 1
%                   or multiple sessions, e.g., session_number = 1:10
% - disdaq          the number of images you want to discard (to allow for
%                   image intensity stablization)
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

func_dirs = filenames(fullfile(PREPROC.dicom_dirs{1}, 'func*'));

if numel(disdaq_n) == 1
    disdaq_n = repmat(disdaq_n, numel(func_dirs), 1);
end

for i = 1:numel(func_dirs)
    [~, func_names{i,1}] = fileparts(func_dirs{i});
end

t = table(func_names, disdaq_n);
s = input('Is the disdaq_n correct? (Y or N) ', 's');

if strcmp(s, 'N')
    error('Please check the disdaq numbers, and run this again.');
end

for i = 1:numel(func_dirs)
    
    str{1} = repmat('-', 1, 60); str{3} = str{1};
    str{2} = ['Working on ' func_names{i}];
    for j = 1:numel(str), disp(str{j}); end
    
    outdir = fullfile(subject_dir, 'func');
    if ~exist(outdir, 'dir')
        mkdir(outdir);
    end
    
    % == Convert dicm2nii
    
    cd(func_dirs{i}); % entering into the directory because of the problems 
                      % related to the length of the files
    dicom_imgs = filenames('*IMA');
    while isempty(dicom_imgs) 
        cd(filenames('*', 'char'));
        dicom_imgs = filenames('*IMA');
    end
        
    dicm2nii(dicom_imgs, outdir, 4, 'save_json');
    out = load(fullfile(outdir, 'dcmHeaders.mat'));
    f = fields(out.h);
    
    % == 3d to 4d
    
    cd(outdir);
    % 3d_imgs = filenames([f{2} '*.nii']);
    
    disp('Saving disdaq_image...')
    spm_file_merge(nifti_imgs(1:disdaq), fullfile(outdir, sprintf('disdaq_first_%02d_images.nii', disdaq)));
    disp('Converting 3d images to 4d images...')
    spm_file_merge(nifti_imgs((disdaq+1):end), output_4d_fnames);
    
    delete(fullfile(outdir, [f{1} '*.nii']));
    
    PREPROC.func_files{session_num} = output_4d_fnames;
    
    
    
    info.source = f{1};
    [~, subj_id] = fileparts(PREPROC.subject_dir);
    info.target = ['sub-' subj_id '_' func_names{8}(6:end)];
    
    filetype = {'nii', 'json'};
    
    for j = 1:numel(filetype)
        source_file = fullfile(outdir, [info.source '.' filetype{j}]);
        target_file = fullfile(outdir, [info.target '.' filetype{j}]);
        movefile(source_file, target_file);
        
        eval(['PREPROC.func_' filetype{i} '_files{i} = {''' target_file '''};']);
    end
    
    eval(['h = out.h.' info.source ';']);
    save(fullfile(outdir, ['func_' func_names{8}(6:end) '_dcm_headers.mat']), 'h');
    delete(fullfile(outdir, 'dcmHeaders.mat'));
    
    
    
    
    
    
    
    
    dicm2nii(filenames(char(fullfile(datdir, '*IMA'))), outdir, 4);
    f = fields(h);
    
    nifti_imgs = filenames(fullfile(outdir, [f{1} '*.nii']), 'absolute');
    
    a = fields(h);
    
    eval(['hh= h.' a{1} ';']);
    output_4d_fnames = fullfile(outdir, sprintf('r%02d_%s_%s.nii', session_num, ...
        hh.StudyDate, f{1}));
    
    % disdaq
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC
    disp('Done')
    
end

end