import TSim.*;
import java.util.concurrent.*;
import java.util.HashMap;

public class Lab1 {
   private final int MAXSPEED = 15;
   private int simulationspeed = 100;
   private HashMap<Integer, Semaphore> allSensors = new HashMap<>();

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
      tsi.setDebug(false);

      Train train1 = new Train(1, semaphores); 
      Train train2 = new Train(2, semaphores);
      if (args.length == 3 ) { 
         train1.setSpeed(Integer.parseInt(args[0]));
         train2.setSpeed(Integer.parseInt(args[1]));
         simulationspeed = Integer.parseInt(args[2]);
      } else {
         train1.setSpeed((int) (Math.random()*MAXSPEED));
         train2.setSpeed((int) (Math.random()*MAXSPEED));
         simulationspeed = Integer.parseInt(args[0]);
      }
      while(true) {
         try {
            SensorEvent olol=(SensorEvent) tstr.read();
            System.err.println(olol.getXpos());
         }
         catch (UnparsableInputException e) {
            System.err.println("OLOLOLOL");
         }
      }
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
            System.exit(1);
         }
      }
   }
}

