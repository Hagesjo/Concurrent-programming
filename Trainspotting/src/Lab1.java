import TSim.*;
import java.util.concurrent.*;
import java.util.HashMap;

public class Lab1 {
   private final int MAXSPEED = 15;
   private int simulationspeed = 100;

   public static void main(String[] args) {
      new Lab1(args);
   }

   public Lab1(String[] args) {
      Semaphore[] semaphores = new Semaphore[10];

      for (int i = 0; i < 9; i++) {
         semaphores[i] = new Semaphore(1,true);
         
      }
      TSimInterface tsi = TSimInterface.getInstance();
      TSimStream  tstr = new TSimStream(System.in);
      tsi.setDebug(true);

      Train train1 = new Train(1); 
      Train train2 = new Train(2);
      if (args.length == 3 ) { 
         train1.setSpeed(Integer.parseInt(args[0]));
         train2.setSpeed(Integer.parseInt(args[1]));
         simulationspeed = Integer.parseInt(args[2]);
      } else {
         train1.setSpeed((int) (Math.random()*MAXSPEED));
         train2.setSpeed((int) (Math.random()*MAXSPEED));
         simulationspeed = Integer.parseInt(args[0]);
      }
      train1.start();
      train2.start();
   }

   public class Train extends Thread {
      private Semaphore[] rails;
      public int speed;
      public int id;
      public TSimInterface tsi;
      boolean turning = true;

      public Train(int id) {
         this.id = id;
         tsi = TSimInterface.getInstance();

      }
      
      public void setSpeed(int speed) {
         this.speed = speed;
         try {
            tsi.setSpeed(id,speed);
         } 
         catch (CommandException e) {
            System.err.println("Error setting speed");
            System.exit(1);
         }
      }
      private void turnTrain() {
         int tmpspeed = speed;
         System.err.println(-tmpspeed);
         setSpeed(0);
         try {
            sleep(2000 + 2 * simulationspeed * Math.abs(tmpspeed));
         }
         catch (InterruptedException e) {}
         setSpeed(-tmpspeed);
         System.err.println(-tmpspeed);
         turning = true;
      }
      @Override
      public void run() {
         while (true) {
            try {
               SensorEvent sens = tsi.getSensor(id);
               if (sens.getStatus() == 1) {
                  switch (sens.getXpos() * 100 + sens.getYpos()) {
                     case 903:
                     case 606:
                     case 905:
                     case 1007:
                     case 1008:
                     case 1908:
                     case 1709:
                     break;
                     case 1508:
                        tsi.setSwitch(17,7,1);
                        break;
                     case 1507:
                        tsi.setSwitch(17,7,2);
                        break;
                     case 1209:
                        tsi.setSwitch(15,9,2);
                        break;
                     case 1211:
                        tsi.setSwitch(15,9,1);
                        break;
                     case 709:
                        tsi.setSwitch(4,9, 1);
                        break;
                     case 710:
                        tsi.setSwitch(4,9, 2);
                        break;
                     //case 209:
                     //case 110:
                     case 313:
                        tsi.setSwitch(3,11, 2);
                        break;
                     case 511:
                        tsi.setSwitch(3,11, 1);
                        break;
                     case 1411: case 1413: case 1403: case 1405:
                        if (!turning) {
                           turnTrain();
                        } else {
                           turning = false;
                        }
                        break;
                  }
               }
            }
            catch (CommandException e) {
               System.exit(1);
            }
            catch (InterruptedException e) {
               System.exit(1);
            }
         }
      }
   }
}

