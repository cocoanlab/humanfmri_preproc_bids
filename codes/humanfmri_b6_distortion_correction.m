function PREPROC = humanfmri_b6_distortion_correction(preproc_subject_dir, epi_enc_dir, use_sbref, varargin)

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
% :Optional Input:
%
% - 'run_num' : Specify run number to apply the distortion corretion.
%               e.g) 1:9, [1,2,3] ...
% - 'deletion' : Delete existed (specific) distortion files. 
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

run_num = [];
do_deletion = false;
for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case {'run_num'}
                run_num = varargin{i+1};
            case {'deletion'}
                do_deletion = true; 
        end
    end
end

%% add fsl path 
setenv('PATH', [getenv('PATH') ':/usr/local/fsl/bin']);

%% Load PREPROC
for subj_i = 1:numel(preproc_subject_dir)

    PREPROC = save_load_PREPROC(preproc_subject_dir{subj_i}, 'load'); % load PREPROC       
    
    if ~any(contains(cellstr(PREPROC.fmap_nii_files), 'run-02_epi.nii')) % no dwi-fmap
        distort_ap_dat = PREPROC.fmap_nii_files(contains(cellstr(PREPROC.fmap_nii_files), 'dir-ap'), :);
        distort_pa_dat = PREPROC.fmap_nii_files(contains(cellstr(PREPROC.fmap_nii_files), 'dir-pa'), :);
    else % dwi-fmap exist
        distort_ap_dat = PREPROC.fmap_nii_files(contains(cellstr(PREPROC.fmap_nii_files), 'dir-ap_run-01'), :);
        distort_pa_dat = PREPROC.fmap_nii_files(contains(cellstr(PREPROC.fmap_nii_files), 'dir-pa_run-01'), :);
    end
        
    %% Specify run number to include
    do_preproc = true(numel(PREPROC.r_func_bold_files),1);
    if ~isempty(run_num)
        do_preproc(~ismember(1:numel(PREPROC.r_func_bold_files), run_num)) = false;     
    end
    %% delete the already (specified) exist dcr* files & dc_*sbref.nii
    if do_deletion
        try
            if isfield(PREPROC,'dcr_func_bold_files')
                delete(PREPROC.dcr_func_bold_files{do_preproc});
            end
            if isfield(PREPROC,'dc_func_sbref_files')
                delete(PREPROC.dc_func_sbref_files{do_preproc});
            end
        catch
            warning([PREPROC.subject_code ': Please, check dcr files']);
            continue
        end
    end
    %% Distortion correction    
    [~,a] = fileparts(preproc_subject_dir{subj_i});
    print_header('disortion correction', a);
    
    PREPROC.distortion_correction_out = fullfile(PREPROC.preproc_fmap_dir, [PREPROC.subject_code '_dc_combined.nii']);
    
    if strcmpi(epi_enc_dir, 'ap')
        system(['export FSLOUTPUTTYPE=NIFTI; fslmerge -t ', PREPROC.distortion_correction_out, ' ', distort_ap_dat, ' ', distort_pa_dat]);
    elseif strcmpi(epi_enc_dir, 'pa')
        system(['export FSLOUTPUTTYPE=NIFTI; fslmerge -t ', PREPROC.distortion_correction_out, ' ', distort_pa_dat, ' ', distort_ap_dat]);
    end
    
    % calculate and write the distortion correction parameter
    
    fmap_hfile = fullfile(PREPROC.study_imaging_dir, 'disdaq_dcmheaders', PREPROC.subject_code, sprintf('%s_fmap_dcmheaders.mat', PREPROC.subject_code));
    dicomheader = load(fmap_hfile);
    ap_readout = dicomheader.h.distortion_corr_64ch_pa_polarity_invert_to_ap.ReadoutSeconds;
    pa_readout = dicomheader.h.distortion_corr_64ch_pa.ReadoutSeconds;
    ap_vol = spm_vol(distort_ap_dat);
    pa_vol = spm_vol(distort_pa_dat);
    
    dc_param = fullfile(PREPROC.preproc_fmap_dir, ['dc_param_', epi_enc_dir, '.txt']);
    
    fileID = fopen(dc_param, 'w');
    if strcmpi(epi_enc_dir, 'ap')
        distort_param_dat = [repmat([0 -1 0 ap_readout], numel(ap_vol), 1); ...
            repmat([0 1 0 pa_readout], numel(pa_vol), 1)];
    elseif strcmpi(epi_enc_dir, 'pa')
        distort_param_dat = [repmat([0 1 0 pa_readout], numel(pa_vol), 1); ...
            repmat([0 -1 0 ap_readout], numel(ap_vol), 1)];
    end
    
    fprintf(fileID, repmat([repmat('%.4f\t', 1, size(distort_param_dat, 2)), '\n'], 1, size(distort_param_dat, 1)), distort_param_dat');
    fclose(fileID);
    
    PREPROC.distortion_correction_parameter = dc_param;
    
    % Running topup
    disp('Running topup....');
    topup_out = fullfile(PREPROC.preproc_fmap_dir, 'topup_out');
    topup_fieldout = fullfile(PREPROC.preproc_fmap_dir, 'topup_fieldout');
    topup_unwarped = fullfile(PREPROC.preproc_fmap_dir, 'topup_unwarped');
    merged_vol = spm_vol(PREPROC.distortion_correction_out);
    merged_dim = merged_vol(1).dim;
    if any(mod(merged_dim, 2) == 1)
        topup_config = '/usr/local/fsl/src/topup/flirtsch/b02b0_1.cnf'; % subsampling 1, takes longer
    else
        topup_config = '/usr/local/fsl/src/topup/flirtsch/b02b0.cnf';
    end
    system(['export FSLOUTPUTTYPE=NIFTI; topup --imain=', PREPROC.distortion_correction_out, ' --datain=', dc_param, ' --config=', topup_config, ' --out=', topup_out, ...
        ' --fout=', topup_fieldout, ' --iout=', topup_unwarped]);
    
    PREPROC.topup.topup_out = topup_out;
    PREPROC.topup.topup_fieldout = topup_fieldout;
    PREPROC.topup.topup_unwarped = topup_unwarped;
    
    fprintf('Take snapshot of fieldmap images before/after TOPUP.\n');
    if strcmpi(epi_enc_dir, 'ap')
        topup_unwarped_png{1} = fullfile(PREPROC.qcdir, 'topup_unwarped_dir-ap_epi.png');
        topup_unwarped_png{2} = fullfile(PREPROC.qcdir, 'topup_unwarped_dir-pa_epi.png');
        topup_figidx = {[1:numel(ap_vol)]', [1:numel(pa_vol)]' + numel(ap_vol)};
    elseif  strcmpi(epi_enc_dir, 'pa')
        topup_unwarped_png{1} = fullfile(PREPROC.qcdir, 'topup_unwarped_dir-pa_epi.png');
        topup_unwarped_png{2} = fullfile(PREPROC.qcdir, 'topup_unwarped_dir-ap_epi.png');
        topup_figidx = {[1:numel(pa_vol)]', [1:numel(ap_vol)]' + numel(pa_vol)};
    end
    for top_i = 1:numel(topup_unwarped_png)
        topup_before_list = cellstr(strcat(PREPROC.distortion_correction_out, ',', num2str(topup_figidx{top_i})));
        topup_after_list = cellstr(strcat([PREPROC.topup.topup_unwarped '.nii'], ',', num2str(topup_figidx{top_i})));
        canlab_preproc_show_montage([topup_before_list; topup_after_list], topup_unwarped_png{top_i});
        drawnow;
    end
    close all;
  
    %% Applying topup on BOLD files   
    for i = find(do_preproc)'
        fprintf('\n- Applying topup on run %d/%d', i, numel(PREPROC.r_func_bold_files));
        input_dat = PREPROC.r_func_bold_files{i};
        [~, a] = fileparts(input_dat);
        PREPROC.dcr_func_bold_files{i,1} = fullfile(PREPROC.preproc_func_dir, ['dc' a '.nii']);
        system(['export FSLOUTPUTTYPE=NIFTI; applytopup --imain=', input_dat, ' --inindex=1 --topup=', topup_out, ' --datain=', dc_param, ...
            ' --method=jac --interp=spline --out=', PREPROC.dcr_func_bold_files{i}]);
        
        % removing spline interpolation neg values by absolute
        system(['export FSLOUTPUTTYPE=NIFTI; fslmaths ', PREPROC.dcr_func_bold_files{i}, ' -abs ', PREPROC.dcr_func_bold_files{i}]);

    end

    if use_sbref
        % Applying topup on SBREF files
        
        for i = find(do_preproc)' 
            fprintf('\n- Applying topup on run %d/%d', i, numel(PREPROC.preproc_func_sbref_files));
            input_dat = PREPROC.preproc_func_sbref_files{i};
            [~, a] = fileparts(input_dat);
            PREPROC.dc_func_sbref_files{i,1} = fullfile(PREPROC.preproc_func_dir, ['dc_' a '.nii']);
            system(['export FSLOUTPUTTYPE=NIFTI; applytopup --imain=', input_dat, ' --inindex=1 --topup=', topup_out, ' --datain=', dc_param, ...
                ' --method=jac --interp=spline --out=', PREPROC.dc_func_sbref_files{i}]);
            
            % removing spline interpolation neg values by absolute
            system(['export FSLOUTPUTTYPE=NIFTI; fslmaths ', PREPROC.dc_func_sbref_files{i}, ' -abs ', PREPROC.dc_func_sbref_files{i}]);

        end
    end
    
    
    %% save mean image across all runs
    dat = fmri_data(char(PREPROC.dcr_func_bold_files{:}), PREPROC.implicit_mask_file);
    mdat = mean(dat);
    
    [~, b] = fileparts(PREPROC.dcr_func_bold_files{1});
    b(strfind(b, '_run'):end) = [];
    
    mdat.fullpath = fullfile(PREPROC.preproc_mean_func_dir, ['mean_' b '.nii']);
    PREPROC.mean_dcr_func_bold_files = mdat.fullpath;
    try
        write(mdat);
    catch
        write(mdat, 'overwrite');
    end
    
    %% save mean_r_func_bold_png
    
    mean_dcr_func_bold_png = fullfile(PREPROC.qcdir, 'mean_dcr_func_bold.png'); % Scott added some lines to actually save the spike images
    canlab_preproc_show_montage(PREPROC.mean_dcr_func_bold_files, mean_dcr_func_bold_png);
    drawnow;
    
    PREPROC = save_load_PREPROC(preproc_subject_dir{subj_i}, 'save', PREPROC);
end

end