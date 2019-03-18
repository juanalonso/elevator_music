class Elevator {

  int totalPisos, pisoSize, x, y;
  State[] estadoPiso;

  Elevator(int totalPisos, int x, int y, int pisoSize) {
    this.totalPisos = totalPisos;
    this.pisoSize = pisoSize;
    this.x = x;
    this.y = y;
    estadoPiso = new State[this.totalPisos];
    for (int f=0; f<this.totalPisos; f++) {
      estadoPiso[f] = State.OFF;
    }
  }

  void pisoOn(int piso) {
    switch(estadoPiso[piso]) {
    case RISING:
      estadoPiso[piso] = State.ON;
      break;
    case ON:
      break;
    case FALLING:
    case OFF:
      estadoPiso[piso] = State.RISING;
      break;
    }
  }


  void pisoOff(int piso) {
    switch(estadoPiso[piso]) {
    case FALLING:
      estadoPiso[piso] = State.OFF;
      break;
    case OFF:
      break;
    case RISING:
    case ON:
      estadoPiso[piso] = State.FALLING;
      break;
    }
  }
}
