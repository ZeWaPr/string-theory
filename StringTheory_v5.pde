import ddf.minim.*;
import java.awt.event.*;
import g4p_controls.*;

PVector center, sliderLeft, sliderRight;
//drawing size
int boxLength = 1200;
int boxHeight = 500;

//string parameters
float strLength = 150;
float strStart = 400;
float strY = boxHeight/2 + 75;
float strTension = 70; //don't know what units we want this in
float strWeight = 1;
float maxLength = 1000; //max length of string in pixels
float lengthFactor = 100/maxLength; //scale factor to multiply pixels by to get length in cm
float weightFactor = .5; //scale factor for string weight
float realLength = strLength*lengthFactor;
float realWeight = strWeight*weightFactor;
float realTension = strTension;
int tIndex = 0;

PFont fSmall;
PFont fBig;

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

//output and instruction statements
String[] prompt = {"Match the goal frequency by changing the string properties.", 
"Change the string such that the ratio of the string frequency to the goal frequency is 1:2",
"Change the string such that the ratio of the string frequency to the goal frequency is 2:3",
"Change the string such that the ratio of the string frequency to the goal frequency is 3:4"};

//prompt[0] = "Match the goal frequency by changing the string properties.";
//prompt[1] = "Change the string such that the ratio of the string frequency to the goal frequency is 1:2";
//prompt[2] = "Change the string such that the ratio of the string frequency to the goal frequency is 2:3";
//prompt[3] = "Change the string such that the ratio of the string frequency to the goal frequency is 3:4";

String[] congrats = {"You matched the frequency.",
"You've got it. This is called an octave.",
"You've got it. This is called a fifth.",
"You've got it. This is called a fourth."," "};

float[] goalFreqs = {440,720,900,600,1};

float[] ratios = {1,.5,.6667,.75,1};

int myIndex = 0;

float[][] tColors = new float[3][201]; //3 columns, for RGB, and 40 rows
float r = 0;
float g = 0;
float b = 0;

//audio outputs
Minim minim;
AudioOutput output;
Minim goalMinim;
AudioOutput goalOutput;

//sliders
GCustomSlider tSdr;
GCustomSlider lSdr;
GCustomSlider wSdr;


void setup(){

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
  
  fSmall = createFont("Arial",16,true);
  fBig = createFont("Arial",32,true);
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
  triX = 600; //coords of right point on triangle
  triY = 150;
  xShift = cos(PI/6)*triSide; //will make an equilateral triangle
  yShift = sin(PI/6)*triSide;
  
  
  tSdr = new GCustomSlider(this, 40, 220, 260, 50, null);
    //args are xpos, ypos, length, width
  // show          opaque  ticks value limits
  tSdr.setShowDecor(false, true, false, true);
  tSdr.setNbrTicks(5);
  tSdr.setLimits(70, 70, 90);
  tSdr.setNumberFormat(G4P.DECIMAL, 1);
  
  lSdr = new GCustomSlider(this, 40, 300, 260, 50, null);
    //args are xpos, ypos, length, width
  // show          opaque  ticks value limits
  lSdr.setShowDecor(false, true, false, true);
  lSdr.setNbrTicks(5);
  lSdr.setLimits(5, 5, 70);
  lSdr.setNumberFormat(G4P.DECIMAL, 1);
  
  wSdr = new GCustomSlider(this, 40, 380, 260, 50, null);
    //args are xpos, ypos, length, width
  // show          opaque  ticks value limits
  wSdr.setShowDecor(false, true, false, true);
  wSdr.setNbrTicks(5);
  wSdr.setLimits(0.5, 0.5, 7.5);
  wSdr.setNumberFormat(G4P.DECIMAL, 1);
}
void draw(){
  background(255);
  update(mouseX, mouseY);
  drawRectangles(strLength, time);
  currentFreq = getStrFreq(realLength, realTension, realWeight);
  
  stroke(0);
  fill(255);
  rect(600,70,1000,50);
  
  //rect(180,300,300,250);
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
textAlign(CENTER,BOTTOM); 
textFont(fSmall,16); 

text("Goal Frequency: " + String.format("%.2f",goalFreqs[myIndex]) + " Hz", 450,160);

if(currentFreq/goalFreqs[myIndex] >= ratios[myIndex]-.01 
  && currentFreq/goalFreqs[myIndex] <= ratios[myIndex]+.01 
  && playingNote == true && myIndex<3){
  myIndex = myIndex + 1;
}


fill(255,0,0);
textFont(fBig,18);
text(prompt[myIndex],600,80);

strTension = round(tSdr.getValueF()*10.)/10.;
realTension = strTension;

realWeight = round(wSdr.getValueF()*10.)/10.;
strWeight = realWeight/weightFactor;

realLength = round(lSdr.getValueF()*10.)/10.;
strLength = realLength/lengthFactor;

fill(0);
textFont(fBig,16);
text("Tension = " + realTension + "N",170,230);
text("Length = " + realLength + "cm",170,310);
text("Weight = " + realWeight + "g/m",170,390);
text("Frequency = " + String.format("%.2f",currentFreq) + "Hz", 170, 200);  

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
    goalOutput.playNote(0,3,goalFreqs[myIndex]);
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
  float f = sqrt(ten/(wei/1000))/(2*len/100);
  //replace 440 with actual math for freq based on length, weight, tension
  //return 440;
  return f;
}

//generates a random string frequency within range of values for tension, weight, and length
float getRandomFreq(){
  float rTension = 70 + random(22);
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
  //stroke(255,0,0);
  tIndex = int(10*(strTension-70));
  for (float x=strStart;x<strLength+strStart;x=x+1){
    //float y = (boxHeight/2);
    float y = (strY) + getPixelMove(x,time);
    stroke(tColors[0][tIndex],tColors[1][tIndex],tColors[2][tIndex]);
    //stroke(color(255,0,0));
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
  if (mouseX >= strStart && mouseX <= strStart+strLength && mouseY >= strY-40 && mouseY <= strY+40){
    return true;
    } else {
    return false;
  }
} 
