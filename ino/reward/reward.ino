char init_char = '*';
char reward_status = '?';
int n_rewards = 2;
char reward_messages[2] = { 'A', 'B' };
char reward_size_end = 'V';
int reward_pins[2] = { 40, 44 };
int rewards[2] = { 0, 0 };
bool reward_state_changed[2] = { false, false };

unsigned long millisLastFrame;
unsigned long millisThisFrame;

void setup() {

  while ( !Serial ) {
    //  wait
  }

	Serial.begin( 115200 );

	Serial.print( init_char );
	
	for ( int i = 0; i < n_rewards; i++ ) {
		pinMode( reward_pins[i], OUTPUT );
	}
}

void loop() {

	millisThisFrame = millis();

	handleSerialComm();

  handleReward();

	millisLastFrame = millisThisFrame;

}

void handleSerialComm() {

	if ( Serial.available() <= 0 ) return;
	int inByte = Serial.read();
	char inChar = char( inByte );
	switch ( inChar ) {
		case '?':
			printRewardStatus();
			break;
		default:
			int index = findIndex( reward_messages, n_rewards, inChar );
      if ( index != -1 ) {
        String reward_size_str = readIn( reward_size_end, "" );
        int reward_size = stringToInt( reward_size_str, 0 );
        handleNewRewardSize( index, reward_size );
			}
	}
}

void handleNewRewardSize( int index, int value ) {

	rewards[index] = value;
	reward_state_changed[index] = true;
}

void handleReward() {

	unsigned long delta = millisThisFrame - millisLastFrame;
	for (int i = 0; i < n_rewards; i++ ) {
		if ( rewards[i] == 0 ) continue;
		rewards[i] -= delta;
		if ( rewards[i] <= 0 ) {
			reward_state_changed[i] = true;
			rewards[i] = 0;
		}
		if (!reward_state_changed[i]) continue;
		if ( rewards[i] == 0 ) {
			digitalWrite( reward_pins[i], LOW );
			reward_state_changed[i] = false;
		} else {
			digitalWrite( reward_pins[i], HIGH );
			reward_state_changed[i] = false;
		}
	}
}

void printRewardStatus() {

  while ( Serial.available() <= 0 ) {
    delay( 5 );
  }
	int channelId = Serial.read();
	bool rewardExpired = rewardIsExpired( char(channelId) );
	Serial.print( rewardExpired );
}

bool rewardIsExpired( char rewardId ) {

	int index = findIndex( reward_messages, n_rewards, rewardId );
	if ( index == -1 ) {
		Serial.print( '!' ); 
		return false;
	}
	return rewards[index] <= 0;
}

String readIn( char endMessage, String initial ) {
  
  while ( Serial.available() <= 0 ) {
    delay( 5 );
  }
  while ( Serial.available() > 0 ) {
    int pos = Serial.read();
    pos = char( pos );
    if ( pos == endMessage ) break;
    initial += char(pos);
  }
  return initial;
}

int findIndex( char* arr, int arrsz, char search ) {

	int pos = -1;
	for ( int i = 0; i < arrsz; i++ ) {
		if ( arr[i] == search ) {
			pos = i;
			break;
		}
	}
	return pos;
}

int stringToInt( String str, int removeNLeading ) {
  int bufferSize = str.length() + 1;
  char charNumber[ bufferSize ] = { 'b' };
  for ( int i = 0; i < removeNLeading; i++ ) {
    str.remove(0, 1);
  }
  str.toCharArray( charNumber, bufferSize );
  return atol( charNumber );
}
