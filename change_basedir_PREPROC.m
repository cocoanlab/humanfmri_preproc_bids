function PREPROC = change_basedir_PREPROC(PREPROC, new_basedir)

% This function changes basedir in PREPROC. This doesn't save new PREPROC 
% in "PREPROC.mat" file. 
%
% :Usage:
% ::
%    PREPROC = change_basedir_PREPROC(PREPROC, new_basedir)
%
% :Input:
% ::
%
% - PREPROC     
% - new_basedir    new basedir
%
% :Output:
% :: 
%     new_PREPROC
%
% :Example:
%    new_basedir = '/data/caps2';
%    PREPROC = change_basedir_PREPROC(PREPROC, new_basedir)
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

f = fields(PREPROC);

old_basedir = PREPROC.study_imaging_dir;
old_base_character_n = numel(old_basedir);

for i = 1:numel(f)
    
    if eval(['~(isstruct(PREPROC.' f{i} ') | isnumeric(PREPROC.' f{i} ') | contains(f{i}, ''job''))'])
        
        if eval(['~ischar(PREPROC.' f{i} ')'])
            temp = eval(['PREPROC.' f{i}]);
        else
            temp = cellstr(eval(['PREPROC.' f{i}]));
        end
            
        basedir_idx = contains(temp, old_basedir);
        if any(basedir_idx)
            for j = 1:numel(basedir_idx)
                wh_start = strfind(temp{j}, old_basedir);
                temp{j}(wh_start:old_base_character_n) = [];
                temp{j} = fullfile(new_basedir, temp{j});
            end
        end
        
        if eval(['ischar(PREPROC.' f{i} ')'])
            eval(['PREPROC.' f{i} ' = char(temp);']);
        else
            eval(['PREPROC.' f{i} ' = temp;']);
        end
    end
    
end

f2 = fields(PREPROC.topup);
for i = 1:numel(f2)
    wh_start = strfind(eval(['PREPROC.topup.' f2{i} ]), old_basedir);
    eval(['PREPROC.topup.' f2{i} '(wh_start:old_base_character_n) = [];']);
    eval(['PREPROC.topup.' f2{i} ' = fullfile(new_basedir, PREPROC.topup.' f2{i} ');']);
end

end