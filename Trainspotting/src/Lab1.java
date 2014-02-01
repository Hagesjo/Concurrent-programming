import TSim.*;
import java.util.concurrent.*;
import java.util.HashMap;

public class Lab1 {
   private final int MAXSPEED = 15;
   private int simulationspeed = 100;
   private final int down = 1;
   private final int up = -1;
   Semaphore[] semaphores = new Semaphore[9];

   public static void main(String[] args) {
      new Lab1(args);
   }

   public Lab1(String[] args) {

      for (int i = 0; i < 9; i++) {
         semaphores[i] = new Semaphore(1,true);
      }
      TSimInterface tsi = TSimInterface.getInstance();
      TSimStream  tstr = new TSimStream(System.in);
      tsi.setDebug(true);

      Train train1 = new Train(1, down); 
      Train train2 = new Train(2, up);
      if (args.length == 3 ) { 
         train1.initspeed = Integer.parseInt(args[0]);
         train2.initspeed = Integer.parseInt(args[1]);
         simulationspeed = Integer.parseInt(args[2]);
      } else {
         train1.initspeed = (int) (Math.random()*MAXSPEED);
         train2.initspeed = (int) (Math.random()*MAXSPEED);
         simulationspeed = Integer.parseInt(args[0]);
      }
      train1.setSpeed(train1.initspeed);
      train2.setSpeed(train2.initspeed);
      train1.start();
      train2.start();
   }

   public class Train extends Thread {
      private int direction;
      private int initspeed;
      public int speed;
      public int id;
      public TSimInterface tsi;
      boolean turning = true;

      public Train(int id, int direction) {
         this.id = id;
         this.direction = direction;
         tsi = TSimInterface.getInstance();
         try {
            if (direction == down) {
               semaphores[6].acquire();
            } else {
               semaphores[1].acquire();
            }
         }
         catch (Exception e) {}
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
         setSpeed(0);
         try {
            sleep(1000 + 2 * simulationspeed * Math.abs(tmpspeed));
         }
         catch (InterruptedException e) {}
         setSpeed(-tmpspeed);
         initspeed = -tmpspeed;
         direction = -direction;
         turning = false;
      }

      private void waitUntilReady(int semaphoreId,int x, int y, int switchDirection) {
         try {
            setSpeed(0);
            semaphores[semaphoreId].acquire();
            setSpeed(initspeed);
            tsi.setSwitch(x,y, switchDirection);
         } catch (Exception e) {
            System.exit(1);
         }
      }

      @Override
      public void run() {
         while (true) {
            try {
               SensorEvent sens = tsi.getSensor(id);
               if (sens.getStatus() == 1) {
                  switch (sens.getXpos() * 100 + sens.getYpos()) {
                     case 509:
                        if (direction == down) {
                           semaphores[4].release();
                        }
                     break;
                     case 1409:
                        if (direction == up) {
                           semaphores[4].release();
                        }
                     break;
                     case 606: case 905:
                        if (direction == down) {
                           setSpeed(0);
                           semaphores[7].acquire();
                           setSpeed(initspeed);
                        } else {
                           semaphores[7].release();
                        }
                     break;
                     case 1007: case 1008:
                        if (direction == up) {
                           setSpeed(0);
                           semaphores[7].acquire();
                           setSpeed(initspeed);
                        } else {
                           semaphores[7].release();
                        }
                     break;
                     case 1908:
                        if (direction == up) {
                           if (semaphores[6].tryAcquire()) {
                              tsi.setSwitch(17,7,2);
                           } else {
                              tsi.setSwitch(17,7,1);
                           }
                        }
                        break;
                        
                     case 1709:
                        if (direction == down) {
                           if (semaphores[4].tryAcquire()) {
                              tsi.setSwitch(15,9,2);
                           } else {
                              tsi.setSwitch(15,9,1);
                           }
                        } 
                        break;
                     
                     case 209:
                        if (direction == up) {
                           if (semaphores[4].tryAcquire()) {
                              tsi.setSwitch(4,9,1);
                           } else {
                              tsi.setSwitch(4,9,2);
                           }
                        } 
                        break;
                     case 110:
                        if (direction == down) {
                           if (semaphores[1].tryAcquire()) {
                              tsi.setSwitch(3,11,1);
                           } else {
                              tsi.setSwitch(3,11,2);
                           }
                        }
                           break;
                     case 1508:
                        if (direction == down) {
                           waitUntilReady(5,17,7,1);
                        } else {
                           semaphores[5].release();
                        }
                        break;
                     case 1407:
                        if (direction == down) {
                           waitUntilReady(5,17,7,2);
                           semaphores[6].release();
                        } else {
                           semaphores[5].release();
                        }
                        break;
                     case 1209:
                        if (direction == up) {
                           waitUntilReady(5,15,9,2);
                        } else {
                           semaphores[5].release();
                        }
                        break;
                     case 1310:
                        if (direction == up) {
                           waitUntilReady(5,15,9,1);
                        } else {
                           semaphores[5].release();
                        }
                        break;
                     case 709:
                        if (direction == down) {
                           waitUntilReady(2,4,9,1);
                        } else {
                           semaphores[2].release();
                        }
                        break;
                     case 610:
                        if (direction == down) {
                           waitUntilReady(2,4,9,2);
                        } else {
                           semaphores[2].release();
                        }
                        break;
                     case 413:
                        if(direction == up){
                           waitUntilReady(2,3,11,2);
                        } else {
                           semaphores[2].release();
                        }
                        break;
                     case 611:
                        if(direction == up){
                           waitUntilReady(2,3,11,1);
                           semaphores[1].release();
                        } else {
                           semaphores[2].release();
                        }
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

