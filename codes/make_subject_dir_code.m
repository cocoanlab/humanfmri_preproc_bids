function [preproc_subject_dir, subject_code] = make_subject_dir_code(study_imaging_dir, projName,subjNo)
% Make cell array of 'subject_code' and 'preproc_subject_dir' based on
% project name.
%
%   ::Usage::
%       [preproc_subject_dir, subject_code]
%           = make_subject_code(study_imaging_dir, projName,subjNo)
%   ::Input::
%        - study_imaging_dir:
%           (e.g., '/Volumes/sein/hbmnas/data/SEMIC/imaging'; )
%        - projName: project name (e.g., 'semic', 'fast', 'pico')
%        - subjNo: subject number want to make (e.g., 1:3, [1:3, 39:40])
%
%
% Suhwan Gim
% Feb, 2019

%% 
c=1;
clear subject_code

num_sub = length(subjNo);
for i=1:num_sub
    subject_code{1,c} = ['sub-' projName sprintf('%03d',subjNo(i))];
    disp(subject_code{1,c}); % for check
    c = c+1;
end
fprintf('Total number of subjects is %d\n', length(subject_code));
preproc_subject_dir = fullfile(study_imaging_dir, 'preprocessed', subject_code);
end