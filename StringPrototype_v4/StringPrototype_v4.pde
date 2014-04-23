import ddf.minim.*; //needed for sound right now, TODO: check out sound.js instead
import g4p_controls.*;

/**
* When refereing to attributes (length, weight, tension) by number, use following convention
* Tension = 1
* Length = 2
* Weight = 3
*/

//TODO: make so player can't change frequency of note while string is playing

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
PFont fWin;

MusicString currString; //musicstring to keep track of which can currently be altered

String[] objective = { "Make the frequency of String 2 match String 1 by only changing TENSION.\n Play both strings at the same time to advance." ,
            "Make the frequency of String 2 match String 1 by only changing LENGTH.\n Play both strings at the same time to advance.",
            "Make the frequency of String 2 match String 1 by only changing WEIGHT.\n Play both strings at the same time to advance.", 
            "Make the frequency of String 2 match String 1 by only changing ANY of the variables.\n Play both strings at the same time to finish.",
            "When the FREQUENCY of two strings is in a ratio of 2:1 they make an octave.\nChange String 2 so that plays an octave with String 1." };

String[] endMess = {"Congratulations!!!", "Congratulations!!!", "Congratulations!!!", "Congratulations!!!", "Didn't that sound nice?\nYEAH IT DID!"};

  //2d array for tension color scale
  float[][] tColors = new float[3][201]; //3 columns, for RGB, and 40 rows
  float r = 0;
  float g = 0;
  float b = 0;


int currLevel = 0;
Level[] levels = new Level[5];  //TODO: number of levels should NOT be hardcoded like this
int winTime = 0;

PImage img, upArrow, downArrow;

//things for play button
GImageButton playBtn;

/*

SETUP

*/

void setup() {
  //setup screen

  img = loadImage("Guitar2.png");
  upArrow = loadImage("upArrow.png");
  downArrow = loadImage("downArrow.png");
  size(boxLength, boxHeight);
  background (255);
  
  //initialize slider(s) and musicstring(s)
  string = new MusicString(270);  
  string1 = new MusicString(300); 
  
  
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
  tSdr.setShowDecor(false, true, false, true); //TODO: Can we show which sliders are active or not with this?
  tSdr.setNbrTicks(5);
  tSdr.setLimits(70, 70, 90);
  tSdr.setNumberFormat(G4P.DECIMAL, 1);
  
  lSdr = new GCustomSlider(this, sliderX, sliderY + 80, sliderLength, sliderHeight, null);
    //args are xpos, ypos, length, width
  // show          opaque  ticks value limits
  lSdr.setShowDecor(false, true, false, true);
  lSdr.setNbrTicks(5);
  lSdr.setLimits(5, 25, 70);
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
  fWin = createFont("Arial", 50, true);
  
  
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
 
 
 //TODO: find a better way to initialize levels than this 
 Level level1, level2, level3, level4, level5;
 level1 = new Level(0, 1., objective[0], endMess[0], string, string1,0);
 level2 = new Level(1, 1., objective[1], endMess[1], string, string1,0);
 level3 = new Level(2, 1., objective[2], endMess[2], string, string1,0);
 level4 = new Level(3, 1., objective[3], endMess[3], string, string1,0);
 level5 = new Level(4, 2., objective[4], endMess[4], string, string1, 440);
  
  levels[0] = level1;
  levels[1] = level2;
  levels[2] = level3;
  levels[3] = level4;
  levels[4] = level5;

  currString.makeRatioPossible(string.getRealTension(),string.getRealLength(), string.getRealWeight(),levels[currLevel].whichSliders());

  //for play button
  cursor(CROSS);
  String[] files;

  files = new String[] { 
    "darkTriangle.png", "lightTriangle.png", "lightTriangle.png"
  };

  playBtn = new GImageButton(this, 160, 50, 40, 40, files);


}

/*

DRAW

*/
void draw() {

    if (winTime != 0) {
      
        tSdr.setVisible(false);
        lSdr.setVisible(false);
        wSdr.setVisible(false);
        playBtn.setVisible(false);
    
    
        //NOTE: Math.random didn't work, to move from processing figure out why
       fill(random(0,255), random(0,255), random(0,255));
        showEndMess(levels[currLevel - 1].getEndMessage());  
    
      //so strings aren't still moving after win screen
      for (MusicString ms : strings) { 
          ms.playingNote = false; 
      }

      if (millis() - winTime > 4000){
          //this resets the goal frequency after a level is won
         if (levels[currLevel].goalFrequency == 0 ){
            string.setRandomValues();
            goalFreq = getStrFreq(string.realLength, string.realTension, string.realWeight);
        
          } else { 
            string.setSpecificValues(levels[currLevel].goalFrequency);
            goalFreq = getStrFreq(string.realLength, string.realTension, string.realWeight);
          }
          //this adjusts the current string so that the level is winnable, needs to be edited
          currString.makeRatioPossible(string.getRealTension(),string.getRealLength(), string.getRealWeight(),levels[currLevel].whichSliders());
          winTime = 0;
       }
        fill(0);
        
    } else {
      
      stringScreenDraw();
      
    }  

}

void stringScreenDraw(){
  background(255);
  tint(255,220);
  image(img, 12, 100, .95*width, 3*height/5);
  
  playBtn.setVisible(true);
   
  textAlign(CENTER, BOTTOM);
 //write instructions at the top of the screen
  textFont(fBig,24);
   text(levels[currLevel].getInstructions(), boxLength/2,80);

 //write current frequencies of the stings
  textFont(fBig,16);
  //NOTE: making these one line
  text("String 1\nf = " + String.format("%.0f",string.getFreq()) + " Hz", 100, string.getYPosition() - 10);
  //text("f = " + String.format("%.0f",string.getFreq()) + " Hz", 100,230);
  text("String 2\nf = " + String.format("%.0f",string1.getFreq()) + " Hz", 100,string1.getYPosition() + 10);
  //text("f = " + String.format("%.0f",string1.getFreq()) + " Hz", 100,380);
 

  //draws rectangles for the musicstring
  for (MusicString ms : strings) {
    ms.drawRectangles(ms.strLength, ms.time);
    fill(255);
    ellipse(ms.strStart,ms.yposition,15,15);
    //fill(255);
    if(ms.current==true){
      image(upArrow,ms.strStart+ms.strLength-15,ms.yposition,30,40);
    }
    if(ms.current==false){
      //rotate(PI);
      //translate(-15, -15);
      image(downArrow,ms.strStart+ms.strLength-15,ms.yposition-40,30,40);

      //rotate(0);
    }
  }

  fill(0);
  
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
  
  
  currString.updateReals(levels[currLevel].whichSliders());
  
  //subtracting 1 from levels.length stops the code from breaking, and I can still get to all 3 levels
  if (levels[currLevel].hasWon() && levels[currLevel].getLevelNum() < levels.length - 1) {
      winTime = millis();
      currLevel++; 
    }
  
  //update frame counter
  drawIndex = drawIndex + 1;
}

void mousePressed() {

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

//handles play button
void handleButtonEvents(GImageButton button, GEvent event) {
  if (button == playBtn){
    if(string.playingNote == false){
      string.startIndex = drawIndex;
      string.playingNote = true;
      //freq is rounded to whole number when it is output
      output.playNote(0,3,round(getStrFreq(string.realLength, string.realTension, string.realWeight)*100.)/100.);
    }
    if(string1.playingNote == false){
      string1.startIndex = drawIndex;
      string1.playingNote = true;
      //freq is rounded to whole number when it is output
      output.playNote(0,3,round(getStrFreq(string1.realLength, string1.realTension, string1.realWeight)*100.)/100.);
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
  float rWeight = (0.5 + random(70)*0.1);
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

  public void showEndMess(String endMessage){
      background(0);
      textFont(fWin);
      text(endMessage, boxLength/2, boxHeight / 2);
    
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
  float maxRealLength;
  float minRealLength;
  float maxRealTension;
  float minRealTension;
  float maxRealWeight;
  float minRealWeight;
  
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
  minLength = 500/3;
  maxTension = 90;
  minTension = 70;
  maxWeight = 14;
  minWeight = 1.5;
  
  minRealLength = 25;
  maxRealLength = 70;
  minRealTension = 70;
  maxRealTension = 90;
  minRealWeight = 0.5;
  maxRealWeight = 7.5;
  
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
    stroke(tColors[0][tIndex],tColors[1][tIndex],tColors[2][tIndex]); //string that can be manipulated has a color determined by the tension
    //stroke(150); //string that cannot be manipulated goes gray
  }
    
  for (float x=strStart;x<strLength+strStart;x=x+1){
    float y = yposition + getPixelMove(x,time);
    rect(x,y,1,strWeight);
  } 
  stroke(0);
  for (float k=strLength+strStart;k<maxLength+strStart;k=k+1){
    rect(k,yposition,1,strWeight);
  }
}

//this sets the current string to have attributes that make the level winnable, ie the variable they are adjusting will fall within the settable range
void makeRatioPossible(float goalRealTension, float goalRealLength, float goalRealWeight, int attribute) {
      float tempTension = 1.;
      float tempLength = 1.;
      float tempWeight = 1.;
      float targetFreq = goalFreq/(levels[currLevel].ratio); //this is the frequency you want the current string set to, this should work for the harmony levels as well
      boolean matchPossible = false;
      
  switch(attribute) {
    case 1:
      //tension constant
      //cycle through random pairs of length and weight until the correct tension falls in the settable range
      while(matchPossible==false) {
        tempLength = minRealLength + random(maxRealLength-minRealLength);
        tempWeight = minRealWeight + random(70)*0.1;
        tempTension = (tempWeight/1000)*pow((2*(tempLength/100)*targetFreq),2);
        if ((tempTension>=minRealTension) && (tempTension<=maxRealTension)) {
          matchPossible = true;
        }
      }
      //added round statements so that these will display correctly on the slider panel (without so many decimal places
      realLength = round(tempLength*10.)/10.;
      strLength = realLength / lengthFactor;
      realWeight = round(tempWeight*10.)/10.;
      strWeight = realWeight / weightFactor;
      break;
    case 2:
      //length constant
      //cycle through random pairs of tension and weight until the correct length falls in the settable range
      while(matchPossible==false) {
        tempTension = minRealTension + random(20);
        tempWeight = minRealWeight + random(70)*0.1;
        tempLength = 100*(1/(2*targetFreq))*pow((tempTension/(tempWeight/1000)),0.5);
        if ((tempLength>=minRealLength) && (tempLength<=maxRealLength)) {
          matchPossible = true;
        }
      }
      realTension = round(tempTension*10.)/10.;
      strTension = realTension;
      realWeight = round(tempWeight*10.)/10.;
      strWeight = realWeight / weightFactor;
      break;         
    case 3:
      //weight constant
      //cycle through random pairs of tension and length until the correct weight falls in the settable range
      while(matchPossible==false) {
        tempTension = minRealTension + random(20);
        tempLength = minRealLength + random(60);
        tempWeight = 1000*tempTension*pow((1/(2*tempLength*targetFreq/100)),2);
        if ((tempWeight>=minRealWeight) && (tempWeight<=maxRealWeight)) {
          matchPossible = true;
        }
      }
      realTension = round(tempTension*10.)/10.;
      strTension = realTension;
      realLength = round(tempLength*10.)/10.;
      strLength = realLength / lengthFactor;
      break;    
    case 4:
      break;
  }
}

//TODO: change this swtich so don't need to add case every time you add a level past the tutorial
void updateReals(int attribute) {
  if(!playingNote){  //added this check so user can't change freq of note while it's playing
    switch (attribute) {
    case 1:
      realTension = round(tSdr.getValueF() * 10.) / 10.;
      strTension = realTension;
      break;
    case 2:
      realLength = round(lSdr.getValueF() * 10.) / 10.;
      strLength = realLength / lengthFactor;
      break;
    case 3:
      realWeight = round(wSdr.getValueF() * 100.) / 100.;
      //realWeight = wSdr.getValueF();
      strWeight = realWeight / weightFactor;
      break;
    case 4:
      strTension = round(tSdr.getValueF() * 10.) / 10.;
      realTension = strTension;

      realWeight = round(wSdr.getValueF() * 100.) / 100.;
      //realWeight = wSdr.getValueF();
      strWeight = realWeight / weightFactor;

      realLength = round(lSdr.getValueF() * 10.) / 10.;
      strLength = realLength / lengthFactor;
      break;
    case 5: 
      strTension = round(tSdr.getValueF() * 10.) / 10.;
      realTension = strTension;

      //realWeight = round(wSdr.getValueF() * 10.) / 10.;
      realWeight = round(wSdr.getValueF() * 100.) / 100.;
      strWeight = realWeight / weightFactor;

      realLength = round(lSdr.getValueF() * 10.) / 10.;
      strLength = realLength / lengthFactor;
      break;
    
      }
    }

    currentFreq = getStrFreq(realLength, realTension, realWeight);

  
    textFont(fBig, 20);//NOTE: why is this here?
  }



//sets random values for the goal string
void setRandomValues() {
  realTension = 70 + random(20);
  realTension = round(realTension*10.)/10.;
  strTension = realTension;
  realWeight = (0.5 + random(70)*0.1);
  realWeight = round(realWeight*10.)/10.;
  strWeight = realWeight/weightFactor;
  realLength = minRealLength + random(maxRealLength-minRealLength);
  realLength = round(realLength*10.)/10.;
  strLength = realLength/lengthFactor;
  currentFreq = getStrFreq(realLength,realTension,realWeight);
}

//initialize tension, length and width so that you achieve desired value
void setSpecificValues(float myFreq) {
  boolean possible = false;
  boolean possibleL = false;
  boolean possibleW = false;
  float maxFreq = 0.;
  float minFreq = 0.;
  float tempTension = 0.;
  while(possible == false){    
    realLength = minRealLength + random(maxRealLength-minRealLength);
    maxFreq = (100/(2*realLength))*sqrt(1000*maxRealTension/minRealWeight);
    minFreq = (100/(2*realLength))*sqrt(1000*minRealTension/maxRealWeight);
    if(myFreq>= minFreq && myFreq<= maxFreq){
      while( possibleW == false){
        realWeight = (0.5 + random(70)*0.1);
        tempTension = pow((2*realLength*myFreq/100),2)*(realWeight/1000);
        if(tempTension>=minRealTension && tempTension<=maxRealTension){
          realTension = tempTension;
          possibleW = true;
          possible = true;
        }
      }
    }
  }
  strTension = realTension;
  strWeight = realWeight/weightFactor;
  strLength = realLength/lengthFactor;
  currentFreq = getStrFreq(realLength,realTension,realWeight);
}

//NOTE: don't know if we're still using this 
//returns current attribute value as decimal for transform to int
float getCurrAttrVal(int attrNum) {
  float currAttrVal = 0.5;
  if (attrNum == 2){
    //length
    currAttrVal = (strLength - minLength) / (maxLength - minLength); 
  } else if (attrNum == 1) {
    //tension
    currAttrVal = (strTension - minTension) / (maxTension - minTension); 
  } else if (attrNum == 3) {
    //weight
    currAttrVal = (strWeight - minWeight) / (maxWeight - minWeight); 
  }
  return currAttrVal;
}
  

/** GETTERS AND SETTERS */   


void setStrFreq(float freq){
  currentFreq = freq;
}
   
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

int getYPosition(){
  return yposition;
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

float getRealLength(){
  return realLength;
}
 
float getRealWeight(){
  return realWeight;
}

float getRealTension(){
  return realTension;
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

public float getFreq() {
  return currentFreq;
}
  
}
 /**
 * 
 * Resets on screen strings, sliders, everything for each tutorial or harmony
 * level
 * 
 * @author ZeWaPr
 * 
 */
public class Level {

  int levelNumber; // TODO: make this autogenerated
  float ratio; // for initial levels ratio = 1
  String instructions, congratulations;
  MusicString goal, controlled;
  float goalFrequency;

  Level(int levelNum, float ratioCondition, String instruct,
      String endMessage, MusicString goalString, MusicString currentString, float goalFreq) {

    levelNumber = levelNum;
    ratio = ratioCondition;
    instructions = instruct;
    congratulations = endMessage;
    goal = goalString;
    controlled = currentString;
    goalFrequency = goalFreq;

  }

  /**
   * Tells if win condition has been met. Both notes must be playing and
   * matched based on ratio.
   * 
   * @return
   */
  public boolean hasWon() {
    
    boolean hasWon = false;
    if (goal.getPlayingNote() && controlled.getPlayingNote()) {
      if (goal.getFreq() / controlled.getFreq() <= ratio + .005 
      && goal.getFreq() / controlled.getFreq() >= ratio - .005) { //TODO: math.round might round too much to match to float ratio
        // YOU WON!
        hasWon = true;
      }
    }
    return hasWon;
  }
  
  /**
   * Decides which sliders are visible. 1 means just tension, 2 means just
   * length, 3 means just weight, 4 means all sliders
   * TODO: change this swtich so don't need to add 
   *       case every time you add a level past the tutorial
   * @return the number of the slider that you can use.
   */
  public int whichSliders() {
    textFont(fBig, 16);
    textAlign(CENTER, BOTTOM);
    switch(levelNumber + 1){
      case 1:
  //      if(winTime !=0){  //trying this to get sliders invisible on win screen
        //Only show tension
        tSdr.setVisible(true);
        lSdr.setVisible(false);
        wSdr.setVisible(false);
//        }
          fill(0);
  
        text("Tension = " + controlled.realTension + "N", sliderX + sliderLength / 2,
            sliderY + 10);
        // because I'd rather be redundant that miss something
        break;
      case 2: 
        if(winTime !=0){
        //only show length
        tSdr.setVisible(false);
        lSdr.setVisible(true);
        wSdr.setVisible(false);
        }
          fill(0);
        text("Length = " + controlled.realLength + "cm", sliderX + sliderLength / 2,
            sliderY + 90);
         // because I'd rather be redundant than miss something
        break;
      case 3:
      if(winTime !=0){
        //only show weight
        tSdr.setVisible(false);
        lSdr.setVisible(false);
        wSdr.setVisible(true);
        }
          fill(0);
        text("Weight = " + controlled.realWeight + "g/m", sliderX + sliderLength / 2,
            sliderY + 170);
        // because I'd rather be redundant than miss something
        break;
      case 4:
        if(winTime !=0){
        //show all 3 sliders
        tSdr.setVisible(true);
        lSdr.setVisible(true);
        wSdr.setVisible(true);
        }
        text("Tension = " + controlled.realTension + "N", sliderX + sliderLength / 2,
            sliderY + 10);
        text("Length = " + controlled.realLength + "cm", sliderX + sliderLength / 2,
              sliderY + 90);
          text("Weight = " + controlled.realWeight + "g/m", sliderX + sliderLength / 2,
              sliderY + 170);
        // because I'd rather be redundant than miss something
        break;
      case 5: 
        if(winTime !=0){
        //show all 3 sliders
        tSdr.setVisible(true);
        lSdr.setVisible(true);
        wSdr.setVisible(true);
        }
          text("Tension = " + controlled.realTension + "N", sliderX + sliderLength / 2,
            sliderY + 10);
        text("Length = " + controlled.realLength + "cm", sliderX + sliderLength / 2,
              sliderY + 90);
          text("Weight = " + controlled.realWeight + "g/m", sliderX + sliderLength / 2,
              sliderY + 170);
        break;
    
    }
    return levelNumber + 1;
  }
  
  public int getLevelNum(){
    return levelNumber;
  }
  
  public String getInstructions(){
    return instructions;
  }
  
  public String getEndMessage(){
    return congratulations;
  }
  
}
