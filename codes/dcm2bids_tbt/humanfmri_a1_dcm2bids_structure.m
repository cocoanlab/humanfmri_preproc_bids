function humanfmri_a1_dcm2bids_structure(study_imaging_dir)

bidsdir = fullfile(study_imaging_dir, 'raw');
tbdir = fullfile(study_imaging_dir, 'for_temp_bids');

%%

fprintf('Generating basic BIDS directory structure...\n');
system(sprintf(['source ~/.d2bvenv/bin/activate;', ...
    'dcm2bids_scaffold -o %s'], bidsdir));

%%

fprintf('Generating temporary NIFTI files for help make configuration file ...\n');
system(sprintf(['source ~/.d2bvenv/bin/activate;', ...
    'dcm2bids_helper -d %s -o %s'], tbdir, bidsdir));

%%

fprintf('Prepare xlsx file that specify relevant information for configuration using the tmp_dcm2bids/helper directory.\n')
fprintf('Make sure the xlsx file named as "dcm2bids_config.xlsx" and located in the code directory.\n')
if ~strcmpi(input('Ready? (Y/y) ', 's'), 'Y'); error('Break!'); end

fprintf('Generating a configuration file ...\n');

T = readtable(fullfile(bidsdir, 'code', 'dcm2bids_config.xlsx'));

cfg_datatype = T.datatype;
cfg_suffix = T.suffix;
cfg_customentities = T.custom_entities;
cfg_criteria = arrayfun(@(x) struct('SeriesDescription', x), T.SeriesDescription, 'un', false);
cfg_id = strcat('id_', T.datatype, '_', T.custom_entities, '_', T.suffix);
cfg_id(ismember(cfg_datatype, {'anat', 'fmap'})) = {''};
cfg_sidecarchanges = repmat({''}, numel(cfg_datatype), 1);
cfg_sidecarchanges(strcmp(cfg_datatype, 'fmap')) = {struct('IntendedFor', string(cfg_id(strcmp(cfg_datatype, 'func'))))};

cfg_all = struct('descriptions', ...
    struct('id', cfg_id, ...
    'datatype', cfg_datatype, ...
    'suffix', cfg_suffix, ...
    'custom_entities', cfg_customentities, ...
    'criteria', cfg_criteria, ...
    'sidecar_changes', cfg_sidecarchanges));

cfg_json = jsonencode(cfg_all, PrettyPrint=true);
cfg_json = strrep(cfg_json, [newline '      "id": "",'], '');
cfg_json = strrep(cfg_json, [',' newline '      "custom_entities": ""'], '');
cfg_json = strrep(cfg_json, [',' newline '      "sidecar_changes": ""'], '');

cfg_jsonfile = fullfile(bidsdir, 'code', 'dcm2bids_config.json');

fid = fopen(cfg_jsonfile, 'w');
fwrite(fid, cfg_json);
fclose(fid);

%%

fprintf('Generating a bidsignore file ...\n');

ign_txt = ['tmp_dcm2bids', newline, 'Icon?'];
ign_file = fullfile(bidsdir, '.bidsignore');

fid = fopen(ign_file, 'w');
fwrite(fid, ign_txt);
fclose(fid);

end