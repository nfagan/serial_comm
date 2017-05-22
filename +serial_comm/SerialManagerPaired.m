classdef SerialManagerPaired < serial_comm.SerialManager
  
  properties
    role;
    WIRE_TIMEOUT = 5;
  end
  
  methods
    function obj = SerialManagerPaired(port, messages, channels, role)
      
      %   SERIAL_MANAGER -- Instantiate a SerialManager object.
      %
      %     IN:
      %       - `port` (char)
      %       - `messages` (struct array) -- Struct array with 'char' and
      %         'message' fields.
      %       - `channels` (cell array of strings) -- Reward channel ids.
      %       - `role` (char) -- 'slave' or 'master'
      
      obj = obj@serial_comm.SerialManager( port, messages, channels );
      serial_comm.util.assert__isa( role, 'char', 'the slave / master role' );
      role = lower( role );
      assert( any(strcmp({'slave', 'master'}, role)), ['Specify role as' ...
        , ' either ''slave'' or ''master''.'] );
      obj.role = role;
    end
    
    function start(obj)
      
      %   START -- Open the serial connection.
      %
      %     The object will wait for initialization feedback from the
      %     Arduino. If this is not received within `obj.INIT_TIMEOUT`
      %     seconds, an error is thrown.
      %
      %     The object will then declare its role and await feedback that
      %     Wire data transfer is ready. If this is not received within
      %     `obj.WIRE_TIMEOUT` seconds, an error is thrown.
      
      start@serial_comm.SerialManager( obj );      
      timeout = obj.WIRE_TIMEOUT;
      wire_feedback_char = obj.CHARS.wire_feedback;
      wire_init_char = obj.CHARS.(obj.role);
      fprintf( obj.comm, '%s', wire_init_char );
      msg = 'Wire initialization timed-out.';
      response = serial_comm.util.await_and_return_non_null( obj.comm ...
        , msg, timeout );
      assert( isequal(response, wire_feedback_char), ['Expected to receive the' ...
        , ' Wire initialization feedback character ''%s'', but received ''%s''.'] ...
        , wire_feedback_char, response );
    end
  end
  
end