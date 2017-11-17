function PREPROC = humanfmri_b5_slice_timing(preproc_subject_dir, tr, mbf)

% This function does slice time correction for functional data. This is 
% using "MosaicRefAcqTimes" information (the actual slice timing information) 
% provided by dicm2nii. This should work for both multi-band (MB) and
% non-MB.
%
% :Usage:
% ::
%   PREPROC = humanfmri_b5_slice_timing(preproc_subject_dir, tr, mbf)
%
%
% :Input:
% 
% - preproc_subject_dir     the subject directory for preprocessed data
%                             (PREPROC.preproc_outputdir)
% - tr                      repetition time (in seconds)
% - mbf                     multi-band factor, if it's not using mb
%                           sequence, it should be 1.
%
% :Output(PREPROC):
% ::
%    PREPROC.slice_time
%    PREPROC.slice_timing_job
%    PREPROC.adc_func_bold_files
%    PREPROC.TR
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
    print_header('Slice timing correction', a);
    
    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC
    dicomheader = load(PREPROC.dicomheader_files{1});

    PREPROC.slice_time = dicomheader.h.MosaicRefAcqTimes';

    %% DATA
    slice_timing_job{1}.spm.temporal.st.scans{1} = PREPROC.dc_func_bold_files; % individual 3d images in cell str

    %% 1. nslices
    Vfirst_vol = spm_vol([PREPROC.dc_func_bold_files{1} ',1']);
    num_slices = Vfirst_vol(1).dim(3);
    slice_timing_job{1}.spm.temporal.st.nslices = num_slices; % number of slices

    %% 2. tr
    slice_timing_job{1}.spm.temporal.st.tr = tr;
    PREPROC.TR = tr;

    %% 3. ta: acquisition time
    slice_timing_job{1}.spm.temporal.st.ta = tr - tr * mbf / num_slices; % if not multi-band, mbf = 1;

    %% 4. so: Slice order
    
    slice_timing_job{1}.spm.temporal.st.so = PREPROC.slice_time;
    slice_timing_job{1}.spm.temporal.st.refslice = find(PREPROC.slice_time==0, 1, 'first');
    slice_timing_job{1}.spm.temporal.st.prefix = 'a';
    
    %% Saving slice time correction job
    
    PREPROC.slice_timing_job = slice_timing_job{1};
    PREPROC.adc_func_bold_files = prepend_a_letter(PREPROC.dc_func_bold_files, ones(size(PREPROC.dc_func_bold_files)), 'a');
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC
    
    %% RUN
    
    spm('defaults','fmri');
    spm_jobman('initcfg');
    spm_jobman('run', {slice_timing_job});

end
    
end


