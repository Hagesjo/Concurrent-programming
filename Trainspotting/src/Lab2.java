import TSim.*;
import java.util.concurrent.locks.*;

/** 
 * @author Andreas Hagesjö och Robert Nyquist
 */
public class Lab2 {
   private int simulationspeed = 100;
   private final int MAXSPEED = 19;
   private final int down = 1; 
   private final int up = -1;
   Track track0 = new Track();
   Track track1 = new Track();
   Track track2 = new Track();
   Track track3 = new Track();
   Track track4 = new Track();
   Track track5 = new Track();



   public static void main(String[] args) throws InterruptedException, CommandException{
      new Lab2(args);
   }

   public Lab2(String[] args) throws InterruptedException, CommandException {

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


      public Train(int id, int direction) throws InterruptedException, CommandException{
         this.id = id;
         this.direction = direction;
         tsi = TSimInterface.getInstance();
         if (direction == down) {
            track3.enter();
         } else {
            track1.enter();
         }
      }


      public void setSpeed(int speed) throws CommandException{
         this.speed = speed;
         tsi.setSpeed(id,speed);
      }


      private void turnTrain() throws CommandException, InterruptedException {
         int tmpspeed = speed;
         setSpeed(0);
         sleep(2000 + 2 * simulationspeed * Math.abs(tmpspeed));
         setSpeed(-tmpspeed);
         initspeed = -tmpspeed;
         direction = -direction;
         turning = false;
      }

      private void waitUntilReady(Track track,int x, int y, int switchDirection) throws InterruptedException, CommandException {
         setSpeed(0);
         track.enter();
         setSpeed(initspeed);
         tsi.setSwitch(x,y, switchDirection);
      }

      @Override
         public void run() {
            //We use 6 Tracks for the different areas.
            //track0 is the cross at the top
            //track1 is the bottom station
            //track2 is the critical "onelinepath" after the bottom station 
            //track3 is the top station
            //track4 is the fastest path in the "choose-section" in the middle
            //track5 is the critical "onelinepath" after the top station

            //Everytime the train has completely left a path connected to a Track, this Track is set to empty, and the new Track (the path the train entered) is (if possible) entered.
            //Everytime the path (Track) the train is about to enter already is entered, the train stops and waits for the Track to be empty before starting again (exception below):

            //We use tryEnter everytime the train has to choose path,
            //which means when the train is about to exit a critical path, and therefore doesn't have to stop, it just has to choose path.
            //If the Track for the default path fails to be entered, the train (well...the switch) simply chooses the other free path
            while (true) {
               try {
                  SensorEvent sens = tsi.getSensor(id);
                  if (sens.getStatus() == 1) {
                     //All cases are sorted according to the map (easier reading)
                     switch (sens.getXpos() * 100 + sens.getYpos()) { //Makes a unique ID for every sensor
                        case 606: case 905:
                           if (direction == down) {
                              setSpeed(0);
                              track0.enter();
                              setSpeed(initspeed);
                           } else {
                              track0.leave();
                           }
                           break;

                        case 1107: case 1008:
                           if (direction == up) {
                              setSpeed(0);
                              track0.enter();
                              setSpeed(initspeed);
                           } else {
                              track0.leave();
                           }
                           break;

                        case 1508:
                           if (direction == down) {
                              waitUntilReady(track5,17,7,1);
                           } else {
                              track5.leave();
                           }
                           break;

                        case 1407:
                           if (direction == down) {
                              waitUntilReady(track5,17,7,2);
                              track3.leave();
                           } else {
                              track5.leave();
                           }
                           break;

                        case 1908:
                           if (direction == up) {
                              if (track3.tryEnter()) {
                                 tsi.setSwitch(17,7,2);
                              } else {
                                 tsi.setSwitch(17,7,1);
                              }
                           }
                           break;

                        case 1709:
                           if (direction == down) {
                              if (track4.tryEnter()) {
                                 tsi.setSwitch(15,9,2);
                              } else {
                                 tsi.setSwitch(15,9,1);
                              }
                           }
                           break;

                        case 1409:
                           if (direction == up) {
                              track4.leave();
                           }
                           break;

                        case 1209:
                           if (direction == up) {
                              waitUntilReady(track5,15,9,2);
                           } else {
                              track5.leave();
                           }
                           break;

                        case 1310:
                           if (direction == up) {
                              waitUntilReady(track5,15,9,1);
                           } else {
                              track5.leave();
                           }
                           break;

                        case 709:
                           if (direction == down) {
                              waitUntilReady(track2,4,9,1);
                           } else {
                              track2.leave();
                           }
                           break;

                        case 610:
                           if (direction == down) {
                              waitUntilReady(track2,4,9,2);
                           } else {
                              track2.leave();
                           }
                           break;

                        case 509:
                           if (direction == down) {
                              track4.leave();
                           }
                           break;

                        case 209:
                           if (direction == up) {
                              if (track4.tryEnter()) {
                                 tsi.setSwitch(4,9,1);
                              } else {
                                 tsi.setSwitch(4,9,2);
                              }
                           } 
                           break;

                        case 110:
                           if (direction == down) {
                              if (track1.tryEnter()) {
                                 tsi.setSwitch(3,11,1);
                              } else {
                                 tsi.setSwitch(3,11,2);
                              }
                           }
                           break;

                        case 413:
                           if(direction == up){
                              waitUntilReady(track2,3,11,2);
                           } else {
                              track2.leave();
                           }
                           break;

                        case 611:
                           if(direction == up){
                              waitUntilReady(track2,3,11,1);
                              track1.leave();
                           } else {
                              track2.leave();
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
   public class Track {
      private Lock lock = new ReentrantLock();
      private Condition critical = lock.newCondition();
      private boolean empty = true;

      /**
       * Enters a track.
       * If the track is not empty, it will wait for the signal that the method "leave" sends
       */
      public void enter() throws InterruptedException {
         lock.lock();
         if (!empty) {
            critical.await();
         }
         empty = false;
         lock.unlock();
      }
      /**
       * Leaves a track.
       * Sends a signal to the track, telling it that it is now empty.
       */
      public void leave(){
         lock.lock();
         empty = true;
         critical.signal();
         lock.unlock();
      }
      /**
       * Tries to enter a track.
       * if the track is empty, send enter(). 
       * @return false if the track is taken.
       * @return true if the track is empty.
       */
      public boolean tryEnter() throws InterruptedException {
         boolean enterd = false;
         if(empty){
            enterd = true;
            enter();
         }
         return enterd;
      }
   }
}

