function move_dicom_to_raw(subject_code, study_imaging_dir, run_n)
% Moving dicom file to RAW directory

% The function move dicom files to corresponding directories in raw
% folders.
% YOU SHOULD CHECK YOUR DIRECTORY STRUCTURE OF DICOM FILES BEFORE USING THIS FUNCTION.                                        
% This function is based on the directory structure of Cocoan lab. 
%
% :Usage:
% ::
%    move_dicom_to_raw(subject_code, study_imaging_dir)
%
% :Inputs:
% 
% - subject_code       the subject id
%                      (e.g., subject_code = {'sub-caps001', 'sub-caps002'});
% - study_imaging_dir  the directory information for the study imaging data
%                      (e.g., study_imaging_dir = '/NAS/data/CAPS2/Imaging')
% 
% - run_n              number of runs: Previously decided in Setting. 
%                      Equal to length of 'func_run_nums'
%
% ..
%     Author and copyright information:
%
%     Copyright (C) Jan 2019  Hongji Kim
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

if ~iscell(subject_code)
    subject_codes{1} = subject_code;
else
    subject_codes = subject_code;
end

for sub_i = 1:numel(subject_codes)
    raw_dir = fullfile(study_imaging_dir, 'raw', subject_codes{1,sub_i});
    dicom_dir = fullfile(study_imaging_dir, 'dicom_from_scanner');
    dicom_dir_2 = filenames(fullfile(dicom_dir, ['*' upper(subject_codes{1,sub_i}(5:end)) '*']), 'char'); % change this part according to your project folder names
    sub_dicom_dir = filenames(fullfile(dicom_dir_2, ['COCOAN*']), 'char');
    
    % anat
    raw_anat_dir = fullfile(raw_dir, 'dicom', 'anat');
    T1_dir = filenames(fullfile(sub_dicom_dir, ['T1*']), 'char');
    movefile(T1_dir,raw_anat_dir);
    
    % fmap
    raw_fmap_dir = fullfile(raw_dir, 'dicom', 'fmap');
    DC_dir = filenames(fullfile(sub_dicom_dir, ['DISTORTION*']), 'char');
    cd(raw_fmap_dir)
    
    for dc_i = 1:2
        movefile(deblank(DC_dir(dc_i,1:end)), raw_fmap_dir);
    end
    
    % run1: FT1
     for run_i = 1:run_n
        raw_run_dir = filenames(fullfile(raw_dir, 'dicom', ['*' num2str(run_i) '*']), 'char');
        dicom_run_dir = filenames(fullfile(sub_dicom_dir, [num2str(run_i), '*']), 'char');
        if size(dicom_run_dir, 1) == 2
            for mb_i = 1:2
                cd(deblank(raw_run_dir(mb_i,:)));
                movefile(deblank(dicom_run_dir(mb_i,1:end)));
            end
        else % when you restarted the run
            rep_num = (size(dicom_run_dir, 1)/2);
            for mb_i = [rep_num*1, rep_num*2]
                cd(deblank(raw_run_dir(mb_i/rep_num,:)));
                movefile(deblank(dicom_run_dir(mb_i,1:end)));
            end
        end
    end
    disp([subject_codes{1,sub_i} ': DONE']);
end

end


