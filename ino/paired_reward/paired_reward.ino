#include <Wire.h>

char init_char = '*';
char reward_status = '?';
int n_rewards = 2;
char reward_messages[2] = { 'A', 'B' };
char reward_size_end = 'V';
int reward_pins[2] = { 11, 44 };
int rewards[2] = { 0, 0 };
bool reward_state_changed[2] = { false, false };

#define BSLAVE 'S'
#define BMASTER 'M'
#define WIRE_ACK 'W'

//  WIRE

bool wire_initialized = false;
bool bslave = true;
bool bmaster = false;

int SLAVE_ADDRESS = 9;

unsigned long millisLastFrame;
unsigned long millisThisFrame;

void setup() {

  while ( !Serial ) {
    //  wait
  }

  Serial.print( init_char );

  Serial.begin( 115200 );
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
    case BSLAVE:
      startWire( false );
      break;
    case BMASTER:
      startWire( true );
      break;
    default:
      int index = findIndex( reward_messages, n_rewards, inChar );
      if ( index != -1 ) {
        String reward_size_str = readIn( reward_size_end, "" );
        if ( bslave ) {
          int reward_size = stringToInt( reward_size_str, 0 );
          handleNewRewardSize( index, reward_size );
        } else {
          String reward_size_str_ = "A";
          reward_size_str_.setCharAt( 0, inChar );
          reward_size_str_ += reward_size_str;
          Wire.beginTransmission( SLAVE_ADDRESS );
          Wire.write( reward_size_str_.c_str() );
          Wire.endTransmission();
        }
      }
  }
}

void startWire( bool bmaster ) {
  
  if ( wire_initialized ) return;
  if ( bmaster ) {
    Wire.begin();
    bmaster = true;
    bslave = false;
  } else {
    bslave = true;
    bmaster = false;
    Wire.begin( SLAVE_ADDRESS );
    Wire.onReceive( handleReceipt );
//    Wire.onRequest( handleRequest );
  }
  wire_initialized = true;
  Serial.print( WIRE_ACK );
}

void handleReceipt( int n_bytes ) {

  if ( n_bytes == 1 ) return;
  while ( Wire.available() <= 0 ) {
    //
  }
  char id_char = Wire.read();
  switch ( id_char ) {
    default:
      int index = findIndex( reward_messages, n_rewards, id_char );
      if ( index != -1 ) {
        String reward_size_str = readInWire( reward_size_end, "" );
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

String readInWire( char endMessage, String initial ) {
  
  while ( Wire.available() <= 0 ) {
    delay( 5 );
  }
  while ( Wire.available() > 0 ) {
    int pos = Wire.read();
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
