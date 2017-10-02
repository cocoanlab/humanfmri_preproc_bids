function print_header(str, str2)

% :Usage:
% :: 
%   print header(str, str2)

  s = '======================================================================================';
  len = length(s);

  disp('======================================================================================');
  disp('=                                                                                    =');
  fprintf('= %s%s=\n', str, repmat(' ', 1, max([1 length(s) - length(str) - 3])));
  if nargin > 1
    fprintf('= %s%s=\n', str2, repmat(' ', 1, max([1 length(s) - length(str2) - 3])));
  end
  disp('=                                                                                    =');
  disp('======================================================================================');


end