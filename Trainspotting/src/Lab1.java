import TSim.*;
import java.util.concurrent.*;

public class Lab1 {
   private final int MAXSPEED = 15;
   private int simulationspeed = 100;

   public static void main(String[] args) {
      new Lab1(args);
   }

   public Lab1(String[] args) {
      Semaphore[] semaphores = new Semaphore[10];

      for (int i = 0; i < 10; i++) {
         semaphores[i] = new Semaphore(1,true);
      }

      TSimInterface tsi = TSimInterface.getInstance();
      tsi.setDebug(true);

      Train train1 = new Train(1, semaphores); 
      Train train2 = new Train(2, semaphores);
      if (args[1] != null) { 
         train1.setSpeed(Integer.parseInt(args[0]));
         train2.setSpeed(Integer.parseInt(args[1]));
         simulationspeed = Integer.parseInt(args[4]);
      } else {
         train1.setSpeed((int) Math.random()*MAXSPEED);
         train2.setSpeed((int) Math.random()*MAXSPEED);
         simulationspeed = Integer.parseInt(args[0]);
      }
      //try {
           //tsi.setDebug(true);
           //tsi.setSpeed(1,10);
           //tsi.setSpeed(2,10);
      //}
      //catch (CommandException e) {
         //e.printStackTrace();    // or only e.getMessage() for the error
         //System.exit(1);
      //}
   }
   public class Train extends Thread implements Runnable {
      private Semaphore[] rails;
      public int speed;
      public int id;

      public Train(int id,Semaphore[] semaphores) {
         this.id = id;
         rails = semaphores;
      }
      
      public void setSpeed(int speed) {
         TSimInterface tsi = TSimInterface.getInstance();
         try {
            tsi.setSpeed(id,speed);
         } 
         catch (CommandException e) {
            System.err.println("Error setting speed");
         }
      }
   }
}

