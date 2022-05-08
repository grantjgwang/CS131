import java.io.*;
import java.util.zip.*;
 
public class ThreadCompressor implements Runnable {
    public final static int DICT_SIZE = 1024*32;
    public final static int BLOCK_SIZE = 1024*128;
    
    private byte[] blockBuf = new byte[BLOCK_SIZE];
    private boolean hasDict;
    private byte[] dictBuf = new byte[DICT_SIZE];
    byte[] cmpBlockBuf = new byte[BLOCK_SIZE * 2];
    private int readSize;
    private Deflater compressor;
    private boolean last;
    private ByteArrayOutputStream outStream;

    public ThreadCompressor(Deflater compressor, byte[] blockBuf, Boolean hasDict, byte[] dictBuf, int readSize, boolean last, ByteArrayOutputStream outStream) {
        this.compressor = compressor;
        this.blockBuf = blockBuf;
        this.hasDict = hasDict;
        this.dictBuf = dictBuf;
        this.readSize = readSize;
        this.last = last;
        this.outStream = outStream;
    }
 
    public void run() {
        compressor.reset();
        if(hasDict) {
            compressor.setDictionary(dictBuf);
        }
        compressor.setInput(blockBuf, 0, readSize);

        if (last) {
            /* If we've read all the bytes in the file, this is the last block.
               We have to clean out the deflater properly */
        if (!compressor.finished()) {
            compressor.finish();
            while (!compressor.finished()) {
                int deflatedBytes = compressor.deflate(
                    cmpBlockBuf, 0, cmpBlockBuf.length, Deflater.NO_FLUSH);
                if (deflatedBytes > 0) {
                    outStream.write(cmpBlockBuf, 0, deflatedBytes);
                }
            }
        }
        } else {
            /* Otherwise, just deflate and then write the compressed block out. Not
          using SYNC _FLUSH here leads to some issues, but using it probably results
          in less efficient compression. Ther e's probably a better
               way to deal with this. */
            int deflatedBytes = compressor.deflate(
                cmpBlockBuf, 0, cmpBlockBuf.length, Deflater.SYNC_FLUSH);
            if (deflatedBytes > 0) {
              outStream.write(cmpBlockBuf, 0, deflatedBytes);
            }
        }

    }
}
