import TSim.*;
import java.util.concurrent.*;

public class Lab1 {

   public static void main(String[] args) {
      new Lab1(args);
   }

   public Lab1(String[] args) {
      Train train1 = new Train(); //todo, create semaphores before being able to send those to the constructor.
      Train train2 = new Train();
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

