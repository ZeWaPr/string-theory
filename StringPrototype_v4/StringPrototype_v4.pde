import ddf.minim.*; //needed for sound right now, TODO: check out sound.js instead

/**
This is a attempt to combine the string and slider classes. 
This is somewhere in between almost clean and absolute mess. Sorry.
**/

//objects we'll need
Slider slider, slider1;
MusicString string;
ArrayList<MusicString> strings; //arraylist so user can add and remove strings whenever
ArrayList<Slider> sliders; //have as many sliders as you want 

//size of animation screen
int boxLength = 900;
int boxHeight = 800;

//play button for matching frequency
int triX, triY, triSide;
color triColor, triHighlight;
float xShift,yShift;
boolean triOver = false;
boolean stringOver = false;

//audio outputs
Minim minim, goalMinim;
AudioOutput output, goalOutput;

//current frame
int drawIndex = 0; 

//frequency of animation
float drawingFreq = 3; 

float defaultTime = 1/(2*PI*drawingFreq);

//freq to match
float goalFreq = getRandomFreq();

//musicstring to keep track of which can currently be altered
MusicString currString; 

void setup() {
	//setup screen
  size(boxLength, boxHeight);
  background (255);
  
	//initialize slider(s) and musicstring(s)
  string = new MusicString(100, 0); //TODO: 100 doesn't set y position of musicString
  slider = new Slider("Length", new PVector(40, 500), string, 0);
  slider1 = new Slider("Weight", new PVector(100, 500), string, 2);
  
  
  //initialize the list of strings
  strings = new ArrayList<MusicString>();
  strings.add(string);
  
    //set the current string
  string.setCurrent(true);
  for (MusicString ms : strings) {
  if(ms.getCurrent()) {
    currString = ms;
  }
  }
  
  //initialize the list of sliders
  sliders = new ArrayList<Slider>();
  sliders.add(slider);
  sliders.add(slider1);
  
  //initialize sound outputs
  minim = new Minim(this);
  output = minim.getLineOut();
  goalMinim = new Minim(this);
  goalOutput = goalMinim.getLineOut();
  
    //initialize triangle playbutton
  triColor = color(0,255,0);
  triHighlight = color(0,150,0);
  triSide = 40;
  triX = 325; //coords of right point on triangle
  triY = 100;
  xShift = cos(PI/6)*triSide; //will make an equilateral triangle
  yShift = sin(PI/6)*triSide;
  
}

void draw() {

  //background color, called to wipe screen each frame
	background(255);

  //color of string and sliders
	fill(0);
  
  //TODO: figure out if/how we want sliders
 	 for (Slider s : sliders) {
  		s.show();
	  }

  
 //show current value of...
//... the slider(s) as percentage, rounded from 2 sig figs, shows up near slider
  for( Slider s : sliders ){
  	text(s.name + ": " + s.getPercent() + "%", s.location.x, s.location.y + s.tall + 20);
  }
  //...the goal frequency
	text("Goal Frequency: " + String.format("%.2f",goalFreq) + " Hz", 380,50);
  //...the string's attributes, if there are strings
  	if(strings.size() > 0) { 
  		for( MusicString ms : strings ){
  		//TODO: when multiple strings, change coordinates so no overlap
			text("Current Length: " + String.format("%.2f",ms.realLength) + " cm", 10, 20);
			text("Current Tension: " + ms.strTension + "N", 10, 40);
			text("Current Weight: " + String.format("%.2f",ms.realWeight*1000) + " g/m", 10, 60);
			text("Current Frequency: " + String.format("%.2f",ms.currentFreq) + " Hz",380,20);
			//draws rectangles for the musicstring
			ms.drawRectangles(ms.strLength, ms.time);
		}
	  }


  //have play button change color on mouseover
	if (overTri(triX, triY, triSide)) {
    	fill(triHighlight);
	} else {
    	fill(triColor);
	}
	
  //draw the play button
	stroke(0);
	triangle(triX,triY,triX-xShift,triY+yShift,triX-xShift,triY-yShift);
  
  
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
  
  
  //update frame counter
	drawIndex = drawIndex + 1;

}



//checks if mouse location is over Play button
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


//When trying to draw only when needed, don't use this
void update(int x, int y) {
  if ( overTri(triX, triY, triSide) ) {
    triOver = true;
  } else {
    triOver = false;
  }
  
  for (MusicString ms : strings){
	  if (ms.overMusicString()){
    	stringOver = true;
	  } else {
    	stringOver = false;
	  }
   }
}

void keyPressed() {
  if (keyPressed == true && key == CODED){
    //make string longer
  if(keyCode == RIGHT && currString.getStrLength() <= currString.getMaxLength()){
    currString.setStrLength(  currString.getStrLength() + 250./65. );    
    currString.setRealLength( currString.getStrLength() * currString.getLengthFactor() );
    currString.strStart = (boxLength/2 - currString.getStrLength()/2);
  }

  //shorten string
  if(keyCode == LEFT && currString.getStrLength() >= currString.getMinLength()){
    currString.setStrLength(  currString.getStrLength() - 250./65. );    
    currString.setRealLength( currString.getStrLength() * currString.getLengthFactor() );
    currString.strStart = (boxLength/2 - currString.getStrLength()/2);
  }

 //increase tension
  if (keyCode == CONTROL && currString.getStrTension() <= currString.getMaxTension()) {
    currString.setStrTension( currString.getStrTension() + .5 );
    currString.setRealTension( currString.getStrTension() );
  }
 
  //decrease tension
  if(keyCode == ALT && currString.getStrTension() >= currString.getMinTension() ) {
    currString.setStrTension( currString.getStrTension() - .5 );
    currString.setRealTension( currString.getStrTension() );
  }  
  
  //increase weight
  //want weight to range from .0005 to .007 in kg/m
  if (keyCode == UP && currString.getStrWeight() <= currString.getMaxWeight()) {
    currString.setStrWeight( currString.getStrWeight() + 0.25 );
    currString.setRealWeight( currString.getStrWeight() * currString.getWeightFactor() );
  }

  //decrease weight
  if (keyCode == DOWN && currString.getStrWeight() >= currString.getMinWeight()) {
    currString.setStrWeight( currString.getStrWeight() - 0.25 );
    currString.setRealWeight( currString.getStrWeight() * currString.getWeightFactor() );
  }    

  
  if(keyCode == SHIFT) {
  for (MusicString ms : strings ){
    if(ms.playingNote == false){
       ms.startIndex = drawIndex;
       ms.playingNote = true;
       output.playNote(0,3,getStrFreq(ms.realLength, ms.realTension, ms.realWeight));
      }
  }
  }
}
}

//update used in this when always drawing
void mousePressed() {
	//Since the mouse can only be in one location at a time, end
	//could have achieved the same effect by putting everything in a large if-else 
  if (overTri(triX, triY, triSide)) {
    goalOutput.playNote(0,3,goalFreq);
    return;	
  }

	for ( MusicString ms : strings){
  		if (ms.overMusicString()) {
   		   if(ms.playingNote == false){
       			ms.startIndex = drawIndex;
        		ms.playingNote = true;
    		    output.playNote(0,3,getStrFreq(ms.realLength, ms.realTension, ms.realWeight));
          		break;
      		}
  		}
 	 }
  for (Slider s : sliders) {
  	if(s.overSlider()) {
  		s.update();
  		s.getMusicString().updateReals();
	  	break;

  	}
  }

}

//Returns Frequency of String based on length, weight, and tension of string
float getStrFreq(float len, float ten, float wei){
  float f = sqrt(ten/wei)/(2*len/100);
  return f;
}

//generates a random string frequency within range of values for tension, weight, and length
float getRandomFreq(){
  float rTension = 69 + random(22);
  float rWeight = (0.5 + random(27)*0.25)/1000.;
  float rLength = 12 + random(53);
  return getStrFreq(rLength, rTension,rWeight);
}

void makeCurrentString(MusicString newCurrent) {
	for (MusicString ms : strings){
		
	}
}

//vertical sliders
class Slider {
  //parameters
 String name;
 //vector that hold x and y coordinates of upper left corner of slider
 PVector location;
 
 //whether or not this slider has been clicked
 boolean pressed;
 
 //height of slider in pixels
 int tall;
 //width of slider in pixels
 int wide;
 
 //Music String the slider can alter
 MusicString string;
 //attribute of the Music that this slider can alter:
 // 0 -> length, 1 ->  tension, 2 -> weight
 int attribute; 

 //percent distance from min to max
 float currentValue;
 //visual representation of current value of slider
 PVector markerLocation;

  
  
  //constructor
  Slider( String n, PVector loc, MusicString ms, int attr) {
    name = n;
    location  = loc;
    string = ms;
  
    //TOTALLY wrong way to check for valid input but this is pre-alpha
    //SHOULD be throwing exceptions, pushed to 2.0
    if (attr == 0 || attr == 1 || attr == 2) {
	    attribute = attr;
    } else {
    	attribute = 0;
   	}
  
    currentValue = ms.getCurrAttrVal(attribute); //the current value of the attr of the musicstring
    pressed = false;
  
    //slider dimensions
    tall = 120;
    wide = 20;
  
    markerLocation = new PVector(location.x, location.y + ( tall * currentValue ));

  }
  
  //draw the slider on screen, not called draw b/c too many draw methods already
  void show() { 
     rectMode(CORNER);
    //draw body of slider, wipes out old marker
    fill(50);
    rect(location.x, location.y, wide, tall);
    //draw marker for current value of slider
    stroke(200);
    line(markerLocation.x, markerLocation.y, markerLocation.x + wide, markerLocation.y);
  }
  
    
  //updates the slider and it's associated string, TODO: Only adjusts length right now
  void update() {
      
      //move marker on screen
      markerLocation.y = mouseY;
      
      //adjust current value to reflect marker location
      currentValue = 1 - ((markerLocation.y - location.y) / tall);
      
      //change associated musicstring's correct attribute to match new current value
      if (attribute == 0) {
      	//length
      	//TODO: check if this formula works
      	string.setStrLength( (string.getMaxLength() - string.getMinLength()) * currentValue + string.getMinLength() );
      } else if( attribute == 1) {
	      //tension
		string.setStrTension( (string.getMaxTension() - string.getMinTension()) * currentValue + string.getMinTension() );
      } else if (attribute == 2) {
	      	//weight
		string.setStrWeight( (string.getMaxWeight() - string.getMinWeight()) * currentValue + string.getMinWeight() );
      }
	  show();
  }

//true if mouse position is over slider
boolean overSlider(){
	boolean tf = false;
  if (mouseX >= location.x && mouseX <= location.x + wide && mouseY >= location.y && mouseY <= location.y + tall){
        tf = true;
    }
    return tf;
}

//if THIS slider was clicked on, return TRUE
 boolean isPressed(){
   boolean p = false;
    if(mousePressed == true) {
      if (mouseX > location.x && mouseX < location.x + wide && mouseY > location.y && mouseY < location.y + tall){
        p = true;
      }
    }
    return p;
 }
 
 float getCurrVal(){
   return currentValue;
 }
 
 //returns value of slider as a percentage
   int getPercent(){
    //float val = currentValue * 100;
    int percent = Math.round(currentValue * 100);
    return percent;
  }
 
 MusicString getMusicString() {
 	return string;
 }
 
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

	
	int fillColor;			//the color of the string
	boolean current;		//whether or not this string can currently be altered
	PVector startPosition;	//where on screen the string appears

//constructor
MusicString (int ypos, int fc){	
	 //string specific parameters
	strLength = 200;
	strStart = (boxLength/2 - strLength/2); //TODO: doesn't center string like it should
	strTension = 70; //don't know what units we want this in
	strWeight = 1;
	maxLength = 500; //max length of string in pixels
	minLength = 100;
	maxTension = 90;
	minTension = 70;
	maxWeight = 14;
	minWeight = 1.5;
	
	  //variables that, if we change them, we'd want them to change for all instances, probably
	lengthFactor = 65/maxLength; //scale factor to multiply pixels by to get length in cm
	weightFactor = .5/1000; //scale factor for string weight

	realLength = strLength*lengthFactor;
	realWeight = strWeight*weightFactor;
	realTension = strTension;
	currentFreq = getStrFreq(realLength, realTension, realWeight);
	

	time = defaultTime;

	startIndex = 0; //frame when the note starts playing

	playingNote = false;
	n = 1; //harmonic number

	
	fillColor = fc;			//the color of the string
	current = false;		//whether or not this string can currently be altered
 int yposition = ypos; //on screen y position of string	
}


/* FUNCTIONS WITH SUBSTANCE */


//checks if mouse location is on or near enough to MusicString
//TODO: make it easier to click the string
boolean overMusicString()  {
  if (mouseX >= strStart && mouseX <= strStart+strLength && mouseY >= boxHeight/2-strWeight + 10 && mouseY <= boxHeight/2+strWeight + 10){
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
	stroke(0);
  for (float x=strStart;x<strLength+strStart;x=x+1){
    fill(0);
    //float y = (boxHeight/2);
    float y = (boxHeight/2) + getPixelMove(x,time);
    rect(x,y,1,strWeight);
  } 
}


void updateReals() {
	realLength = strLength*lengthFactor;
	realWeight = strWeight*weightFactor;
	realTension = strTension;
	currentFreq = getStrFreq(realLength, realTension, realWeight);
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
 

