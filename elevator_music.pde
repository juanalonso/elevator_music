import themidibus.*;

import gab.opencv.*;
import org.opencv.core.Mat;
import org.opencv.core.Scalar;
import org.opencv.core.Core;

import processing.video.*;

static final int NUMASCENSORES = 6;

Elevator[] ascensores = new Elevator[NUMASCENSORES];

/*
1:   13 -> bajo
 2:    4 -> bajo -> 11
 3:    8 -> bajo ->  6
 4:    8 ->   13 -> 10
 5: bajo
 6: bajo ->    8
 
 */

int[] notasAcorde = {0, 3, 7, 10, 12, 15};

PImage gris;
MidiBus myBus; 
Movie video;
OpenCV opencv;

void setup() {

  size(450, 800);
  noFill();
  stroke(220);

  gris = createImage(450, 800, RGB);

  MidiBus.list();
  myBus = new MidiBus(this, -1, "IAC Bus 1"); 

  for (int f=0; f<NUMASCENSORES; f++) {
    ascensores[f] = new Elevator(14);
  }

  video = new Movie(this, "Estabilizado y escala.mp4");
  opencv = new OpenCV(this, 450, 800);

  video.loop();
  video.play();
  video.volume(0);
}



void draw() {


  opencv.loadImage(video);
  opencv.useColor(HSB);
  opencv.setGray(opencv.getB());
  opencv.blur(2);
  opencv.matV = contrast(1.8, opencv.getB());
  opencv.inRange(190, 255);

  gris = opencv.getSnapshot();

  for (int a=0; a<NUMASCENSORES; a++) {
    for (int p=0; p<ascensores[a].totalPisos; p++) {
      int counter = 0;
      for (int y=0; y<25; y++) {
        for (int x=0; x<25; x++) {
          counter += gris.get(x+73+a*40, height-324-29*p+y) & 0x000001;
        }
      }
      if (counter>16) {
        ascensores[a].pisoOn(p);
      } else {
        ascensores[a].pisoOff(p);
      }
    }
  }

  image(video, 0, 0);  

  for (int a=0; a<NUMASCENSORES; a++) {
    for (int p=0; p<ascensores[a].totalPisos; p++) {
      switch(ascensores[a].estadoPiso[p]) {
      case RISING:
        //rect(73+a*40, height-324-29*p, 25, 25);
        //println("ASC " + (a+1) + " R " + p);
        myBus.sendNoteOn(a, notasAcorde[p%notasAcorde.length]+64, 100);
        break;
      case ON:
        //rect(73+a*40, height-324-29*p, 25, 25);
        break;
      case FALLING:
        //println("ASC " + (a+1) + " F " + p);
        myBus.sendNoteOff(a, notasAcorde[p%notasAcorde.length]+64, 100);
        break;
      case OFF:
        break;
      }
    }
  }
}



void movieEvent(Movie m) {
  m.read();
}



//Amount of contrast to apply. 0-1.0 reduces contrast. Above 1.0 increases contrast.
Mat contrast(float amt, Mat m) {
  Scalar modifier = new Scalar(amt);
  Core.multiply(m, modifier, m);
  return m;
}



//The amount to brighten the image. Ranges -255 to 255. 
Mat brightness(int amt, Mat m) {
  Scalar modifier = new Scalar(amt);
  Core.add(m, modifier, m);
  return m;
}
