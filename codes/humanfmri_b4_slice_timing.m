function PREPROC = humanfmri_b4_slice_timing(preproc_subject_dir, tr, mbf, varargin)

% This function does slice time correction for functional data. This is 
% using "MosaicRefAcqTimes" information (the actual slice timing information) 
% provided by dicm2nii. This should work for both multi-band (MB) and
% non-MB.
%
% :Usage:
% ::
%   PREPROC = humanfmri_b4_slice_timing(preproc_subject_dir, tr, mbf)
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
% :Optional Input:
%
% - custom_slice_timing    Specification of slice timing.
%                          Order(integer) or timing (in milliseconds, float)
%                          or type (character) are available.
%                          ex) Order : [1 3 5 7 2 4 6 8]',
%                              Timing : [0.0000 252.5000 62.5000 315.0000
%                                       125.0000 377.5000 190.0000]'
%                              Type: 'interleaved_ascending': Default for Philips and GE
%                                    'interleaved_ascending_siemens': Default for Siemens
%                                    'interleaved_descending'
%                                    'ascending'
%                                    'descending'
%                          (If not specified, slice timing is obtained by reading dicom header file)
%
% :Output(PREPROC):
% ::
%    PREPROC.slice_time
%    PREPROC.slice_timing_job
%    PREPROC.a_func_bold_files
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
%
% Programmer's notes:
%  ** Caution: This function hasn't been fully tested.
%              
run_num = [];

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case {'run_num'}
                run_num = varargin{i+1};
            case {'custom_slice_timing'}
                custom_slice_timing = varargin{i+1};
        end
    end
end

for subj_i = 1:numel(preproc_subject_dir)

    subject_dir = preproc_subject_dir{subj_i};
    [~,a] = fileparts(subject_dir);
    print_header('Slice timing correction', a);
    
    PREPROC = save_load_PREPROC(subject_dir, 'load'); % load PREPROC

    %% RUNS TO INCLUDE
    do_preproc = true(numel(PREPROC.preproc_func_bold_files),1);
    if ~isempty(run_num)
        do_preproc(~ismember(1:numel(PREPROC.preproc_func_bold_files), run_num)) = false;
    end
    
    %% DATA
    slice_timing_job{1}.spm.temporal.st.scans{1} = spm_select('expand', PREPROC.preproc_func_bold_files(do_preproc)); % individual 4d images in cell str

    %% 1. nslices
    Vfirst_vol = spm_vol([PREPROC.preproc_func_bold_files{1} ',1']);
    num_slices = Vfirst_vol(1).dim(3);
    slice_timing_job{1}.spm.temporal.st.nslices = num_slices; % number of slices

    %% 2. tr
    slice_timing_job{1}.spm.temporal.st.tr = tr;
    PREPROC.TR = tr;

    %% 3. ta: acquisition time
    slice_timing_job{1}.spm.temporal.st.ta = tr - tr * mbf / num_slices; % if not multi-band, mbf = 1;

    %% 4. so: Slice order
    
    if exist('custom_slice_timing', 'var')
        if isnumeric(custom_slice_timing)
            PREPROC.slice_time = custom_slice_timing(:).';
        elseif ischar(custom_slice_timing)
            switch custom_slice_timing
                case 'interleaved_ascending'
                    PREPROC.slice_time = [1:2:num_slices 2:2:num_slices];
                case 'interleaved_ascending_siemens'
                    if mod(num_slices, 2) == 1 % odd slices
                        PREPROC.slice_time = [1:2:num_slices 2:2:num_slices];
                    elseif mod(num_slices, 2) == 0 % even slices
                        PREPROC.slice_time = [2:2:num_slices 1:2:num_slices];
                    end
                case 'interleaved_descending'
                    PREPROC.slice_time = fliplr([1:2:num_slices 2:2:num_slices]);
                case 'ascending'
                    PREPROC.slice_time = 1:num_slices;
                case 'descending'
                    PREPROC.slice_time = fliplr(1:num_slices);
                otherwise
                    error('Slice timing information is strange.');
            end
        else
            error('Slice timing information is strange.');
        end
        fprintf('custom slice timing: \n');
    else
        dicomheader = load(PREPROC.dicomheader_files{1});
        PREPROC.slice_time = dicomheader.h.MosaicRefAcqTimes(:).'; % milliseconds
        fprintf('slice timing from dicom header: \n');
    end
    disp(PREPROC.slice_time);

    slice_timing_job{1}.spm.temporal.st.so = PREPROC.slice_time;
    
    %% 5. refslice: Reference slice (first)
    
    if isequal(1:num_slices, sort(PREPROC.slice_time, 'ascend')) % Order-based
        [~, ref_slice] = min(PREPROC.slice_time);
        fprintf('Reference slice number: %d \n', ref_slice);
    else
        if min(PREPROC.slice_time) >= 0 && max(PREPROC.slice_time)/1000 <= tr % Time-based
            ref_slice = min(PREPROC.slice_time);
            fprintf('Reference time: %f \n', ref_slice);
        else
            error('Slice timing information is strange.');
        end
    end
    slice_timing_job{1}.spm.temporal.st.refslice = ref_slice;
    
    %% 6. prefix
    
    slice_timing_job{1}.spm.temporal.st.prefix = 'a';
    
    %% Saving slice time correction job
    
    PREPROC.slice_timing_job = slice_timing_job{1};
    PREPROC.a_func_bold_files = prepend_a_letter(PREPROC.preproc_func_bold_files, ones(size(PREPROC.preproc_func_bold_files)), 'a');
    
    save_load_PREPROC(subject_dir, 'save', PREPROC); % save PREPROC
    
    %% RUN
    
    spm('defaults','fmri');
    spm_jobman('initcfg');
    spm_jobman('run', slice_timing_job);

end
    
end


