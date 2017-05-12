function response = await_and_return_non_null(comm, msg, timeout)

%   AWAIT_AND_RETURN_NON_NULL -- Wait for and return a non-null character.
%
%     IN:
%       - `comm` (serial) -- Serial communicator object.
%       - `msg` (char) -- Error message, in case the await times-out
%       - `timeout` (double) -- Number of seconds to wait for response, in
%         seconds.

start_await = tic;
while ( comm.BytesAvailable == 0 )
  if ( toc(start_await) > timeout ), error( msg ); end;
end
response = '';
success = true;
start_await = tic;
while ( isequal(response, '') )
  if ( comm.BytesAvailable == 0 ), success = false; break; end;
  timed_out = toc( start_await ) > timeout;
  if ( timed_out ), success = false; break; end;
  response = fscanf( comm, '%s', 1 );
end
if ( ~success ), error( msg ); end;

end