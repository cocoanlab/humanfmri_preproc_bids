function PREPROC = humanfmri_5_distortion_correction(subject_dir, ap_or_pa)

PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC

func_dat = char(PREPROC.func_bold_files);
SBRef_dat = char(PREPROC.func_sbref_files);
distort_ap_dat = PREPROC.fmap_nii_files(1,:); % ap
distort_pa_dat = PREPROC.fmap_nii_files(2,:); % pa

% create preproc directories

PREPROC.preproc_outputdir = fullfile(PREPROC.study_imaging_dir, 'preprocessed', PREPROC.subject_code);
if ~exist(PREPROC.preproc_outputdir, 'dir'), mkdir(PREPROC.preproc_outputdir); end

PREPROC.preproc_func_dir = fullfile(PREPROC.preproc_outputdir, 'func'); 
if ~exist(PREPROC.preproc_func_dir, 'dir'), mkdir(PREPROC.preproc_outputdir); end

PREPROC.preproc_anat_dir = fullfile(PREPROC.preproc_outputdir, 'anat'); 
if ~exist(PREPROC.preproc_anat_dir, 'dir'), mkdir(PREPROC.preproc_anat_dir); end

PREPROC.preproc_fmap_dir = fullfile(PREPROC.preproc_outputdir, 'fmap'); 
if ~exist(PREPROC.preproc_fmap_dir, 'dir'), mkdir(PREPROC.preproc_fmap_dir); end


%% Distortion correction

print_header('disortion correction', '');

PREPROC.distortion_correction_out = fullfile(PREPROC.preproc_fmap_dir, [PREPROC.subject_code '_dc_combined.nii']);

if strcmpi(ap_or_pa, 'ap')
    system(['fslmerge -t ', PREPROC.distortion_correction_out, ' ', distort_ap_dat, ' ', distort_pa_dat]);
elseif strcmpi(ap_or_pa, 'pa')
    system(['fslmerge -t ', PREPROC.distortion_correction_out, ' ', distort_pa_dat, ' ', distort_ap_dat]);
end

distort_info = nifti(distort_ap_dat);
distort_num = distort_info.dat.dim(4);

distort_param = fullfile(preproc_funcdir, ['2_distort_param_', APorPA, '.txt']);
fileID = fopen(distort_param, 'w');
if strcmp(APorPA, 'AP')
    distort_param_dat = [repmat([0 -1 0 readout_time], distort_num, 1); ...
        repmat([0 1 0 readout_time], distort_num, 1)];
elseif strcmp(APorPA, 'PA')
    distort_param_dat = [repmat([0 1 0 readout_time], distort_num, 1); ...
        repmat([0 -1 0 readout_time], distort_num, 1)];
end
fprintf(fileID, repmat([repmat('%.4f\t', 1, size(distort_param_dat, 2)), '\n'], 1, size(distort_param_dat, 1)), distort_param_dat');
fclose(fileID);

topup_out = fullfile(preproc_funcdir, '2_topup_out');
topup_fieldout = fullfile(preproc_funcdir, '2_topup_fieldout');
topup_unwarped = fullfile(preproc_funcdir, '2_topup_unwarped');
topup_config = '/usr/local/fsl/src/topup/flirtsch/b02b0.cnf';
system(['topup --imain=', distort_out, ' --datain=', distort_param, ' --config=', topup_config, ' --out=', topup_out, ...
    ' --fout=', topup_fieldout, ' --iout=', topup_unwarped]);

input_dat = fullfile(preproc_funcdir, '1_copy.nii');
output_dat = fullfile(preproc_funcdir, '2_distort_correct.nii');
system(['applytopup --imain=', input_dat, ' --inindex=1 --topup=', topup_out, ' --datain=', distort_param, ...
    ' --method=jac --interp=spline --out=', output_dat]);

disp('%%%%% Distortion correction : Removing spline interpolation neg values by abs');
system(['fslmaths ', output_dat, ' -abs ', output_dat, ' -odt short']);
disp(' ');

end