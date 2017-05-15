function close_ports()

%   CLOSE_PORTS -- Close all open ports.

ports = instrfind();
if ( isempty(ports) ), return; end;
fclose( ports );

end