import ddf.minim.*; //needed for sound right now, TODO: check out sound.js instead
import g4p_controls.*;

/**
This is a attempt to combine the string and slider classes. 
This is somewhere in between almost clean and absolute mess. Sorry.
**/

//objects we'll need
MusicString string, string1;
ArrayList<MusicString> strings; //arraylist so user can add and remove strings whenever

//size of animation screen
int boxLength = 900;
int boxHeight = 750;

boolean stringOver = false;

//sliders
GCustomSlider tSdr;
GCustomSlider lSdr;
GCustomSlider wSdr;

//slider attributes
int sliderLength = 500;
int sliderHeight = 50;
int sliderX = boxLength/2 - sliderLength/2; //left edge of of sliders
int sliderY = boxHeight - 250; // y coord of first slider

//audio outputs
Minim minim, goalMinim;
AudioOutput output, goalOutput;

//current frame
int drawIndex = 0; 

//frequency of animation
float drawingFreq = 3; 

float defaultTime = 1/(2*PI*drawingFreq);

//freq to match
//float goalFreq = getRandomFreq();
float goalFreq;
PFont fSmall;
PFont fBig;

MusicString currString; //musicstring to keep track of which can currently be altered

String[] objective = { "Make your string’s frequency match the Goal Frequency by only changing length." ,
            "Make your string’s frequency match the Goal Frequency by only changing weight",
            "Make your string’s frequency match the Goal Frequency by only changing tension" };

  //2d array for tension color scale
  float[][] tColors = new float[3][201]; //3 columns, for RGB, and 40 rows
  float r = 0;
  float g = 0;
float b = 0;

/*

SETUP

*/

void setup() {
  //setup screen
  size(boxLength, boxHeight);
  background (255);
  
  //initialize slider(s) and musicstring(s)
  string = new MusicString(200);  //TODO: Make this reflect goal freq
  string1 = new MusicString(350); 
  
  
  //initialize the list of strings
  strings = new ArrayList<MusicString>();
  strings.add(string);
  strings.add(string1);

  //generate values for goal string
  string.setRandomValues();
  goalFreq = getStrFreq(string.realLength, string.realTension, string.realWeight);
  
  
  //set the current string
  string1.setCurrent(true);
  for (MusicString ms : strings) {
  if(ms.getCurrent()) {
    currString = ms;
    break;  //so there's only ever one
  }
  }
  
  //initialize sound outputs
  minim = new Minim(this);
  output = minim.getLineOut();
  goalMinim = new Minim(this);
  goalOutput = goalMinim.getLineOut();

  tSdr = new GCustomSlider(this, sliderX, sliderY, sliderLength, sliderHeight, null);
    //args are xpos, ypos, length, width
  // show          opaque  ticks value limits
  tSdr.setShowDecor(false, true, false, true);
  tSdr.setNbrTicks(5);
  tSdr.setLimits(70, 70, 90);
  tSdr.setNumberFormat(G4P.DECIMAL, 1);
  
  lSdr = new GCustomSlider(this, sliderX, sliderY + 80, sliderLength, sliderHeight, null);
    //args are xpos, ypos, length, width
  // show          opaque  ticks value limits
  lSdr.setShowDecor(false, true, false, true);
  lSdr.setNbrTicks(5);
  lSdr.setLimits(5, 10, 70);
  lSdr.setNumberFormat(G4P.DECIMAL, 1);
  
  wSdr = new GCustomSlider(this, sliderX, sliderY + 160, sliderLength, sliderHeight, null);
    //args are xpos, ypos, length, width
  // show          opaque  ticks value limits
  wSdr.setShowDecor(false, true, false, true);
  wSdr.setNbrTicks(5);
  wSdr.setLimits(0.5, 0.5, 7.5);
  wSdr.setNumberFormat(G4P.DECIMAL, 1);
  
  //fonts
   fSmall = createFont("Arial",16,true);
  fBig = createFont("Arial",32,true);
  
  
   //initialize array of tension colors, starts at blue for lowest tension and changes to red for highest tension
  //array is 2D, column number specifies color (0=R,1=G,2=B) and row is the tension index
  for (int k=0; k<201; k=k+1){
    if (k<=100){
      tColors[0][k] = 0;
      r = 0;
      g = k/100.;
      b = 1-k/100.;
      if(g>=b){
        tColors[1][k] = 255;
        tColors[2][k] = 255.*b/g;
      }
      if(g<b){
        tColors[2][k] = 255;
        tColors[1][k] = 255.*g/b;
      }
    }
    if (k>100){
      tColors[2][k] = 0;
      g = 1 - (k-100.)/100.;
      r = (k-100.)/100.;
      if(g>=r){
        tColors[1][k] = 255;
        tColors[0][k] = 255.*r/g;
      }
      if(g<r){
        tColors[0][k] = 255;
        tColors[1][k] = 255.*g/r;
      }
      
    }
  }
  

  
}

/*

DRAW

*/
void draw() {

  //background color, called to wipe screen each frame
  background(255);
  textAlign(CENTER, BOTTOM);
  
 //show current value of...
  //...the goal frequency
  textFont(fBig,24);
  text("Change String 2 to match the frequency of String 1.", boxLength/2,80);
  textFont(fBig,16);
  text("String 1", 100,200);
  text("f = " + String.format("%.0f",goalFreq) + " Hz", 100,230);
  text("String 2", 100,350);
  text("f = " + String.format("%.0f",getStrFreq(string1.realLength, string1.realTension, string1.realWeight)) + " Hz", 100,380);
  
  //show current objective
//  text(objective[0], 200, 450);


  //draws rectangles for the musicstring
  for (MusicString ms : strings) {
    ms.drawRectangles(ms.strLength, ms.time);
  }

  
  //draw the play button
  stroke(0);  
  
   //putting these in a for loop should allow multiple strings to play at once
    for( MusicString ms : strings) {
    if(ms.getPlayingNote()==true){
        ms.time = ms.time + 1/60.;
     }  
   }
  for (MusicString ms : strings) {   
    if(drawIndex> ms.getStartIndex()+180){
        ms.playingNote = false;
          ms.time = defaultTime;
    }
  }
  
  
  
  currString.updateReals();
  
  //update frame counter
  drawIndex = drawIndex + 1;

}




//When trying to draw only when needed, don't use this
void update(int x, int y) {
  
  for (MusicString ms : strings){
    if (ms.overMusicString()){
      stringOver = true;
    } else {
      stringOver = false;
    }
   }
}

void mousePressed() {
  //Since the mouse can only be in one location at a time, end
  //could have achieved the same effect by putting everything in a large if-else 

  for ( MusicString ms : strings){
      if (ms.overMusicString()) {
          if(ms.playingNote == false){
             ms.startIndex = drawIndex;
            ms.playingNote = true;
            //freq is rounded to whole number when it is output
            output.playNote(0,3,round(getStrFreq(ms.realLength, ms.realTension, ms.realWeight)*100.)/100.);
              break;
          }
      }
    }

}

//Returns Frequency of String based on length, weight, and tension of string
float getStrFreq(float len, float ten, float wei){
  float f = sqrt(ten/(wei/1000))/(2*len/100);
  return f;
}

//generates a random string frequency within range of values for tension, weight, and length
float getRandomFreq(){
  float rTension = 70 + random(20);
  float rWeight = (0.5 + random(27)*0.25);
  float rLength = 10 + random(60);
  return getStrFreq(rLength, rTension,rWeight);
}

//TODO: make given string the only string that can be altered 
void makeCurrentString(MusicString newCurrent) {
  //if the given string is already the current string, leave this method
  if (newCurrent.getCurrent()) {
    return;
  }
  //get rid of "old current"
  for (MusicString ms : strings){
    if(ms.getCurrent()){
      ms.setCurrent(false);
    }
  }
  newCurrent.setCurrent(true);
}

//returns the string that can currently be altered, defaults to first string in strings
//TODO: does not compile, return can't live in conditional statement FIX
MusicString getCurrentString () {
  //TODO: can't remember the better way to do this
  MusicString out = strings.get(0);
  for (MusicString ms : strings) {
    if (ms.getCurrent()){
      out = ms;
    } 
  }
  return out;
}

//our strings that play sound
class MusicString {

  //string specific parameters
  float strLength;
  float strStart;
  float strTension;
  float strWeight;
  float maxLength;
  float minLength;
  float maxTension;
  float minTension;
  float maxWeight;
  float minWeight;
  
    //variables that, if we change them, we'd want them to change for all instances, probably
  float lengthFactor; //scale factor to multiply pixels by to get length in cm
  float weightFactor; //scale factor for string weight

  float realLength;
  float realWeight;
  float realTension;
  float currentFreq;
  

  float time;

  int startIndex;

  boolean playingNote;
  int n;

  
  int fillColor;      //the color of the string
  boolean current;    //whether or not this string can currently be altered
  int yposition;  //where on screen the string appears
  int tIndex = 0;

//constructor
MusicString (int ypos){  
   //string specific parameter
  strLength = 200;
  maxLength = 500; //max length of string in pixels
  strStart = (boxLength/2 - maxLength/2); // string is now centered correctly -LW 
  strTension = 70; //don't know what units we want this in
  strWeight = 1;
  minLength = 100;
  maxTension = 90;
  minTension = 70;
  maxWeight = 14;
  minWeight = 1.5;
  
    //variables that, if we change them, we'd want them to change for all instances, probably
  lengthFactor = 70/maxLength; //scale factor to multiply pixels by to get length in cm
  weightFactor = .5; //scale factor for string weight

  realLength = strLength*lengthFactor;
  realWeight = strWeight*weightFactor;
  realTension = strTension;
  currentFreq = getStrFreq(realLength, realTension, realWeight);
  

  time = defaultTime;

  startIndex = 0; //frame when the note starts playing

  playingNote = false;
  n = 1; //harmonic number

  
  current = false;    //whether or not this string can currently be altered
  yposition = ypos; //on screen y position of string  
  
}


/* FUNCTIONS WITH SUBSTANCE */


//checks if mouse location is on or near enough to MusicString
//TODO: make it easier to click the string
boolean overMusicString()  {
  if (mouseX >= strStart && mouseX <= strStart+strLength && mouseY >= yposition-strWeight - 20 && mouseY <= yposition+strWeight + 20){
    return true;
    } else {
    return false;
  }
}


//tells pixels/shapes in musicstring how to move
float getPixelMove(float x, float t){
  float w = 2*PI*drawingFreq;
  float k = 2*PI/(2*strLength/n); //wavelength for fundamental is 2*length, so k = pi/length
  float y = (15/t+.5)*cos(w*t)*sin(k*(x-strStart));
  if(playingNote==false){
    y=0;
  }
  return y;
}

//draw rectangles that make up the string
void drawRectangles(float strLength, float time){
  rectMode(CENTER);
  tIndex = int(10*(strTension-70));
  if (getCurrent()){
    stroke(tColors[0][tIndex],tColors[1][tIndex],tColors[2][tIndex]); //string that can be manipulated has a color determined by the tension
  }
  if (getCurrent() == false){
    stroke(150); //string that cannot be manipulated goes gray
  }
    
  for (float x=strStart;x<strLength+strStart;x=x+1){
    float y = yposition + getPixelMove(x,time);
    rect(x,y,1,strWeight);
  } 
}


void updateReals() {
  strTension = round(tSdr.getValueF()*10.)/10.;
realTension = strTension;

realWeight = round(wSdr.getValueF()*10.)/10.;
strWeight = realWeight/weightFactor;

realLength = round(lSdr.getValueF()*10.)/10.;
strLength = realLength/lengthFactor;

currentFreq = getStrFreq(realLength, realTension, realWeight);

fill(0);
textFont(fBig,16);
textAlign(CENTER, BOTTOM);
text("Tension = " + realTension + "N", sliderX + sliderLength/2, sliderY + 10);
text("Length = " + realLength + "cm",sliderX + sliderLength/2, sliderY + 90);
text("Weight = " + realWeight + "g/m",sliderX + sliderLength/2, sliderY + 170);
//text("Frequency = " + String.format("%.2f",currentFreq) + "Hz", sliderX + sliderLength/2, sliderY - 20);  
textFont(fBig,20);
text("Move the sliders to adjust the properties of String 2.", sliderX + sliderLength/2, sliderY-30);
}


//sets random values for the goal string
void setRandomValues() {
  realTension = 70 + random(20);
  realTension = strTension;
  realWeight = (0.5 + random(70)*0.1);
  strWeight = realWeight/weightFactor;
  realLength = 10 + random(60);
  strLength = realLength/lengthFactor;
}

//returns current attribute value as decimal for transform to int
float getCurrAttrVal(int attrNum) {
  float currAttrVal = 0.5;
  if (attrNum == 0){
    //length
    currAttrVal = (strLength - minLength) / (maxLength - minLength); //my math could be wrong
  } else if (attrNum == 1) {
    //tension
    currAttrVal = (strTension - minTension) / (maxTension - minTension); //my math could be wrong
  } else if (attrNum == 2) {
    //weight
    currAttrVal = (strWeight - minWeight) / (maxWeight - minWeight); //my math could be wrong
  }
  return currAttrVal;
}
  

/** GETTERS AND SETTERS */   
   
void setCurrent(boolean tf){
  current = tf;
}
   
void setStrLength(float newLength){
  strLength = newLength;
}
 
void setStrTension(float newTension){
  strTension = newTension;
}

void setStrWeight(float newWeight) {
  strWeight = newWeight;
}

void setRealLength(float newRealLength) {
  realLength = newRealLength;
}
 
void setRealWeight(float newRealWeight) {
  realWeight = newRealWeight;
}

void setRealTension(float newRealTension) {
  realTension = newRealTension;
}

boolean getPlayingNote(){
  return playingNote;
}

//true if this string can currently be altered, false if it cannot
boolean getCurrent(){
  return current;
}

int getStartIndex(){
  return startIndex;
}

float getStrLength(){
  return strLength;
}
 
float getStrWeight(){
  return strWeight;
}

float getStrTension(){
  return strTension;
}

float getMaxLength(){
  return maxLength;
}

float getMaxTension(){
  return maxTension;
}

float getMaxWeight(){
  return maxWeight;
}

float getMinLength(){
  return minLength;
}

float getMinTension(){
  return minTension;
}

float getMinWeight(){
  return minWeight;
}

float getLengthFactor(){
  return lengthFactor;
}

float getWeightFactor() {
  return weightFactor;
}
  
}
 


