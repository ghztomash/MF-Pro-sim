//MIDI Fighter Pro simulator
//tomash ghz
//www.tomashg.com

import themidibus.*; //Import the library

MidiBus myBus; // The MidiBus

import controlP5.*; // library for GUI
ControlP5 controlP5;


PImage backg; // backround image

int bank=0; //bank number

//gui elements
Knob knobA;
Knob knobB;
Slider sliderA;
Slider sliderB;
DropdownList midiOut;

int knobAVal = 0;
int knobBVal = 0;
int faderAVal = 0;
int faderBVal = 0;

//midi values
int channel = 2;
int velocity = 127;

//store the previous button state
boolean arcadeState[]=new boolean[16];
boolean connected;
boolean traktormode; // if enabled sends smart knob CCs and combos

// store the keystroeks pressed to recognize the combos
ArrayList keystrokes;
String combos;
char comboActive='n';

void setup(){
  //set window size
  size(800,520);
  smooth();
  //load background image
  backg= loadImage("mf-pro.jpg");
  
  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.
    
//                   Parent In Out
//                     |    |  |
  //myBus = new MidiBus(this, 0, 0); // Create a new MidiBus using the device index to select the Midi input and output devices respectively.
  
  //load gui elements
  controlP5 = new ControlP5(this);
  knobA = controlP5.addKnob("knobA",0,127,0,60,100,65);
  knobB = controlP5.addKnob("knobB",0,127,0,160,100,65);
  sliderA= controlP5.addSlider("sliderA",0,127,0,90,300,14,130);
  sliderA= controlP5.addSlider("sliderB",0,127,0,205,300,14,130);

  // create the midi prot list
  midiOut = controlP5.addDropdownList("midiOut",100,75,140,80);
  for(int i=0;i<myBus.availableOutputs().length;i++) {
    midiOut.addItem(myBus.availableOutputs()[i],i); //populate the list
  }
  //create a connect button
  controlP5.addButton("connect", 10, 260, 65, 80, 10);
  controlP5.addToggle("traktormode",false,360,65,10,10);
  
  keystrokes=new ArrayList();
}

void draw(){
  //redraw frame
  background(backg);
  
  //draw bank buttons
  fill(255,255,0,224);
  rect(290,120+bank*87,30,30);
  
}

//gui event handlers
void knobA(int theValue) {
  if(connected)
    sendCC(channel, 16, theValue,knobAVal); // Send a controllerChange
  println("A knob event "+theValue);
  knobAVal=theValue;
}

void knobB(int theValue) {
  if(connected)
    sendCC(channel, 18, theValue,knobBVal); // Send a controllerChange
  println("B knob event "+theValue);
  knobBVal=theValue;
}

void sliderA(int theValue) {
  if(connected)
    sendCC(channel, 20, theValue,faderAVal); // Send a controllerChange
  println("A slider event "+theValue);
  faderAVal=theValue;
}

void sliderB(int theValue) {
  if(connected)
    sendCC(channel, 22, theValue,faderBVal); // Send a controllerChange
  println("B slider event "+theValue);
  faderBVal=theValue;
}
// event for the connect button
void connect(){
  myBus = new MidiBus(this,-1,myBus.availableOutputs()[(int)midiOut.value()]);
  connected=true;
}

//keyboard event handler
void keyPressed(){
  switch(key){
    //bank buttons
    case '1':
      if(traktormode)
        myBus.sendNoteOn(channel, 4, 127);
      else
        bank=0;
      break;
    case '2':
      if(traktormode)
        myBus.sendNoteOn(channel, 5, 127);
      else
        bank=1;
      break;
    case '3':
      if(traktormode)
        myBus.sendNoteOn(channel, 6, 127);
      else
        bank=2;
      break;
    case '4':
      if(traktormode)
        myBus.sendNoteOn(channel, 7, 127);
      else
        bank=3;
      break;
    //arcade buttons
    default:
      int button=findButton(key);
      // the button is a valid button and has not been pressed already
      if((button!=-1)&&(!arcadeState[button])){
        arcadeState[button]=true;
        if(connected)
          myBus.sendNoteOn(channel, button+bank*16+36, velocity); // Send a Midi noteOn
        println("button " + (button+bank*16)+ " pressed"); 
        if(traktormode)
          addKey(key+"1"); //add a key to the keystroke buffer
      }
      break;
  }
  
  
}

void keyReleased(){
  //release the pressed button
  
  int button=findButton(key);
      // the button is a valid button and has not been pressed already
      if((button!=-1)&&(arcadeState[button])){
        arcadeState[button]=false;
        if(connected)
          myBus.sendNoteOff(channel, button+bank*16+36, velocity); // Send a Midi nodeOff
        println("button " +  (button+bank*16) + " released"); 
        if(traktormode)
          addKey(key+"0"); //add a key to the keystroke buffer
      }
}

//function to find the pressed key index of arcade button
int findButton(char c){
  char chList[]={'v','b','n','m',
                 'g','h','j','k',
                 't','y','u','i',
                 '6','7','8','9'};
  
  for(int i=0;i<16;i++){
    if(c==chList[i]) 
      return i;//return the char index
  }
  
  return -1;
}

void sendCC(int channel, int number, int value, int oldValue){
  myBus.sendControllerChange(channel, number, value); // Send a controllerChange
  //send the advanced traktor midi messages
  
// 0  3            64           124 127
// |--|-------------|-------------|--| - full range
//
// |0=======================127| - CC A
// |0=========105| - CC B
//
// |__|on____________________________| - note A
// |off___________________________|on| - note B
//    3                          124
  
  if(traktormode){
    println(oldValue);
    println(value);
    
     if((value>3)&&(oldValue<=3)){ // send the 0 value note on
        myBus.sendNoteOn(channel, number+84, 127);
        println("sending A on");
     }
     else if((value<=3)&&(oldValue>3)){
        myBus.sendNoteOff(channel, number+84, 0);
        println("sending A off");
     }
     if((value>124)&&(oldValue<=124)){ // send the 127 value note on
        myBus.sendNoteOn(channel, number+85, 127);
        println("sending B on");
     }
     else if((value<=124)&&(oldValue>124)){
       myBus.sendNoteOff(channel, number+85, 0);
       println("sending B off");
     }
     
     if(value<=64) // send the secondary cc
        myBus.sendControllerChange(channel, number+1, (int)map(value,0,64,0,105));
  }
}

//functions to check the secret combos
void addKey(String k){
  keystrokes.add(k);
  if(keystrokes.size()>=20) // we need to store only up to 20 key presses for the last combo
    keystrokes.remove(0);
    
  combos="";
  for (int i=0; i<keystrokes.size(); i++){
    combos=combos+(keystrokes.get(i).toString()); // cast the keystrokes into an String so that we can check the suffix
  }
  //println(combos);
  checkCombo();
}

void checkCombo(){
  
  // COMBOS
  //
  //   A          B           C           D           E
  // +--------+ +--------+  +--------+  +--------+  +--------+
  // |        | |        |  |        |  |        |  |        |
  // |        | |        |  |  y u   |  |        |  |t       |
  // |        | |g h j k |  |  h j   |  |g h j k |  |g h j k |
  // |v b n m | |        |  |        |  |        |  |v       |
  // +--------+ +--------+  +--------+  +--------+  +--------+
  //  v-b-n-m    g-h-j-k     hold all   a-b-c-c-d   ttvvghghkj
  //      X X        X X                        X            X  
  // Combos retain a NoteOn while the final key is depressed and emit a NoteUp
  // when it is released.
  // Combo A    G#-2
  // Combo B    A-2
  // Combo C	A#-2
  // Combo D	B-2
  // Combo E	C-1
  
  // for some reason we can have only 2 keys pressed at a time(!?) in the same row  
  // so the combos will work when the keys are pressed and released in sequence appart from the 
  // buttons that have X which you have to hold
  
  //check the combo combinations
  if(combos.endsWith("v1v0b1b0n1m1")){
    comboActive='a';
    println("Combo A");
    myBus.sendNoteOn(channel, 8, 127);
  }else
  if(combos.endsWith("g1g0h1h0j1k1")){
    comboActive='b';
    println("Combo B");
    myBus.sendNoteOn(channel, 9, 127);
  }else
  if(combos.endsWith("h1j1y1u1")){
    comboActive='c';
    println("Combo C");
    myBus.sendNoteOn(channel, 10, 127);
  }else
  if(combos.endsWith("g1g0h1h0j1j0j1j0k1")){
    comboActive='d';
    println("Combo D");
    myBus.sendNoteOn(channel, 11, 127);
  }else
  if(combos.endsWith("t1t0t1t0v1v0v1v0g1g0h1h0g1g0h1h0k1k0j1")){
    comboActive='e';
    println("Combo E");
    myBus.sendNoteOn(channel, 12, 127);
  }else
  {
    if (comboActive!='n'){//a combo was active send note off
      switch(comboActive){
        case 'a':
          println("Combo A broken");
          myBus.sendNoteOff(channel, 8, 0);
          break;
        case 'b':
          println("Combo B broken");
          myBus.sendNoteOff(channel, 9, 0);
          break;
        case 'c':
          println("Combo C broken");
          myBus.sendNoteOff(channel, 10, 0);
          break;
        case 'd':
          println("Combo D broken");
          myBus.sendNoteOff(channel, 11, 0);
          break;
        case 'e':
          println("Combo E broken");
          myBus.sendNoteOff(channel, 12, 0);
          break;
      }
    }
    comboActive='n';
  }
  
}
