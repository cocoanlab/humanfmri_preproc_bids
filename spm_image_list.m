function image_list = spm_image_list(image_list, do_indiv_cellstrs)

% spm's batch handling appears to be changing in some versions of SPM8
% the optional flag do_indiv_cellstrs will make the files into a single,
% individual list of cells, one volume per cell.
%
% :Usage:
% ::
%     image_list = spm_image_list(image_list, do_indiv_cellstrs)
%

if nargin < 2, do_indiv_cellstrs = 0; end

if ~iscell(image_list)
    image_list = cellstr(image_list); % should already be cells; just in case
end

for i = 1:length(image_list)
    image_list{i} = expand_4d_filenames(image_list{i});
end

doflatten = 0;
if do_indiv_cellstrs
   for i = 1:length(image_list)
    if size(image_list{i}, 1) > 1
        doflatten = 1;
    end
   end
end

if doflatten
    image_list = char(image_list{:});
    image_list = cellstr(image_list);
end


end % function