function PREPROC = humanfmri_b3_functional_implicitmask_savemean(preproc_subject_dir)

% This function creates and saves implicit mask (top 95% of voxels above
% the mean value) and mean functional images (before any preprocessing) in 
% the preproc subject direcotry. The mean functional images can be used for 
% coregistration. 
%
% :Usage:
% ::
%        humanfmri_b3_functional_implicitmask_savemean(preproc_subject_dir)
%
% :Input:
% ::
%   - preproc_subject_dir     the subject directory for preprocessed data
%                             (PREPROC.preproc_outputdir)
%
% :Output(PREPROC):
% ::
%    PREPROC.implicit_mask_file
%    saves implicit_mask.nii and mean_beforepreproc_sub-x_task-x_run-x_bold.nii 
%                            and mean_dc_sbref.nii if there is dc_sbref
%
%    PREPROC.mean_before_preproc
%    saves qc_images/mean_before_preproc.png
%          
%    PREPROC.mean_dc_sbref (if there is dc_sbref)
%    saves qc_images/dc_func_sbref_files.png 
%
% ..
%     Author and copyright information:
%
%     Copyright (C) Nov 2017  Choong-Wan Woo
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


for subj_i = 1:numel(preproc_subject_dir)
    
    subject_dir = preproc_subject_dir{subj_i};
    [~,a] = fileparts(subject_dir);
    fprintf('\n');
    print_header('Saving implicit mask and mean functional images', a);
    
    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC
    
    if any(contains(fieldnames(PREPROC), 'dc_func_bold_files'))
        func_bold_files = PREPROC.dc_func_bold_files;
    else
        func_bold_files = PREPROC.func_bold_files;
    end
    
    [~, ~, ~, ~, outputname] = fmri_mask_thresh_canlab(char(func_bold_files),...
        fullfile(PREPROC.preproc_outputdir, 'implicit_mask.nii'));
    
    % output
    PREPROC.implicit_mask_file = outputname;
    
    for i = 1:numel(func_bold_files)
        dat = fmri_data(char(func_bold_files{i}), PREPROC.implicit_mask_file);
        mdat = mean(dat);
        [~, b] = fileparts(func_bold_files{i});
        
        mdat.fullpath = fullfile(PREPROC.preproc_mean_func_dir, ['mean_beforepreproc_' b '.nii']);
        PREPROC.mean_before_preproc{i,1} = mdat.fullpath;
        write(mdat);
    end
    
    % save mean_before_preproc images
    canlab_preproc_show_montage(PREPROC.mean_before_preproc);
    drawnow;
    
    mean_before_preproc_png = fullfile(PREPROC.qcdir, 'mean_before_preproc.png'); % Scott added some lines to actually save the spike images
    saveas(gcf,mean_before_preproc_png);
    
    if any(contains(fieldnames(PREPROC), 'dc_func_sbref_files'))
        
        % rewrite the sbref file using implicit mask file
        for i = 1:numel(PREPROC.dc_func_sbref_files)
            dc_sbrefdat = fmri_data(PREPROC.dc_func_sbref_files{i}, PREPROC.implicit_mask_file);
            write(dc_sbrefdat);
        end
        
        canlab_preproc_show_montage(PREPROC.dc_func_sbref_files);
        drawnow;
        
        dc_func_sbref_png = fullfile(PREPROC.qcdir, 'dc_func_sbref_files.png'); % Scott added some lines to actually save the spike images
        saveas(gcf,dc_func_sbref_png);
        
        mdc_sbref = fmri_data(PREPROC.dc_func_sbref_files, PREPROC.implicit_mask_file);
        mdc_sbref = mean(mdc_sbref);
        mdc_sbref.fullpath = fullfile(PREPROC.preproc_mean_func_dir, 'mean_dc_sbref.nii');
        write(mdc_sbref);

        PREPROC.mean_dc_sbref = mdc_sbref.fullpath;
    end
    
    save_load_PREPROC(preproc_subject_dir{subj_i}, 'save', PREPROC); % save PREPROC

end

% save dc_sbref images
        
        
        

        

end