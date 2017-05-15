classdef SerialManager < handle
  
  properties
    port;
    messages;
    comm;
    reward_manager;
    baud_rate;
    debounce_timer = NaN;
    debounce_amount = .001;
  end
  
  methods
    
    function obj = SerialManager(port, messages, channels)
      
      %   SERIAL_MANAGER -- Instantiate a SerialManager object.
      %
      %     IN:
      %       - `port` (char)
      %       - `messages` (struct array) -- Struct array with 'char' and
      %         'message' fields.
      %       - `channels` (cell array of strings) -- 
      
      serial_comm.util.assert__isa( messages, 'struct', ['The message' ...
        , ' struct'] );
      obj.messages = messages;
      obj.port = port;
      obj.comm = serial( port );
      obj.baud_rate = 115200; 
      obj.reward_manager = serial_comm.RewardManager( obj.comm, channels );
    end
    
    function set.baud_rate(obj, value)
      
      %   SET.BAUD_RATE -- Update the baud_rate property.
      %
      %     Updating this property updates the serial object `comm`.
      %
      %     IN:
      %       - `value` (double) -- New baud_rate.
      
      obj.baud_rate = value;
      obj.comm.BaudRate = value;
    end
    
    function start(obj)
      
      %   START -- Open the serial connection.
      
      fopen( obj.comm );
    end
    
    function close(obj)
      
      %   CLOSE -- Close the serial connection.
      
      fclose( obj.comm );
    end
    
    function reward(obj, channel, quantity)
      
      %   REWARD -- Deliver reward.
      %
      %     IN:
      %       - `channel` (char)
      %       - `quantity` (double) -- Amount of reward to deliver, in ms.
      
      obj.debounce( @reward_, channel, quantity );
    end
    
    function reward_(obj, channel, quantity)
      
      %   REWARD_ -- Debounced reward delivery.
      
      obj.reward_manager.reward( channel, quantity );
    end
    
    function varargout = debounce(obj, func, varargin)
      
      %   DEBOUNCE -- Call a function only after `debounce_amount` seconds
      %     have ellapsed since the last call to a function.
      %
      %     IN:
      %       - `func` (function_handle) -- Function to be called.
      %       - `varargin` (/any/) -- Any additional inputs to be passed.
      %     OUT:
      %       - `varargout` (/any/) -- Any outputs returned by the
      %         function.
      
      if ( isnan(obj.debounce_timer) )
        should_call = true;
      else should_call = toc( obj.debounce_timer ) > obj.debounce_amount;
      end      
      while ( ~should_call )
        should_call = toc( obj.debounce_timer ) > obj.debounce_amount;
      end      
      [varargout{1:nargout()}] = func( obj, varargin{:} );
      obj.debounce_timer = tic;
    end    
  end
  
end