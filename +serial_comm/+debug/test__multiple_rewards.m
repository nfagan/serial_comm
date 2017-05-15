function test__multiple_rewards()

serial_comm.util.close_ports();
b = serial_comm.SerialManager( 'COM4', struct(), 'A' );
b.start();

WaitSecs( 2 );

should_reward = true;

delay = tic;

while ( true )
    
  if ( should_reward )
    b.reward('A', 100);
    b.reward('A', 100);
%     b.reward('A', 500);
    should_reward = false;
  end

  b.update();
  
  if ( isempty(b.reward_manager.rewards(1).pending) )
    break;
  end

%   if ( toc(delay) > Inf ), break; end;    
end