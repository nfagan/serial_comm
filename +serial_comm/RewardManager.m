classdef RewardManager < handle
  
  properties
    comm;
    rewards;
    channels;
    RECEIPT_TIMEOUT = 5;
    INTER_REWARD_INTERVAL = .1;
    CHARS = struct( 'reward_status', '?', 'reward_end', 'V' );
  end
  
  methods
    function obj = RewardManager(comm, channels)
      
      %   REWARDMANAGER -- Instantiate a RewardManager object.
      %
      %     IN:
      %       - `comm` (serial) -- Serial communicator object.
      %       - `channels` (cell array of strings) -- Characters specifying
      %         each reward channel.
      
      serial_comm.util.assert__isa( comm, 'serial', 'the serial communicator' );
      channels = serial_comm.util.ensure_cell( channels );
      serial_comm.util.assert__is_cellstr( channels, 'the channel characters' );
      obj.comm = comm;
      obj.channels = channels;
      emp = repmat( {[]}, 1, numel(channels) );
      obj.rewards = struct( 'current', emp, 'pending', emp ...
        , 'last', emp, 'timer', emp );
    end
    
    function update(obj)
      
      %   UPDATE -- Update all pending and current rewards, for each
      %     channel.
      
      for i = 1:numel(obj.channels)
        obj.update_channel( obj.channels{i} );
      end
    end
    
    function update_channel(obj, channel)
      
      %   UPDATE_CHANNEL -- Update the pending / current rewards associated
      %     with a given channel.
      %
      %     This is an internal function not meant to be called directly.
      %
      %     IN:
      %       - `channel` (char) -- Channel identifier.
      
      ind = strcmp( obj.channels, channel );
      if ( isempty(obj.rewards(ind).pending) ), return; end
      str = sprintf( '%s%s', obj.CHARS.reward_status, channel );
      fprintf( obj.comm, '%s', str );
      response = obj.await_and_return_non_null();
      complete = isequal( response, '1' );
      incomplete = isequal( response, '0' );
      if ( ~complete && ~incomplete )
        error( 'Invalid reward feedback response ''%s''.', response );
      end
      if ( incomplete ), return; end;
      reward_end = obj.CHARS.reward_end;
      last = obj.rewards(ind).current;
      obj.rewards(ind).current = [];
      pending = obj.rewards(ind).pending;
      if ( ~isempty(pending) )
        current = pending(1);
        obj.rewards(ind).current = current;
        obj.rewards(ind).pending(1) = [];
        obj.rewards(ind).last = last;
        if ( ~isempty(last) )
          reward_timer = obj.rewards(ind).timer;
          should_proceed = false;
          while ( ~should_proceed )
            should_proceed = toc( reward_timer ) - last/1e3 >= ...
              obj.INTER_REWARD_INTERVAL;
          end
        end
        %   deliver reward
        str = sprintf( '%s%d%s', channel, round(current), reward_end );
        fprintf( obj.comm, '%s', str );
        obj.rewards(ind).timer = tic;
      end
    end
    
    function reward(obj, channel, quantity)
      
      %   REWARD -- Deliver a reward, or add a reward to the currently
      %     pending rewards.
      %
      %     obj.reward( 'A', 100 ) delivers a 100ms reward associated with
      %     channel 'A'.
      %
      %     obj.reward( 1, 100 ) delivers the reward to the channel
      %     identified by obj.channels{1}; i.e., the first channel.
      %
      %     IN:
      %       - `channel` (char, double) -- Channel specifier.
      %       - `quantity` (double) -- Reward size, in ms.
      
      if ( ischar(channel) )
        ind = strcmp( obj.channels, channel );
      else
        ind = channel;
        channel = obj.channels{ ind };
      end
      assert( any(ind), 'No channel matches ''%s''.', channel );
      obj.rewards(ind).pending(end+1) = quantity;
      obj.update_channel( channel );
    end
    
    function response = await_and_return_non_null(obj)
      
      %   AWAIT_AND_RETURN_NON_NULL -- Wait for and return a non-null
      %     character.
      
      import serial_comm.util.await_and_return_non_null;
      msg = sprintf( ['No reward completion feedback was received within' ...
            , ' %0.1f seconds.'], obj.RECEIPT_TIMEOUT );
      response = await_and_return_non_null( obj.comm, msg, obj.RECEIPT_TIMEOUT );
    end
  end
  
  methods (Static = true)
    
    function arr = ensure_cell( arr )
      
      %   ENSURE_CELL -- Ensure an input is a cell array.
      
      if ( ~iscell(arr) ), arr = { arr }; end;
    end
  end
  
end