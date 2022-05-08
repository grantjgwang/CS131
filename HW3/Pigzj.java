import java.io.*;

public class Pigzj {
    public static void main(String[] args) throws IOException {
        int num_available_process = Runtime.getRuntime().availableProcessors();
        try {
            for(int i = 0; i < args.length; i++) {
                if(args[i].equals("-p")) {
                    // System.out.println("Receive argument -p with number of processes: " + args[i+1]);
                    num_available_process = Integer.parseInt(args[i+1]);
                    i += 1;
                }
                else {
                    throw new java.lang.Error("Receive bad argument");
                }
            }
            MultithreadCompressor pigzj = new MultithreadCompressor(num_available_process);
            pigzj.compress();
        }
        catch (NumberFormatException e) {
            System.out.println("Argument -p followed by non-numeric input"); 
        }
        catch (IOException ioe) {
            System.out.print(ioe.getMessage());
        }
    }
}

