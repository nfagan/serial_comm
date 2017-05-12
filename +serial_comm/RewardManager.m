classdef RewardManager < handle
  
  properties
    comm;
    rewards;
    channels;
    RECEIPT_TIMEOUT = 5;
    CHARS = struct( 'reward_status', '?' );
  end
  
  methods
    function obj = RewardManager(comm, channels)
      
      %   REWARDMANAGER -- Instantiate a RewardManager object.
      %
      %     IN:
      %       - `comm` (serial) -- Serial communicator object.
      %       - `channels` (cell array of strings) -- Characters specifying
      %         each reward channel.
      
      obj.assert__isa( comm, 'serial', 'the serial communicator' );
      obj.assert__is_cellstr( channels, 'the channel characters' );
      obj.comm = comm;
      obj.channels = channels;
      emp = repmat( {[]}, 1, numel(channels) );
      obj.rewards = struct( 'current', emp, 'pending', emp, 'last', emp );
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
      fprintf( obj.comm, '%s%s', obj.CHARS.reward_status, channel );
      response = obj.await_and_receive_non_null();
      complete = isequal( response, '1' );
      incomplete = isequal( response, '0' );
      if ( ~complete && ~incomplete )
        error( 'Invalid reward feedback response ''%s''.', response );
      end
      if ( incomplete ), return; end;
      last = obj.rewards(ind).current;
      obj.rewards(ind).current = [];
      pending = obj.rewards(ind).pending;
      if ( ~isempty(pending) )
        obj.rewards(ind).current = pending(1);
        obj.rewards(ind).pending(1) = [];
        obj.rewards(ind).last = last;
        %   deliver reward
        fprintf( obj.comm, '%s', channel );
      end
    end
    
    function reward(obj, channel, quantity)
      
      %   REWARD -- Deliver a reward, or add a reward to the currently
      %     pending rewards.
      %
      %     IN:
      %       - `channel` (char) -- Channel specifier.
      %       - `quantity` (double) -- Reward size, in ms.
      
      ind = strcmp( obj.channels, channel );
      assert( any(ind), 'No channel matches ''%s''.', channel );
      obj.rewards(ind).pending(end+1) = quantity;
      obj.update();
    end
    
    function response = await_and_return_non_null(obj)
      
      %   AWAIT_AND_RETURN_NON_NULL -- Wait for and return a non-null
      %     character.
      
      import serial_comm.util.await_and_return_non_null;
      msg = sprintf( ['No reward completion feedback was received within' ...
            , ' %0.1f seconds.'], obj.RECEIPT_TIMEOUT );
      response = await_and_return_non_null( obj.comm, msg, obj.RECEIPT_TIMEOUT );
    end
    
    function assert__isa(obj, var, kind, var_name)
      
      %   ASSERT__ISA -- Ensure a variable is of a given kind.
      %
      %     IN:
      %       - `var` (/any/) -- Variable to check.
      %       - `kind` (char) -- Expected class of `var`.
      %       - `var_name` (char) |OPTIONAL| -- Optionally provide a more
      %         descriptive name for the variable in case the assertion
      %         fails.
      
      if ( nargin < 4 ), var_name = 'input'; end;
      assert( isa(var, kind), 'Expected %s to be a ''%s''; was a ''%s''.' ...
        , var_name, kind, class(var) );
    end
    
    function assert__is_cellstr(obj, var, var_name)
      
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
  end
  
end