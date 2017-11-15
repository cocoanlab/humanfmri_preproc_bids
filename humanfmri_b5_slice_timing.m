function PREPROC = humanfmri_b5_slice_timing(preproc_subject_dir, tr, mbf)


% This function does slice time correction for one run's functional image
% data. The functional images should be located within 
% subject_dir/Functional/raw/r## (e.g., /r01). But this will automatically 
% read the location of functional image data from the output of previous 
% step of the preprocessing pipeline. This is designed to work with multi-band 
% data. But if you want to use this for multi-band data, you need to
% replace two spm functions (spm_slice_timing.m and spm_cfg_st.m) with the
% new ones from https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=ind1407&L=spm&D=0&P=795113
%
%
% :Usage:
% ::
%   apfmri_functional_5_slice_timing(subject_dir, 1, 'TR', 1.2, 'MBF', 2, 'acq', 'interleaved_TD')
%
%
% :Input:
% 
% - subject_dir             the subject directory
% - session_num             the session number, e.g., 1
% - 'TR', tr                repetition time, e.g., 'TR', 1.2 (in seconds)
% - 'MBF', mbf              if multi-band, multi-band factor
% - 'acq', acquisition      'interleaved_TD' (top-down) or 'interleaved_BU'
%                           (bottom-up); currently only works for these two
% - 'slice_time'            if you have the exact slice_time info, you can
%                           feed it into here
%                           if you have a dicom file, you can get the info.
%       e.g., 
%             hdr = dicominfo(dicomfile);
%             slice_time = hdr.Private_0019_1029;
%
% :Output(PREPROC):
% ::
%    PREPROC.slice_timing_job
%    PREPROC.ao_func_files
%    PREPROC.TR
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

%   matlabbatch{1}.spm.temporal.st.scans = {volnames};
%   %%
%   matlabbatch{1}.spm.temporal.st.nslices = 30;
%   matlabbatch{1}.spm.temporal.st.tr = 2;
%   matlabbatch{1}.spm.temporal.st.ta = 1.93333333333333;
%   matlabbatch{1}.spm.temporal.st.so = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30];
%   matlabbatch{1}.spm.temporal.st.refslice = 1;
%   matlabbatch{1}.spm.temporal.st.prefix = 'a';


for subj_i = 1:numel(preproc_subject_dir)

    subject_dir = preproc_subject_dir{subj_i};
    [~,a] = fileparts(subject_dir);
    print_header('Slice timing correction', a);
    
    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC
    dicomheader = load(PREPROC.dicomheader_files{1});

    slice_time = dicomheader.h.SliceTiming';

    %% DATA
    slice_timing_job{1}.spm.temporal.st.scans{1} = PREPROC.dc_func_bold_files; % individual 3d images in cell str

    %% 1. nslices
    Vfirst_vol = spm_vol([PREPROC.o_func_files{session_num(1)} ',1']);
    num_slices = Vfirst_vol(1).dim(3);
slice_timing_job{1}.spm.temporal.st.nslices = num_slices; % number of slices

%% 2. tr
slice_timing_job{1}.spm.temporal.st.tr = tr;
PREPROC.TR = tr;

%% 3. ta: acquisition time
slice_timing_job{1}.spm.temporal.st.ta = tr - tr * mbf / num_slices; % if not multi-band, mbf = 1;

%% 4. so: Slice order

if ~input_slicetime
    if strncmp(acq, 'interleaved', 11) % optimized for Siemens
        slice_time_unsorted = (0:(tr * mbf / num_slices):(tr-(tr * mbf / num_slices)))*1000; %(in msec)
        if mod(num_slices/mbf, 2) == 0
            so = repmat([2:2:num_slices/mbf 1:2:num_slices/mbf], 1, mbf);
        else
            so = repmat([1:2:num_slices/mbf 2:2:num_slices/mbf], 1, mbf);
        end
        
        slice_time_sorted = NaN(1,num_slices/mbf);
        for i = 1:(num_slices/mbf), slice_time_sorted(so(i)) = slice_time_unsorted(i); end
        slice_time = repmat(slice_time_sorted, 1, mbf);
        
        if strcmp(acq, 'interleaved_BU')
            % do nothing
        elseif strcmp(acq, 'interleaved_TD')
            slice_time = fliplr(slice_time);
        else
            error('STOP! Unrecognized image acquisition method');
        end
    else
        error('STOP! Unrecognized image acquisition method');
    end
end
    
slice_timing_job{1}.spm.temporal.st.so = slice_time;
slice_timing_job{1}.spm.temporal.st.refslice = find(slice_time==0, 1, 'first'); 
slice_timing_job{1}.spm.temporal.st.prefix = 'a';
    
%% Saving slice time correction job

if numel(session_num)==1
    PREPROC.slice_timing_job{session_num} = slice_timing_job{1};
    ao_func_files = prepend_a_letter(PREPROC.o_func_files(session_num), 1, 'a');
    PREPROC.ao_func_files{session_num} = ao_func_files{1};
else
    PREPROC.slice_timing_job = slice_timing_job{1};
    for i = session_num
        ao_func_files = prepend_a_letter(PREPROC.o_func_files(i), 1, 'a');
        PREPROC.ao_func_files{i} = ao_func_files{1};
    end
end

save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC

%% RUN

spm('defaults','fmri');
spm_jobman('initcfg');
spm_jobman('run', {slice_timing_job});
    
end


