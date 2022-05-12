import java.io.*;
import java.util.zip.*;
import java.util.concurrent.Future;
import java.util.concurrent.Callable;
 
public class ThreadCompressor implements Callable<byte[]> {
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
    private Future<byte[]> prevTask;
    
    private int j;

    public ThreadCompressor(Deflater compressor, byte[] blockBuf, Boolean hasDict, byte[] dictBuf, int readSize, boolean last, ByteArrayOutputStream outStream, Future<byte[]> prevTask, int j) {
        this.compressor = compressor;
        this.blockBuf = blockBuf;
        this.hasDict = hasDict;
        this.dictBuf = dictBuf;
        this.readSize = readSize;
        this.last = last;
        this.outStream = outStream;
        this.prevTask = prevTask;
        this.j = j;
    }
    
    @Override
    public byte[] call() throws Exception {
        while(prevTask != null && !prevTask.isDone()) {
            // System.out.println("waiting...");
        }
        
        // System.out.println("Thread get: " + blockBuf + " with size " + readSize + " is last? " + last + " in turn " + j);

        ByteArrayOutputStream tempStream = new ByteArrayOutputStream(); 
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
                        tempStream.write(cmpBlockBuf, 0, deflatedBytes);
                    }
                }
            }
        } else {
            int deflatedBytes = compressor.deflate(
                cmpBlockBuf, 0, cmpBlockBuf.length, Deflater.SYNC_FLUSH);
            if (deflatedBytes > 0) {
                tempStream.write(cmpBlockBuf, 0, deflatedBytes);
            }
        }
        
        tempStream.writeTo(outStream);
        tempStream.close();
        return (tempStream.toByteArray());
    }
}
