function arr = ensure_cell( arr )

%   ENSURE_CELL -- Ensure an input is a cell array.

if ( ~iscell(arr) ), arr = { arr }; end;

end