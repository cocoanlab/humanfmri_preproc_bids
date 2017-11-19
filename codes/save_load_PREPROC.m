function PREPROC = save_load_PREPROC(subject_dir, varargin)

% support function for save and load the PREPROC file
% 
% :Usage:
% :: 
%       save_load_PREPROC(subject_dir, 'save', PREPROC)  for save
%       save_load_PREPROC(subject_dir, 'load')  for load

fname = fullfile(subject_dir, 'PREPROC.mat');

switch varargin{1}
    case 'load'
        a = load(fname); % load PREPROC 
        PREPROC = a.PREPROC;
    case 'save'
        PREPROC = varargin{2};
        save(fname, 'PREPROC')
end

end
        
