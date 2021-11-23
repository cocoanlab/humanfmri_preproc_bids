function PREPROC = humanfmri_d1_distortion_correction(preproc_subject_dir, epi_enc_dir)

% This function applies the distortion correction for diffusion data using fsl's topup.
%
% :Usage:
% ::
%    PREPROC = humanfmri_d1_distortion_correction(preproc_subject_dir, epi_enc_dir, varargin)
%
%    e.g. 
%       epi_enc_dir = 'ap';
%       humanfmri_d1_distortion_correction(preproc_subject_dir, epi_enc_dir, varargin)
%
% :Input:
% 
% - preproc_subject_dir     the subject directory for preprocessed data
%                           (PREPROC.preproc_outputdir)
%
% - epi_enc_dir     EPI phase encoding direction: Now this works only for
%                   A->P or P->A. Input should be 'ap' or 'pa'. See the
%                   example above.
%
% :Optional Input:
%
% :Output:
% ::
%     PREPROC.dwi_distortion_correction_out          fmap combined
%     PREPROC.dwi_distortion_correction_parameter    dc parameters
%     PREPROC.dwi_dcr_func_bold_files{}               corrected functional images      
%     PREPROC.dwi_topup.topup_out
%                      .topup_fieldout
%                      .topup_unwarped               topup outputs
%     
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

%% add fsl path 
setenv('PATH', [getenv('PATH') ':/usr/local/fsl/bin']);
setenv('FSLOUTPUTTYPE','NIFTI_GZ');

%% Load PREPROC
for subj_i = 1:numel(preproc_subject_dir)

    PREPROC = save_load_PREPROC(preproc_subject_dir{subj_i}, 'load'); % load PREPROC       
    
    if ~any(contains(cellstr(PREPROC.fmap_nii_files), 'run-02_epi.nii')) % no dwi-fmap
        error('no fmap data for DWI...');
    else % dwi-fmap exist
        distort_ap_dat = PREPROC.fmap_nii_files(contains(cellstr(PREPROC.fmap_nii_files), 'dir-ap_run-02'), :);
        distort_pa_dat = PREPROC.fmap_nii_files(contains(cellstr(PREPROC.fmap_nii_files), 'dir-pa_run-02'), :);
    end
    
    %% Distortion correction    
    [~,a] = fileparts(preproc_subject_dir{subj_i});
    print_header('disortion correction', a);
    
    PREPROC.dwi_distortion_correction_out = fullfile(PREPROC.preproc_fmap_dir, [PREPROC.subject_code '_dc_combined_fordwi.nii']);
    
    if strcmpi(epi_enc_dir, 'ap')
        system(['fslmerge -t ', PREPROC.dwi_distortion_correction_out, ' ', distort_ap_dat, ' ', distort_pa_dat]);
    elseif strcmpi(epi_enc_dir, 'pa')
        system(['fslmerge -t ', PREPROC.dwi_distortion_correction_out, ' ', distort_pa_dat, ' ', distort_ap_dat]);
    end
    
    % calculate and write the distortion correction parameter
    
    fmap_hfile = fullfile(PREPROC.study_imaging_dir, 'disdaq_dcmheaders', PREPROC.subject_code, sprintf('%s_fmap_dcmheaders.mat', PREPROC.subject_code));
    dicomheader = load(fmap_hfile);
    
    dc_param = fullfile(PREPROC.preproc_fmap_dir, ['dc_param_', epi_enc_dir, '_fordwi.txt']);
    
    fileID = fopen(dc_param, 'w');
    if strcmpi(epi_enc_dir, 'ap')
        h2 = dicomheader.h.ep2d_diff_DisCor_AP;
        h1 = dicomheader.h.ep2d_diff_DisCor_PA;
        distort_param_dat = [repmat([0 -1 0 h1.ReadoutSeconds], h1.NumberOfTemporalPositions, 1); ...
            repmat([0 1 0 h2.ReadoutSeconds], h2.NumberOfTemporalPositions, 1)];
    elseif strcmpi(epi_enc_dir, 'pa')
        h1 = dicomheader.h.ep2d_diff_DisCor_PA;
        h2 = dicomheader.h.ep2d_diff_DisCor_AP;
        distort_param_dat = [repmat([0 1 0 h1.ReadoutSeconds], h1.NumberOfTemporalPositions, 1); ...
            repmat([0 -1 0 h2.ReadoutSeconds], h2.NumberOfTemporalPositions, 1)];
    end
    
    fprintf(fileID, repmat([repmat('%.4f\t', 1, size(distort_param_dat, 2)), '\n'], 1, size(distort_param_dat, 1)), distort_param_dat');
    fclose(fileID);
    
    PREPROC.dwi_distortion_correction_parameter = dc_param;
    
    % Running topup
    disp('Running topup....');
    topup_out = fullfile(PREPROC.preproc_fmap_dir, 'topup_out_fordwi');
    topup_fieldout = fullfile(PREPROC.preproc_fmap_dir, 'topup_fieldout_fordwi');
    topup_unwarped = fullfile(PREPROC.preproc_fmap_dir, 'topup_unwarped_fordwi');
    topup_config = '/usr/local/fsl/src/topup/flirtsch/b02b0.cnf';
    system(['topup --imain=', PREPROC.dwi_distortion_correction_out, ' --datain=', dc_param, ' --config=', topup_config, ' --out=', topup_out, ...
        ' --fout=', topup_fieldout, ' --iout=', topup_unwarped]);
    
    PREPROC.dwi_topup.topup_out = topup_out;
    PREPROC.dwi_topup.topup_fieldout = topup_fieldout;
    PREPROC.dwi_topup.topup_unwarped = topup_unwarped;
    
    system(['export FSLOUTPUTTYPE=NIFTI; fslchfiletype NIFTI ' PREPROC.dwi_distortion_correction_out]);
    system(['export FSLOUTPUTTYPE=NIFTI; fslchfiletype NIFTI ' PREPROC.dwi_topup.topup_unwarped '.nii.gz']);
    
    fprintf('Take snapshot of fieldmap images before/after TOPUP.\n');
    if strcmpi(epi_enc_dir, 'ap')
        topup_unwarped_png{1} = fullfile(PREPROC.qcdir, 'topup_unwarped_dir-ap_epi_fordwi.png');
        topup_unwarped_png{2} = fullfile(PREPROC.qcdir, 'topup_unwarped_dir-pa_epi_fordwi.png');
    elseif  strcmpi(epi_enc_dir, 'pa')
        topup_unwarped_png{1} = fullfile(PREPROC.qcdir, 'topup_unwarped_dir-pa_epi_fordwi.png');
        topup_unwarped_png{2} = fullfile(PREPROC.qcdir, 'topup_unwarped_dir-ap_epi_fordwi.png');
    end
    for top_i = 1:numel(topup_unwarped_png)
        topup_before_list = cellstr(strcat(PREPROC.dwi_distortion_correction_out, ',', num2str([2*top_i-1;2*top_i])));
        topup_after_list = cellstr(strcat([PREPROC.dwi_topup.topup_unwarped '.nii'], ',', num2str([2*top_i-1;2*top_i])));
        canlab_preproc_show_montage([topup_before_list; topup_after_list], topup_unwarped_png{top_i});
        drawnow;
    end
    close all;
    
    PREPROC = save_load_PREPROC(preproc_subject_dir{subj_i}, 'save', PREPROC);
end

end