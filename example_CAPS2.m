Resourcedir = '/Volumes/habenula/Resource';
addpath(genpath(Resourcedir)); % Basic resource folder
Resourcermdir = '/Volumes/habenula/Resource/github_nas/cocoanlab';
rmpath(genpath(Resourcermdir)); % This folder contains spm8 : Remove it.
codedir = '/Users/jaejoong/Documents/github/humanfmri_preproc_bids';
addpath(genpath(codedir));

basedir = '/Volumes/habenula/hbmnas/';
datdir = fullfile(basedir, 'projects/CAPS_project/data');
load(fullfile(datdir, 'CAPS2_dataset_171110.mat')); % Dataset : Subject info


for sj_num = 1:numel(D.Subj_Level.id)

    study_imaging_dir = fullfile(basedir, 'data/CAPS2/fMRI_prep');
    subject_codenum = split(D.Subj_Level.id{sj_num}, '_');
    subject_code = {['sub-caps', subject_codenum{2}]};
    subject_dir = fullfile(study_imaging_dir, 'raw', subject_code{1});

    orderlist = D.Subj_Level.data(sj_num, 3:6);

    func_run_nums = [1 2 3 4];
    disdaq_n = [20 20 20 20];

    func_tasks{orderlist(1)} = 'CAPS';
    func_tasks{orderlist(2)} = 'QUIN';
    func_tasks{orderlist(3)} = 'ODOR';
    func_tasks{orderlist(4)} = 'REST';

    %% 1. Make directories

    humanfmri_a1_make_directories(subject_code, study_imaging_dir, func_run_nums, func_tasks);

    %% (+) copy files
    % You need to copy all the dicom files into the raw data folder.
    % This section copy files into the raw data folder that was made above.

    temp_imgdir = '/Volumes/habenula/hbmnas/data/CAPS2/Imaging';
    imgdir = filenames(fullfile(temp_imgdir, ['CAPS2_' subject_codenum{2} '*']), 'char');

    capsrefdir = filenames(fullfile(imgdir, 'CAPS*SBREF*'));
    capsdir = setdiff(filenames(fullfile(imgdir, 'CAPS*')), capsrefdir);

    quinrefdir = filenames(fullfile(imgdir, 'QUIN*SBREF*'));
    quindir = setdiff(filenames(fullfile(imgdir, 'QUIN*')), quinrefdir);

    odorrefdir = filenames(fullfile(imgdir, 'ODOR*SBREF*'));
    odordir = setdiff(filenames(fullfile(imgdir, 'ODOR*')), odorrefdir);

    restrefdir = filenames(fullfile(imgdir, 'REST*SBREF*'));
    restdir = setdiff(filenames(fullfile(imgdir, 'REST*')), restrefdir);

    fmapdir = filenames(fullfile(imgdir, 'DISTOR*'));

    anatdir = filenames(fullfile(imgdir, 'T1*'));

    t_capsrefdir = filenames(fullfile(subject_dir, 'dicom/func_task-CAPS_run*_sbref'));
    t_capsdir = filenames(fullfile(subject_dir, 'dicom/func_task-CAPS_run*_bold'));
    t_quinrefdir = filenames(fullfile(subject_dir, 'dicom/func_task-QUIN_run*_sbref'));
    t_quindir = filenames(fullfile(subject_dir, 'dicom/func_task-QUIN_run*_bold'));
    t_odorrefdir = filenames(fullfile(subject_dir, 'dicom/func_task-ODOR_run*_sbref'));
    t_odordir = filenames(fullfile(subject_dir, 'dicom/func_task-ODOR_run*_bold'));
    t_restrefdir = filenames(fullfile(subject_dir, 'dicom/func_task-REST_run*_sbref'));
    t_restdir = filenames(fullfile(subject_dir, 'dicom/func_task-REST_run*_bold'));

    t_fmapdir = filenames(fullfile(subject_dir, 'dicom/fmap'));

    t_anatdir = filenames(fullfile(subject_dir, 'dicom/anat'));


    copyfile(capsrefdir{1}, t_capsrefdir{1});
    capslist = dir(fullfile(capsdir{1}, '*.IMA'));
    for i = 1:numel(capslist)
        copyfile(fullfile(capslist(i).folder, capslist(i).name), t_capsdir{1});
    end
    copyfile(quinrefdir{1}, t_quinrefdir{1});
    quinlist = dir(fullfile(quindir{1}, '*.IMA'));
    for i = 1:numel(quinlist)
        copyfile(fullfile(quinlist(i).folder, quinlist(i).name), t_quindir{1});
    end
    copyfile(odorrefdir{1}, t_odorrefdir{1});
    odorlist = dir(fullfile(odordir{1}, '*.IMA'));
    for i = 1:numel(odorlist)
        copyfile(fullfile(odorlist(i).folder, odorlist(i).name), t_odordir{1});
    end
    copyfile(restrefdir{1}, t_restrefdir{1});
    restlist = dir(fullfile(restdir{1}, '*.IMA'));
    for i = 1:numel(restlist)
        copyfile(fullfile(restlist(i).folder, restlist(i).name), t_restdir{1});
    end

    for i = 1:numel(fmapdir)
        fmapname = split(fmapdir{i}, '/');
        copyfile(fmapdir{i}, fullfile(t_fmapdir{1}, fmapname{end}));
    end

    copyfile(anatdir{1}, t_anatdir{1});
    
    
    clearvars -except sj_num basedir datdir D
    
end
