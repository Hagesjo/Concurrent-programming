import TSim.*;
import java.util.concurrent.*;
import java.util.HashMap;

   /** 
    * @author Andreas Hagesjö och Robert Nyquist
    */
public class Lab1 {
   private int simulationspeed = 100;
   private final int MAXSPEED = 19;
   private final int down = 1; //constant variables to keep track of which direction the train has
   private final int up = -1;
   Semaphore[] semaphores = new Semaphore[6];

   public static void main(String[] args) throws InterruptedException, CommandException{
      new Lab1(args);
   }

   public Lab1(String[] args) throws InterruptedException, CommandException {
      for (int i = 0; i < 6; i++) {
         semaphores[i] = new Semaphore(1,true);
      }
      TSimInterface tsi = TSimInterface.getInstance();
      tsi.setDebug(false);
      Train train1 = new Train(1, down); 
      Train train2 = new Train(2, up);
      
      if (args.length >= 1) {
         simulationspeed = Integer.parseInt(args[args.length - 1]);
      }
      if (args.length == 2) {
         train1.initspeed = Integer.parseInt(args[0]);
      }
      if (args.length == 3) {
         train1.initspeed = Integer.parseInt(args[0]);
         train2.initspeed = Integer.parseInt(args[1]);
      }

      train1.setSpeed(train1.initspeed);
      train2.setSpeed(train2.initspeed);
      train1.start();
      train2.start();
   }

   public class Train extends Thread {
      private int direction;
      private int initspeed = (int) (Math.random()*(MAXSPEED - 1) + 1); 
      public int speed;
      public int id;
      public TSimInterface tsi;
      boolean turning = true;

         /**
          * @param id The id of the train
          * @param direction The direction of the train. 1 is down, -1 is up
          */
      public Train(int id, int direction) throws InterruptedException, CommandException{
         this.id = id;
         this.direction = direction;
         tsi = TSimInterface.getInstance();
            //Acquire the semaphore for the station the train starts at
            if (direction == down) {
               semaphores[3].acquire();
            } else {
               semaphores[1].acquire();
            }
      }
      
         /** 
          * Set a new speed to the train
          * @param speed the new speed of the train
          */
      public void setSpeed(int speed) throws CommandException{
         this.speed = speed;
         tsi.setSpeed(id,speed);
      }
         /**
          * Turns the train. 
          * The function sets the speed to 0, then waits 2 seconds, and then
          * sets the speed to the old speed (but backwards of course)
          */
      private void turnTrain() throws CommandException, InterruptedException {
         int tmpspeed = speed;
         setSpeed(0);
         sleep(2000 + 2 * simulationspeed * Math.abs(tmpspeed));
         setSpeed(-tmpspeed);
         initspeed = -tmpspeed;
         direction = -direction;
         turning = false;
      }

         /** 
          * Makes the train wait until the next session is released. 
          * When it is free to go, it also sets the switch in front of the
          * train to the correct direction
          * @param semaphoreId Semaphore which the train waits for to be released
          * @param x The x-coordinate for the switch
          * @param y The y-coordinate for the switch
          * @param switchDirection The direction to turn the switch to
          */
      private void waitUntilReady(int semaphoreId,int x, int y, int switchDirection) throws InterruptedException, CommandException {
            setSpeed(0);
            semaphores[semaphoreId].acquire();
            setSpeed(initspeed);
            tsi.setSwitch(x,y, switchDirection);
      }

      @Override
      public void run() {
            //We use 6 semaphores for the different areas.
            //semaphores[0] is the cross at the top
            //semaphores[1] is the bottom station
            //semaphores[2] is the critical "onelinepath" after the bottom station 
            //semaphores[3] is the top station
            //semaphores[4] is the fastest path in the "choose-section" in the middle
            //semaphores[5] is the critical "onelinepath" after the top station
            //Everytime the path (semaphore) the train is about to enter is acquired, the train stops and waits for the semaphore to be released before starting again (exception below):
            
            //We use tryAcquire everytime the train has to choose path,
            //which means when the train is about to exit a critical path (and then doesn't have to stop)
            //If the semaphores then fails to be acquired, the train (well...the switch) simply chooses the other free path
         while (true) {
            try {
               SensorEvent sens = tsi.getSensor(id);
               if (sens.getStatus() == 1) {
                  //All cases are sorted according to the map (easier reading)
                  switch (sens.getXpos() * 100 + sens.getYpos()) { //Makes a unique ID for every sensor
                     case 606: case 905:
                        if (direction == down) {
                           setSpeed(0);
                           semaphores[0].acquire();
                           setSpeed(initspeed);
                        } else {
                           semaphores[0].release();
                        }
                     break;

                     case 1107: case 1008:
                        if (direction == up) {
                           setSpeed(0);
                           semaphores[0].acquire();
                           setSpeed(initspeed);
                        } else {
                           semaphores[0].release();
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
                           semaphores[3].release();
                        } else {
                           semaphores[5].release();
                        }
                        break;

                     case 1908:
                        if (direction == up) {
                           if (semaphores[3].tryAcquire()) {
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

                     case 1409:
                        if (direction == up) {
                           semaphores[4].release();
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

                     case 509:
                        if (direction == down) {
                           semaphores[4].release();
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

                        //Endstation-sensors. Makes the train reverse
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
