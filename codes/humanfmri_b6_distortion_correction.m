function PREPROC = humanfmri_b6_distortion_correction(preproc_subject_dir, epi_enc_dir, use_sbref)

% This function applies the distortion correction using fsl's topup.
%
% :Usage:
% ::
%    PREPROC = humanfmri_b6_distortion_correction(preproc_subject_dir, epi_enc_dir, use_sbref)
%
%    e.g. 
%       epi_enc_dir = 'ap';
%       use_sbref = true;
%       humanfmri_b6_distortion_correction(preproc_subject_dir, epi_enc_dir, use_sbref)
%
% :Input:
% 
% - preproc_subject_dir     the subject directory for preprocessed data
%                           (PREPROC.preproc_outputdir)
%
% - epi_enc_dir     EPI phase encoding direction: Now this works only for
%                   A->P or P->A. Input should be 'ap' or 'pa'. See the
%                   example above.
% - use_sbref       1: Apply topup on sbref
%                   0: Do not apply topup on sbref
%
% :Output:
% ::
%     PREPROC.distortion_correction_out          fmap combined
%     PREPROC.distortion_correction_parameter    dc parameters
%     PREPROC.dcr_func_bold_files{}               corrected functional images      
%     PREPROC.topup.topup_out
%                  .topup_fieldout
%                  .topup_unwarped               topup outputs
%     
%
% ..
%     Author and copyright information:
%
%     Copyright (C) Nov 2017  Choong-Wan Woo and Jaejoong Lee
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



%% add fsl path 
setenv('PATH', [getenv('PATH') ':/usr/local/fsl/bin']);
setenv('FSLOUTPUTTYPE','NIFTI_GZ');

%% Load PREPROC

for subj_i = 1:numel(preproc_subject_dir)

    PREPROC = save_load_PREPROC(preproc_subject_dir{subj_i}, 'load'); % load PREPROC
    
    distort_ap_dat = PREPROC.fmap_nii_files(1,:); % ap
    distort_pa_dat = PREPROC.fmap_nii_files(2,:); % pa
    
    
    %% Distortion correction
    
    [~,a] = fileparts(preproc_subject_dir{subj_i});
    print_header('disortion correction', a);
    
    PREPROC.distortion_correction_out = fullfile(PREPROC.preproc_fmap_dir, [PREPROC.subject_code '_dc_combined.nii']);
    
    if strcmpi(epi_enc_dir, 'ap')
        system(['fslmerge -t ', PREPROC.distortion_correction_out, ' ', distort_ap_dat, ' ', distort_pa_dat]);
    elseif strcmpi(epi_enc_dir, 'pa')
        system(['fslmerge -t ', PREPROC.distortion_correction_out, ' ', distort_pa_dat, ' ', distort_ap_dat]);
    end
    
    % calculate and write the distortion correction parameter
    
    dicomheader = load(PREPROC.dicomheader_files{1});
    readout_time = dicomheader.h.ReadoutSeconds;
    distort_info = nifti(distort_ap_dat);
    distort_num = distort_info.dat.dim(4);
    
    dc_param = fullfile(PREPROC.preproc_fmap_dir, ['dc_param_', epi_enc_dir, '.txt']);
    
    fileID = fopen(dc_param, 'w');
    if strcmpi(epi_enc_dir, 'ap')
        distort_param_dat = [repmat([0 -1 0 readout_time], distort_num, 1); ...
            repmat([0 1 0 readout_time], distort_num, 1)];
    elseif strcmpi(epi_enc_dir, 'pa')
        distort_param_dat = [repmat([0 1 0 readout_time], distort_num, 1); ...
            repmat([0 -1 0 readout_time], distort_num, 1)];
    end
    
    fprintf(fileID, repmat([repmat('%.4f\t', 1, size(distort_param_dat, 2)), '\n'], 1, size(distort_param_dat, 1)), distort_param_dat');
    fclose(fileID);
    
    PREPROC.distortion_correction_parameter = dc_param;
    
    % Running topup
    disp('Running topup....');
    topup_out = fullfile(PREPROC.preproc_fmap_dir, 'topup_out');
    topup_fieldout = fullfile(PREPROC.preproc_fmap_dir, 'topup_fieldout');
    topup_unwarped = fullfile(PREPROC.preproc_fmap_dir, 'topup_unwarped');
    topup_config = '/usr/local/fsl/src/topup/flirtsch/b02b0.cnf';
    system(['topup --imain=', PREPROC.distortion_correction_out, ' --datain=', dc_param, ' --config=', topup_config, ' --out=', topup_out, ...
        ' --fout=', topup_fieldout, ' --iout=', topup_unwarped]);
    
    PREPROC.topup.topup_out = topup_out;
    PREPROC.topup.topup_fieldout = topup_fieldout;
    PREPROC.topup.topup_unwarped = topup_unwarped;
    
    % Applying topup on BOLD files
    
    for i = 1:numel(PREPROC.r_func_bold_files)
        fprintf('\n- Applying topup on run %d/%d', i, numel(PREPROC.r_func_bold_files));
        input_dat = PREPROC.r_func_bold_files{i};
        [~, a] = fileparts(input_dat);
        PREPROC.dcr_func_bold_files{i,1} = fullfile(PREPROC.preproc_func_dir, ['dc' a '.nii']);
        system(['applytopup --imain=', input_dat, ' --inindex=1 --topup=', topup_out, ' --datain=', dc_param, ...
            ' --method=jac --interp=spline --out=', PREPROC.dcr_func_bold_files{i}]);
        
        % removing spline interpolation neg values by absolute
        system(['fslmaths ', PREPROC.dcr_func_bold_files{i}, ' -abs ', PREPROC.dcr_func_bold_files{i}, ' -odt short']);
        
        % unzip
        system(['gzip -d ' PREPROC.dcr_func_bold_files{i} '.gz']);
    end

    if use_sbref
        % Applying topup on SBREF files
        
        for i = 1:numel(PREPROC.preproc_func_sbref_files)
            fprintf('\n- Applying topup on run %d/%d', i, numel(PREPROC.preproc_func_sbref_files));
            input_dat = PREPROC.preproc_func_sbref_files{i};
            [~, a] = fileparts(input_dat);
            PREPROC.dc_func_sbref_files{i,1} = fullfile(PREPROC.preproc_func_dir, ['dc_' a '.nii']);
            system(['applytopup --imain=', input_dat, ' --inindex=1 --topup=', topup_out, ' --datain=', dc_param, ...
                ' --method=jac --interp=spline --out=', PREPROC.dc_func_sbref_files{i}]);
            
            % removing spline interpolation neg values by absolute
            system(['fslmaths ', PREPROC.dc_func_sbref_files{i}, ' -abs ', PREPROC.dc_func_sbref_files{i}, ' -odt short']);
            
            % unzip
            system(['gzip -d ' PREPROC.dc_func_sbref_files{i} '.gz']);
        end
    end
    
    
    %% save mean image across all runs
    dat = fmri_data(char(PREPROC.dcr_func_bold_files{:}), PREPROC.implicit_mask_file);
    mdat = mean(dat);
    
    [~, b] = fileparts(PREPROC.dcr_func_bold_files{1});
    b(strfind(b, '_run'):end) = [];
    
    mdat.fullpath = fullfile(PREPROC.preproc_mean_func_dir, ['mean_' b '.nii']);
    PREPROC.mean_dcr_func_bold_files = mdat.fullpath;
    write(mdat);
    
    %% save mean_r_func_bold_png
    
    mean_dcr_func_bold_png = fullfile(PREPROC.qcdir, 'mean_dcr_func_bold.png'); % Scott added some lines to actually save the spike images
    canlab_preproc_show_montage(PREPROC.mean_dcr_func_bold_files, mean_dcr_func_bold_png);
    drawnow;
    
    PREPROC = save_load_PREPROC(preproc_subject_dir{subj_i}, 'save', PREPROC);
end

end