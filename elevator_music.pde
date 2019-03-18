import themidibus.*;

import gab.opencv.*;
import org.opencv.core.Mat;
import org.opencv.core.Scalar;
import org.opencv.core.Core;

import processing.video.*;

static final int NUMASCENSORES = 6;
static final int OFFSETX = 200;
static final int OFFSETY = 60;
static final int DISTASCENSORES = 40;
static final int DISTPISOS = 29;
static final int RADIOPISOS = 25;
static final int THRESHOLD = 500; //16

static final boolean SHOWRECT = true;

Elevator[] ascensores = new Elevator[NUMASCENSORES];

int[] notasAcorde = {0, 3, 7, 10, 12, 15};

PImage gris;
MidiBus myBus; 
Capture cam;
OpenCV opencv;




void setup() {

  size(1280, 480);
  noFill();
  stroke(255);

  gris = createImage(640, 480, RGB);

  String[] cameras = Capture.list();
  for (int i = 0; i < cameras.length; i++) {
    println(cameras[i]);
  }

  opencv = new OpenCV(this, 640, 480);

  MidiBus.list();
  myBus = new MidiBus(this, -1, "Bus IAC 1"); 

  cam = new Capture(this, 640, 480);
  cam.start();

  for (int a=0; a<NUMASCENSORES; a++) {
    ascensores[a] = new Elevator(14, OFFSETX+a*DISTASCENSORES, height-OFFSETY, RADIOPISOS);
  }
}




void draw() {

  //Leemos el fotograma de la cámara
  if (!cam.available()) {
    return;
  }
  cam.read();
  image(cam, 0, 0);

  //Tratamos la imagen de la cámara 
  opencv.loadImage(cam);
  opencv.useColor(HSB);
  opencv.setGray(opencv.getB());
  opencv.blur(2);
  opencv.matV = contrast(1.8, opencv.getB());
  opencv.inRange(190, 255);
  gris = opencv.getSnapshot();
  image(gris, 640, 0);

  //Contamos el número de píxeles iluminados
  for (int a=0; a<NUMASCENSORES; a++) {
    for (int p=0; p<ascensores[a].totalPisos; p++) {
      int counter = 0;
      for (int y=0; y<ascensores[a].pisoSize; y++) {
        for (int x=0; x<ascensores[a].pisoSize; x++) {
          counter += gris.get(x+ascensores[a].x, ascensores[a].y-DISTPISOS*p+y) & 0x1;
        }
      }
      if (counter>THRESHOLD) {
        ascensores[a].pisoOn(p);
      } else {
        ascensores[a].pisoOff(p);
      }
    }
  }

  //Lanzamos los eventos MIDI
  for (int a=0; a<NUMASCENSORES; a++) {
    for (int p=0; p<ascensores[a].totalPisos; p++) {
      switch(ascensores[a].estadoPiso[p]) {
      case RISING:
        myBus.sendNoteOn(a, notasAcorde[p%notasAcorde.length]+64, 100);
        break;
      case FALLING:
        myBus.sendNoteOff(a, notasAcorde[p%notasAcorde.length]+64, 100);
        break;
      default:
      }
    }
  }

  //Un poco de debug
  if (SHOWRECT) {
    for (int a=0; a<NUMASCENSORES; a++) {
      for (int p=0; p<ascensores[a].totalPisos; p++) {
        stroke(255);
        rect(ascensores[a].x, ascensores[a].y-DISTPISOS*p, ascensores[a].pisoSize, ascensores[a].pisoSize);
        if (ascensores[a].estadoPiso[p]==State.RISING || ascensores[a].estadoPiso[p]==State.ON ) {
          stroke(100, 255, 100);
          rect(640+ascensores[a].x, ascensores[a].y-DISTPISOS*p, ascensores[a].pisoSize, ascensores[a].pisoSize);
        }
      }
    }
  }
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
