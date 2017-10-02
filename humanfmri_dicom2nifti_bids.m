function PREPROC = humanfmri_dicom2nifti_bids(subject_dir, session_n, disdaq_n)

% This function saves the dicom files into nifti files in the Functional 
% image directory (subject_dir/Functional/dicom/r##, e.g., r01). 
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

for session_num = session_n
    
    if numel(disdaq_n)>1
        disdaq = disdaq_n(session_num);
    else
        disdaq = disdaq_n;
    end
    
    str = ['Working on session #' num2str(session_num)];
    disp(str);
    
    datdir = filenames(fullfile(subject_dir, 'Functional', 'dicom', sprintf('r%02d*',session_num)));
    [~, temp] = fileparts(datdir{1});
    
    outdir = fullfile(subject_dir, 'Functional', 'raw', temp);
    
    
    if ~exist(outdir, 'dir')
        mkdir(outdir);
    end
    
    [~, h] = dicm2nii(filenames(char(fullfile(datdir, '*IMA'))), outdir, 4);
    f = fields(h);
    
    nifti_imgs = filenames(fullfile(outdir, [f{1} '*.nii']), 'absolute');
    
    a = fields(h);
    
    eval(['hh= h.' a{1} ';']);
    output_4d_fnames = fullfile(outdir, sprintf('r%02d_%s_%s.nii', session_num, ...
        hh.StudyDate, f{1}));
    
    % disdaq
    disp('Saving disdaq_image...')
    spm_file_merge(nifti_imgs(1:disdaq), fullfile(outdir, sprintf('disdaq_first_%02d_images.nii', disdaq)));
    disp('Converting 3d images to 4d images...')
    spm_file_merge(nifti_imgs((disdaq+1):end), output_4d_fnames);
    
    delete(fullfile(outdir, [f{1} '*.nii']));
    
    PREPROC.func_files{session_num} = output_4d_fnames;
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC
    disp('Done')
    
end

end