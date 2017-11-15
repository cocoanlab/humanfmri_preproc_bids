function PREPROC = humanfmri_5_distortion_correction(subject_dir, epi_enc_dir)

% This function applies the distortion correction using fsl's topup.
%
% :Usage:
% ::
%    PREPROC = humanfmri_3_functional_dicom2nifti_bids(subject_dir, disdaq_n)
%
%    e.g. 
%       disdaq = 5;
%       PREPROC = humanfmri_3_functional_dicom2nifti_bids(subject_dir, session_num, disdaq);
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

% epi_enc_dir: 'ap' or 'pa'

%% add fsl path 
setenv('PATH', [getenv('PATH') ':/usr/local/fsl/bin']);
setenv('FSLOUTPUTTYPE','NIFTI_GZ');

%% Load PREPROC
PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC

distort_ap_dat = PREPROC.fmap_nii_files(1,:); % ap
distort_pa_dat = PREPROC.fmap_nii_files(2,:); % pa


%% Distortion correction

print_header('disortion correction', '');

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

% Running topup
disp('Running topup....');
topup_out = fullfile(PREPROC.preproc_fmap_dir, 'topup_out');
topup_fieldout = fullfile(PREPROC.preproc_fmap_dir, 'topup_fieldout');
topup_unwarped = fullfile(PREPROC.preproc_fmap_dir, 'topup_unwarped');
topup_config = '/usr/local/fsl/src/topup/flirtsch/b02b0.cnf';
system(['topup --imain=', PREPROC.distortion_correction_out, ' --datain=', dc_param, ' --config=', topup_config, ' --out=', topup_out, ...
    ' --fout=', topup_fieldout, ' --iout=', topup_unwarped]);

% Applying topup

for i = 1:numel(PREPROC.func_bold_files)
    fprintf('\n- Applying topup on run %d/%d', i, numel(PREPROC.func_bold_files));
    input_dat = PREPROC.func_bold_files{i};
    [~, a] = fileparts(input_dat);
    PREPROC.dc_func_bold_files{i} = fullfile(PREPROC.preproc_func_dir, ['dc_' a '.nii']);
    system(['applytopup --imain=', input_dat, ' --inindex=1 --topup=', topup_out, ' --datain=', dc_param, ...
        ' --method=jac --interp=spline --out=', PREPROC.dc_func_bold_files{i}]);
    
    % removing spline interpolation neg values by absolute
    system(['fslmaths ', PREPROC.dc_func_bold_files{i}, ' -abs ', PREPROC.dc_func_bold_files{i}, ' -odt short']);
end

PREPROC = save_load_PREPROC(subject_dir, 'save', PREPROC);

end