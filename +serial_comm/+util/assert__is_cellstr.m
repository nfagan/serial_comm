function assert__is_cellstr(var, var_name)
      
%   ASSERT__IS_CELLSTR -- Ensure a variable is a cell aray of
%     strings.
%
%     IN:
%       - `var` (/any/) -- Variable to check.
%       - `var_name` (char) |OPTIONAL| -- Optionally provide a more
%         descriptive name for the variable in case the assertion
%         fails.

if ( nargin < 3 ), var_name = 'input'; end;
assert( iscellstr(var), ['Expected %s to be a cell array of strings;' ...
  , ' was a ''%s'''], var_name, class(var) );
end