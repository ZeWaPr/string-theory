import ddf.minim.*;
import java.awt.event.*;

PVector center, sliderLeft, sliderRight;
//drawing size
int boxLength = 600;
int boxHeight = 500;

//string parameters
float strLength = 200;
float strStart = (boxLength/2 - strLength/2);
float strTension = 70; //don't know what units we want this in
float strWeight = 1;
float maxLength = 500; //max length of string in pixels
float lengthFactor = 65/maxLength; //scale factor to multiply pixels by to get length in cm
float weightFactor = .5/1000; //scale factor for string weight
float realLength = strLength*lengthFactor;
float realWeight = strWeight*weightFactor;
float realTension = strTension;

float currentFreq = getStrFreq(realLength, realTension, realWeight);
float goalFreq = getRandomFreq();
float drawingFreq = 3; //frequency of animation
float defaultTime = 1/(2*PI*drawingFreq);
float time = defaultTime;

int drawIndex = 0; //current frame
int startIndex = 0; //frame when the note starts playing

boolean playingNote = false;
int n = 1; //harmonic number

//play button for matching frequency
int triX, triY, triSide;
color triColor, triHighlight;
float xShift,yShift;
boolean triOver = false;
boolean stringOver = false;

//audio outputs
Minim minim;
AudioOutput output;
Minim goalMinim;
AudioOutput goalOutput;

void setup(){
  size(boxLength,boxHeight);
  rectMode(CENTER);
  fill(0);
  center = new PVector(width/2, height/2);
  sliderLeft  = new PVector(200, height - 200);
  sliderRight = new PVector(sliderLeft.x + 200, sliderLeft.y);

  //initialize sound outputs
  minim = new Minim(this);
  output = minim.getLineOut();
  goalMinim = new Minim(this);
  goalOutput = goalMinim.getLineOut();
  
  //setup triangle playbutton
  triColor = color(0,255,0);
  triHighlight = color(0,150,0);
  triSide = 40;
  triX = 325; //coords of right point on triangle
  triY = 100;
  xShift = cos(PI/6)*triSide; //will make an equilateral triangle
  yShift = sin(PI/6)*triSide;
}

void draw(){
  background(255);

  update(mouseX, mouseY);
  drawRectangles(strLength, time);
  if (triOver) {
    fill(triHighlight);
  } else {
    fill(triColor);
  }
  stroke(0);
  triangle(triX,triY,triX-xShift,triY+yShift,triX-xShift,triY-yShift);
  
  //you need a string
 //rect(center.x, center.y, strLength, strWeight); 
  
  
  fill(0);
  //you need to show info on the string's attributes 
text("Current Length: " + String.format("%.2f",realLength) + " cm", 10, 20);
text("Current Tension: " + strTension + "N", 10, 40);
text("Current Weight: " + String.format("%.2f",realWeight*1000) + " g/m", 10, 60);
currentFreq = getStrFreq(realLength, realTension, realWeight);
text("Current Frequency: " + String.format("%.2f",currentFreq) + " Hz",380,20);
text("Goal Frequency: " + String.format("%.2f",goalFreq) + " Hz", 300,50);
if (keyPressed == true && key == CODED){
    //make string longer
  if(keyCode == RIGHT && strLength <= 500){
    strLength = strLength + 250./65.;
    realLength = (strLength)*lengthFactor;
    strStart = (boxLength/2 - strLength/2);
  }

  //shorten string
  if(keyCode == LEFT && strLength >= 100){
    strLength = strLength - 250./65.;
    realLength = strLength*lengthFactor;
    strStart = (boxLength/2 - strLength/2);
  }

 //increase tension
  if (keyCode == CONTROL && strTension <=90) {
    strTension = strTension + .5;
    realTension = strTension;
  }
 
  //decrease tension
  if(keyCode == ALT && strTension >=70 ) {
    strTension = strTension - .5;
    realTension = strTension;
  }  
  
  //increase weight
  //want weight to range from .0005 to .007 in kg/m
  if (keyCode == UP && strWeight <= 14) {
    strWeight = strWeight + 0.25;
    realWeight = strWeight*weightFactor;
  }

  //decrease weight
  if (keyCode == DOWN && strWeight >= 1.5) {
    strWeight = strWeight - 0.25; 
    realWeight = strWeight*weightFactor;
  }
  
  //you need a play sound button
  //commented this out as it is now handled by clicking the string
  //if(keyCode == SHIFT) {
  //  if(playingNote == false){
  //    startIndex = drawIndex;
  //    playingNote = true;
  //    output.playNote(0,3,getStrFreq(realLength, realTension, realWeight));
  //    }
  //  }

    //minim method: takes frequency as int, plays note
    
}
  if(playingNote==true){
    time = time + 1/60.;
  }  
   
   if(drawIndex>startIndex+180){
        playingNote = false;
        time = defaultTime;
   }
  drawIndex = drawIndex + 1;
  redraw();

}


void update(int x, int y) {
  if ( overTri(triX, triY, triSide) ) {
    triOver = true;
  } else {
    triOver = false;
  }
  if (overString(strLength)){
    stringOver = true;
  } else {
    stringOver = false;
  }
}

void mousePressed() {
  if (triOver) {
    goalOutput.playNote(0,3,goalFreq);
  }
  if (stringOver) {
      if(playingNote == false){
        startIndex = drawIndex;
        playingNote = true;
        output.playNote(0,3,getStrFreq(realLength, realTension, realWeight));
      }
  }
}

//Returns Frequency of String based on length, weight, and tension of string
float getStrFreq(float len, float ten, float wei){
  float f = sqrt(ten/wei)/(2*len/100);
  //replace 440 with actual math for freq based on length, weight, tension
  //return 440;
  return f;
}

//generates a random string frequency within range of values for tension, weight, and length
float getRandomFreq(){
  float rTension = 69 + random(22);
  float rWeight = (0.5 + random(27)*0.25)/1000.;
  float rLength = 12 + random(53);
  return getStrFreq(rLength, rTension,rWeight);
}

float getPixelMove(float x, float t){
  float w = 2*PI*drawingFreq;
  float k = 2*PI/(2*strLength/n); //wavelength for fundamental is 2*length, so k = pi/length
  float y = (15/t+.5)*cos(w*t)*sin(k*(x-strStart));
  if(playingNote==false){
    y=0;
  }
  return y;
}

void drawRectangles(float strLength, float time){
  background(255);
  for (float x=strStart;x<strLength+strStart;x=x+1){
    fill(0);
    //float y = (boxHeight/2);
    float y = (boxHeight/2) + getPixelMove(x,time);
    rect(x,y,1,strWeight);
  } 
}

boolean overTri(int x, int y, float xShift)  {
  if (mouseX >= x-xShift && mouseX <= x){
    float newYShift = (triX-mouseX)/2;
    float yMax = y + newYShift;
    float yMin = y - newYShift;
    if (mouseY >= yMin && mouseY <= yMax){
      return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
} 

boolean overString(float strLength)  {
  if (mouseX >= strStart && mouseX <= strStart+strLength && mouseY >= boxHeight/2-strWeight && mouseY <= boxHeight/2+strWeight){
    return true;
    } else {
    return false;
  }
} 

  
