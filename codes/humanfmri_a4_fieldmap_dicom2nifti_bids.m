function PREPROC = humanfmri_a4_fieldmap_dicom2nifti_bids(subject_code, study_imaging_dir)

% This function saves the dicom files (subject_dir/dicoms/fmap/*) into 
% nifti files in the fmap directory (subject_dir/fmap/sub-, e.g., r01). 
%
% :Usage:
% ::
%    PREPROC = humanfmri_a4_fieldmap_dicom2nifti_bids(subject_code, study_imaging_dir)
%
% :Input:
% 
% - subject_code    the subject id
%                   (e.g., subject_code = {'sub-caps001', 'sub-caps002'});
% - study_imaging_dir  the directory information for the study imaging data
%                      (e.g., study_imaging_dir = '/NAS/data/CAPS2/Imaging')
%
% :Output(PREPROC):
% ::
%     PREPROC.fmap_nii_files
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


if ~iscell(subject_code)
    subject_codes{1} = subject_code;
else
    subject_codes = subject_code;
end


for subj_i = 1:numel(subject_codes)
    
    subject_dir = fullfile(study_imaging_dir, 'raw', subject_codes{subj_i});
    
    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC
    
    fmap_dir = filenames(fullfile(PREPROC.dicom_dirs{1}, 'fmap*'), 'char', 'absolute');
    
    % set the directory
    outdir = fullfile(subject_dir, 'fmap');
    if ~exist(outdir, 'dir'), mkdir(outdir); end
    
    [imgdir, subject_id] = fileparts(subject_dir);
    studydir = fileparts(imgdir);
    
    outdisdaqdir = fullfile(studydir, 'disdaq_dcmheaders', subject_id);
    if ~exist(outdisdaqdir, 'dir'), mkdir(outdisdaqdir); end
    
    cd(fmap_dir);
    
    if ~any(contains(filenames('*'), 'EP2D_DIFF_DISCOR')) % no dwi-fmap
    
        dicom_imgs = filenames('*/*IMA', 'absolute');
        dicom_imgs_pa = dicom_imgs(~contains(dicom_imgs, 'POLARITY_INVERT_TO_AP'));
        dicom_imgs_ap = dicom_imgs(contains(dicom_imgs, 'POLARITY_INVERT_TO_AP'));

        %% PA
        dicm2nii(dicom_imgs_pa, outdir, 4, 'save_json');
        out = load(fullfile(outdir, 'dcmHeaders.mat'));
        f = fields(out.h);

        cd(outdir);
        nifti_3d = filenames([f{1} '*.nii']);

        [~, subj_id] = fileparts(PREPROC.subject_dir);
        output_4d_fnames = fullfile(outdir, sprintf('%s_dir-pa_epi', subj_id));

        disp('Converting 3d images to 4d images...')
        spm_file_merge(nifti_3d, [output_4d_fnames '.nii']);

        delete(fullfile(outdir, [f{1} '*nii']))

        % == change the json file name and save PREPROC
        movefile(fullfile(outdir, [f{1} '.json']), [output_4d_fnames '.json']);

        %% AP
        dicm2nii(dicom_imgs_ap, outdir, 4, 'save_json');
        out = load(fullfile(outdir, 'dcmHeaders.mat'));
        f = fields(out.h);

        nifti_3d = filenames([f{2} '*.nii']);

        [~, subj_id] = fileparts(PREPROC.subject_dir);
        output_4d_fnames = fullfile(outdir, sprintf('%s_dir-ap_epi', subj_id));

        disp('Converting 3d images to 4d images...')
        spm_file_merge(nifti_3d, [output_4d_fnames '.nii']);

        delete(fullfile(outdir, [f{2} '*nii']))

        % == change the json file name and save PREPROC
        movefile(fullfile(outdir, [f{2} '.json']), [output_4d_fnames '.json']);
        
    else % dwi-fmap exist
        
        dicom_imgs = filenames('*/*IMA', 'absolute');
        dicom_imgs_forfunc_ap = dicom_imgs(contains(dicom_imgs, 'DISTORTION_CORR_64CH_PA_POLARITY_INVERT_TO_AP'));
        dicom_imgs_forfunc_pa = setdiff(dicom_imgs(contains(dicom_imgs, 'DISTORTION_CORR_64CH_PA')), dicom_imgs_forfunc_ap);
        dicom_imgs_fordwi_ap = dicom_imgs(contains(dicom_imgs, 'EP2D_DIFF_DISCOR_AP'));
        dicom_imgs_fordwi_pa = dicom_imgs(contains(dicom_imgs, 'EP2D_DIFF_DISCOR_PA'));
        
        dicom_imgs_cell = {dicom_imgs_forfunc_pa, dicom_imgs_forfunc_ap, dicom_imgs_fordwi_pa, dicom_imgs_fordwi_ap};
        
        for modal_i = 1:numel(dicom_imgs_cell)

        dicm2nii(dicom_imgs_cell{modal_i}, outdir, 4, 'save_json');
        out = load(fullfile(outdir, 'dcmHeaders.mat'));
        f = fields(out.h);

        cd(outdir);
        nifti_3d = filenames([f{modal_i} '*.nii']);

        [~, subj_id] = fileparts(PREPROC.subject_dir);
        switch modal_i
            case 1 % dicom_imgs_forfunc_pa
                output_4d_fnames = fullfile(outdir, sprintf('%s_dir-pa_run-01_epi', subj_id));
            case 2 % dicom_imgs_forfunc_ap
                output_4d_fnames = fullfile(outdir, sprintf('%s_dir-ap_run-01_epi', subj_id));
            case 3 % dicom_imgs_fordwi_pa
                output_4d_fnames = fullfile(outdir, sprintf('%s_dir-pa_run-02_epi', subj_id));
            case 4 % dicom_imgs_fordwi_ap
                output_4d_fnames = fullfile(outdir, sprintf('%s_dir-ap_run-02_epi', subj_id));
        end

        disp('Converting 3d images to 4d images...')
        spm_file_merge(nifti_3d, [output_4d_fnames '.nii']);

        delete(fullfile(outdir, [f{modal_i} '*nii']))

        % == change the json file name and save PREPROC
        movefile(fullfile(outdir, [f{modal_i} '.json']), [output_4d_fnames '.json']);

    end
    
    PREPROC.fmap_nii_files = filenames('sub*dir*.nii', 'absolute', 'char');
    
    h = out.h;
    
    output_dcmheaders_fnames = fullfile(outdisdaqdir, sprintf('%s_fmap', subj_id));
    save([output_dcmheaders_fnames '_dcmheaders.mat'], 'h');
    delete(fullfile(outdir, 'dcmHeaders.mat'));
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC
    disp('Done')
end

end