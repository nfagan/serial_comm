char REWARD_STATUS = '?';
int N_REWARDS = 2;
char REWARD_MESSAGES[N_REWARDS] = { 'A', 'B' };
int REWARD_PINS[N_REWARDS] = { 44, 40 };
int REWARDS[N_REWARDS] = { 0, 0 };
bool REWARD_STATE_CHANGED[N_REWARDS] = { false, false };

unsigned long millisLastFrame;
unsigned long millisThisFrame;

void setup() {

	Serial.begin( 115200 );
	for ( int i = 0; i < N_REWARDS; i++ ) {
		pinMode( REWARD_PINS[i], OUTPUT );
	}
}

void loop() {

	millisThisFrame = millis();

	handleReward();

	handleSerialComm();

	millisLastFrame = millisThisFrame;

}

void handleSerialComm() {

	if ( Serial.available() <= 0 ) return;
	int inByte = Serial.read();
	char inChar = char( inByte );
	switch ( inChar ) {
		case REWARD_STATUS:
			printRewardStatus();
			break;
		default:
			int index = findRewardIndex( inChar );
			if ( index == -1 ) {
				Serial.print( '!' );
			} else {
				//	update reward size somehow
				//	handleNewRewardSize()
			}
	}
}

void handleNewRewardSize( int index, int value ) {

	REWARDS[index] = value;
	REWARD_STATE_CHANGED[index] = true;
}

void handleReward() {

	unsigned long delta = millisThisFrame - millisLastFrame;
	for (int i = 0; i < N_REWARDS; i++ ) {
		if ( REWARDS[i] == 0 ) continue;
		REWARDS[i] -= delta;
		if ( REWARDS[i] <= 0 ) {
			REWARD_STATE_CHANGED[i] = true;
			REWARDS[i] = 0;
		}
		if (!REWARD_STATE_CHANGED[i]) continue;
		if ( REWARDS[i] == 0 ) {
			digitalWrite( REWARD_PINS[i], LOW );
			REWARD_STATE_CHANGED[i] = false;
		} else {
			digitalWrite( REWARD_PINS[i], HIGH );
			REWARD_STATE_CHANGED[i] = false;
		}
	}
}

void printRewardStatus() {

	int channelId = Serial.read();
	bool rewardExpired = rewardIsExpired( char(channelId) );
	Serial.print( rewardExpired );
}

bool rewardIsExpired( char rewardId ) {

	int index = findRewardIndex( rewardId );
	if ( index == -1 ) {
		Serial.println( '!' ); 
		return false;
	}
	return REWARDS[index] <= 0;
}

int findRewardIndex( char search ) {
	
	return findIndex( REWARD_MESSAGES, N_REWARDS, search );
}

int findIndex( char arr, int arrsz, char search ) {

	int pos = -1;
	for ( int i = 0; i < arrsz; i++ ) {
		if ( arr[i] == search ) {
			pos = i;
			break;
		}
	}
	return pos;
}
