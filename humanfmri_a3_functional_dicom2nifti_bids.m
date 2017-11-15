function PREPROC = humanfmri_a3_functional_dicom2nifti_bids(subject_code, study_imaging_dir, disdaq_input)

% This function saves the dicom files (subject_dir/dicoms/func/r**) into 
% nifti files in the Functional image directory (subject_dir/func/sub-, e.g., r01). 
%
% :Usage:
% ::
%    PREPROC = humanfmri_a3_functional_dicom2nifti_bids(subject_code, study_imaging_dir, disdaq_input)
%
%    e.g. 
%       disdaq_input = 20; or disdaq_input = [20 20 20 20];
%       PREPROC = humanfmri_a3_functional_dicom2nifti_bids(subject_code, study_imaging_dir, disdaq_input)
%
% :Input:
% 
% - subject_code    the subject id
%                   (e.g., subject_code = {'sub-caps001', 'sub-caps002'});
% - study_imaging_dir  the directory information for the study imaging data
%                      (e.g., study_imaging_dir = '/NAS/data/CAPS2/Imaging')
% - disdaq_input    the number of images you want to discard (to allow for
%                   image intensity stablization)
%
% :Output(PREPROC):
% ::
%     PREPROC.func_bold_files
%     PREPROC.func_bold_json_files
%     PREPROC.func_sbref_files
%     PREPROC.func_sbref_json_files
%     PREPROC.dicomheader_files
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


if ~iscell(subject_code)
    subject_codes{1} = subject_code;
else
    subject_codes = subject_code;
end


for subj_i = 1:numel(subject_codes)
    
    subject_dir = fullfile(study_imaging_dir, 'raw', subject_codes{subj_i});
    
    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC
    
    %% constructing disdaq n
    
    func_dirs = PREPROC.dicom_dirs(contains(PREPROC.dicom_dirs, 'func_'));
    
    disdaq_n = zeros(size(func_dirs));
    
    if numel(disdaq_input) == 1
        disdaq_n = repmat(disdaq_input, numel(func_dirs), 1);
        disdaq_n(contains(func_dirs, '_sbref')) = 0;
    else
        disdaq_n(contains(func_dirs, '_bold')) = disdaq_input;
    end
    
    for i = 1:numel(func_dirs)
        [~, func_names{i,1}] = fileparts(func_dirs{i});
    end
    
    %% Make sure disdaq n is correct
    
    if subj_i == 1
        try
            t = table(func_names, disdaq_n)
        catch
            t = table(func_names, disdaq_n')
        end
        
        s = input('Is the disdaq_n correct? (Y or N) ', 's');
        
        if strcmp(s, 'N') || strcmp(s, 'n')
            error('Please check the disdaq numbers, and run this again.');
        end
    end
    
    %% set the directory
    
    outdir = fullfile(subject_dir, 'func');
    if ~exist(outdir, 'dir'), mkdir(outdir); end
    
    [imgdir, subject_id] = fileparts(subject_dir);
    studydir = fileparts(imgdir);
    
    outdisdaqdir = fullfile(studydir, 'disdaq_dcmheaders', subject_id);
    if ~exist(outdisdaqdir, 'dir'), mkdir(outdisdaqdir); end
    
    % loop for runs
    for i = 1:numel(func_dirs)
        
        disdaq = disdaq_n(i);
        
        str{1} = repmat('-', 1, 60); str{3} = str{1};
        str{2} = ['Working on ' func_names{i}];
        for j = 1:numel(str), disp(str{j}); end
        
        %% **** dicm2nii ****
        
        cd(func_dirs{i}); % entering into the directory because of the problems
        % related to the length of the files
        dicom_imgs = filenames('*IMA');
        while isempty(dicom_imgs)
            cd(filenames('*', 'char'));
            dicom_imgs = filenames('*IMA');
        end
        
        taskname = func_dirs{1}(strfind(func_dirs{1}, 'func_task-')+10:strfind(func_dirs{1}, 'run-')-2);
        
        dicm2nii(dicom_imgs, outdir, 4, 'save_json', 'taskname', taskname);
        out = load(fullfile(outdir, 'dcmHeaders.mat'));
        f = fields(out.h);
        
        %% **** 3d to 4d ****
        
        cd(outdir);
        
        nifti_3d = filenames([f{1} '*.nii']);
        
        if disdaq > 0
            disp('Saving disdaq_image...')
            spm_file_merge(nifti_3d(1:disdaq), fullfile(outdisdaqdir, sprintf('disdaq_first_%02d_imgs_%s.nii', disdaq, func_names{i}(6:end))));
        end
        
        [~, subj_id] = fileparts(PREPROC.subject_dir);
        output_4d_fnames = fullfile(outdir, sprintf('%s_%s', subj_id, func_names{i}(6:end)));
        output_dcmheaders_fnames = fullfile(outdisdaqdir, sprintf('%s_%s', subj_id, func_names{i}(6:end)));
        
        disp('Converting 3d images to 4d images...')
        spm_file_merge(nifti_3d((disdaq+1):end), [output_4d_fnames '.nii']);
        
        delete(fullfile(outdir, [f{1} '*nii']))
        
        %% **** change the json file name and save PREPROC ****
        movefile(fullfile(outdir, [f{1} '.json']), [output_4d_fnames '.json']);
        
        if contains(output_4d_fnames, '_bold')
            PREPROC.func_bold_files{ceil(i/2),1} = filenames([output_4d_fnames '.nii'], 'char');
            PREPROC.func_bold_json_files{ceil(i/2),1} = filenames([output_4d_fnames '.json'], 'char');
        elseif contains(output_4d_fnames, '_sbref')
            PREPROC.func_sbref_files{ceil(i/2),1} = filenames([output_4d_fnames '.nii'], 'char');
            PREPROC.func_sbref_json_files{ceil(i/2),1} = filenames([output_4d_fnames '.json'], 'char');
        end
        
        eval(['h = out.h.' f{1} ';']);
        
        PREPROC.dicomheader_files{i} = [output_dcmheaders_fnames '_dcmheaders.mat'];
        save(PREPROC.dicomheader_files{i}, 'h');
        delete(fullfile(outdir, 'dcmHeaders.mat'));
        
    end
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC
    disp('Done');
end

end