import java.io.IOException;

public class JGzip {
  public static void main(String[] args) throws IOException {
    SingleThreadedGZipCompressor cmp =
        new SingleThreadedGZipCompressor(args[0]);
    cmp.compress();
  }
}
