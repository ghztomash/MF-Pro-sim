// MIDI Fighter Pro simulator
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

int knobAValue = 0;
int knobBValue = 0;

//midi values
int channel = 2;
int velocity = 127;

//store the previous button state
boolean arcadeState[]=new boolean[16];
boolean connected;

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
  sliderA= controlP5.addSlider("sliderA",0,127,64,90,300,14,130);
  sliderA= controlP5.addSlider("sliderB",0,127,64,205,300,14,130);

  // create the midi prot list
  midiOut = controlP5.addDropdownList("midiOut",100,75,140,80);
  for(int i=0;i<myBus.availableOutputs().length;i++) {
    midiOut.addItem(myBus.availableOutputs()[i],i); //populate the list
  }
  //create a connect button
  controlP5.addButton("connect", 10, 260, 65, 80, 10);
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
    myBus.sendControllerChange(channel, 16, theValue); // Send a controllerChange
  println("A knob event "+theValue);
}

void knobB(int theValue) {
  if(connected)
    myBus.sendControllerChange(channel, 18, theValue); // Send a controllerChange
  println("B knob event "+theValue);
}

void sliderA(int theValue) {
  if(connected)
    myBus.sendControllerChange(channel, 20, theValue); // Send a controllerChange
  println("A slider event "+theValue);
}

void sliderB(int theValue) {
  if(connected)
    myBus.sendControllerChange(channel, 22, theValue); // Send a controllerChange
  println("B slider event "+theValue);
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
      bank=0;
      break;
    case '2':
      bank=1;
      break;
    case '3':
      bank=2;
      break;
    case '4':
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
