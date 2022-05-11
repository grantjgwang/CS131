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
    private int currIdx;
    private int preIdx;

    public ThreadCompressor(Deflater compressor, byte[] blockBuf, Boolean hasDict, byte[] dictBuf, int readSize, boolean last, ByteArrayOutputStream outStream, int currIdx, int preIdx) {
        this.compressor = compressor;
        this.blockBuf = blockBuf;
        this.hasDict = hasDict;
        this.dictBuf = dictBuf;
        this.readSize = readSize;
        this.last = last;
        this.outStream = outStream;
        this.currIdx = currIdx;
        this.preIdx = preIdx;
    }
 
    public synchronized  void run() {
        // System.out.write(blockBuf, 0, readSize);
        
        // System.out.println("Thread get: " + blockBuf + " with size " + readSize + " and lock is " + currIdx + "/" + preIdx);
        synchronized (MultithreadCompressor.LOCKS) {
            while(MultithreadCompressor.LOCKS.get(preIdx) && MultithreadCompressor.LOCKS.get(currIdx)) {
                try {
                    MultithreadCompressor.LOCKS.wait();
                }
                catch (InterruptedException e) {
                    //System.out.println("Interrupted Exception!");
                }
            }
            MultithreadCompressor.LOCKS.set(preIdx, true);
            // System.out.println("done waiting");
            
            compressor.reset();
            if(hasDict) {
                compressor.setDictionary(dictBuf);
            }
            compressor.setInput(blockBuf, 0, readSize);
            
            if (last) {
                if (!compressor.finished()) {
                    compressor.finish();
                    while (!compressor.finished()) {
                        int deflatedBytes = compressor.deflate(cmpBlockBuf, 0, cmpBlockBuf.length, Deflater.NO_FLUSH);
                        if (deflatedBytes > 0) {                      
                            outStream.write(cmpBlockBuf, 0, deflatedBytes);
                        }
                    }
                }
            } else {
                int deflatedBytes = compressor.deflate(
                    cmpBlockBuf, 0, cmpBlockBuf.length, Deflater.SYNC_FLUSH);
                if (deflatedBytes > 0) {
                    outStream.write(cmpBlockBuf, 0, deflatedBytes);
                }
            }
            MultithreadCompressor.LOCKS.set(preIdx, false);
            // System.out.println("unlock " + currIdx);
            MultithreadCompressor.LOCKS.notifyAll();
        }
    }
}
