function PREPROC = humanfmri_a2_dcm2bids_convert(subject_code, dicom_code, study_imaging_dir)

bidsdir = fullfile(study_imaging_dir, 'raw');
dicomdir = fullfile(study_imaging_dir, 'dicom_from_scanner', dicom_code);

cfg_jsonfile = fullfile(bidsdir, 'code', 'dcm2bids_config.json');

%%

system(sprintf(['source ~/.d2bvenv/bin/activate;', ...
    'dcm2bids -d %s -p %s -c %s -o %s'], ...
    dicomdir, subject_code, cfg_jsonfile, bidsdir));

%%

PREPROC.study_imaging_dir = study_imaging_dir;
PREPROC.study_rawdata_dir = bidsdir;
PREPROC.subject_code = subject_code;
PREPROC.subject_dir = bidsdir;

save_load_PREPROC(PREPROC.subject_dir, 'save', PREPROC); % save PREPROC

end