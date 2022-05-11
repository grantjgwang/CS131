import java.io.*;
import java.util.*;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.zip.*;
import java.util.concurrent.TimeUnit;
import java.util.Collections;

public class MultithreadCompressor {
    public final static int BLOCK_SIZE = 131072;
    public final static int DICT_SIZE = 32768;
    private final static int GZIP_MAGIC = 0x8b1f;
    private final static int TRAILER_SIZE = 8;
    public static List<Boolean> LOCKS;

    private int num_proccess;
    public ByteArrayOutputStream outStream = new ByteArrayOutputStream();
    private CRC32 crc = new CRC32();
    public static ThreadPoolExecutor executor;

    public MultithreadCompressor(int num_available_process) {
        this.num_proccess = num_available_process;
        LOCKS = new ArrayList<Boolean>(Arrays.asList(new Boolean[num_available_process]));
        Collections.fill(LOCKS, Boolean.FALSE);
        LOCKS = Collections.synchronizedList(LOCKS);
        executor = (ThreadPoolExecutor) Executors.newFixedThreadPool(num_proccess);
    }

    private void writeHeader() throws IOException {
        outStream.write(new byte[] {
            (byte)GZIP_MAGIC,        // Magic number (short)
            (byte)(GZIP_MAGIC >> 8), // Magic number (short)
            Deflater.DEFLATED,       // Compression method (CM)
            0,                       // Flags (FLG)
            0,                       // Modification time MTIME (int)
            0,                       // Modification time MTIME (int)
            0,                       // Modification time MTIME (int)
            0,                       // Modification time MTIME (int)Sfil
            0,                       // Extra flags (XFLG)
            0               // Operating system (OS) or "(byte)0xff"
        });
    }

    private void writeTrailer(long totalBytes, byte[] buf, int offset) throws IOException {
        writeInt((int)crc.getValue(), buf, offset); // CRC-32 of uncompr. data
        writeInt((int)totalBytes, buf, offset + 4); // Number of uncompr. bytes
    }

    private void writeInt(int i, byte[] buf, int offset) throws IOException {
        writeShort(i & 0xffff, buf, offset);
        writeShort((i >> 16) & 0xffff, buf, offset + 2);
    } 

    private void writeShort(int s, byte[] buf, int offset) throws IOException {
        buf[offset] = (byte)(s & 0xff);
        buf[offset + 1] = (byte)((s >> 8) & 0xff);
    }

    public void compress() throws IOException {
        // header 
        this.writeHeader();
        this.crc.reset();

        // read from standard input and compress 1024 byte at a time
        boolean done = false;
        boolean last = false;
        boolean hasDict = false;
        int currReadSize;
        int nextReadSize = -1;
        int i = 0;
        long inputSize = 0;
        byte[] currBlockBuf = new byte[BLOCK_SIZE];
        byte[] nextBlockBuf = new byte[BLOCK_SIZE];
        byte[] dictBuf = new byte[DICT_SIZE];
        Deflater compressor = new Deflater(Deflater.DEFAULT_COMPRESSION, true); 
        if((currReadSize = System.in.read(currBlockBuf)) > 0) {
            if((nextReadSize = System.in.read(nextBlockBuf)) < 0) {
                last = true;
            }
        }
        else {
            done = true;
        }
        /*
            BufferedInputStream bf = new BufferedInputStream(System.in);
            byte[] currBlockBuf = new byte[1024];
            int i;
            while((i = bf.read(currBlockBuf)) != -1) {
                char c = (char) i;
                System.out.println(currBlockBuf);
            }
            bf.close();
        */
        while (!done) {
            inputSize += currReadSize;
            crc.update(currBlockBuf, 0, currReadSize);
            int currIdx = i;
            int preIdx;
            if (i < 1) {
                preIdx = num_proccess - 1;
            }
            else {
                preIdx = i - 1;
            }
            ThreadCompressor threadCompressor = new ThreadCompressor(compressor, currBlockBuf, hasDict, dictBuf, currReadSize, last, outStream, currIdx, preIdx);
            // System.out.println("Prepoare to compresss");

            executor.execute(threadCompressor);
            
            if (currReadSize >= DICT_SIZE) {
                System.arraycopy(currBlockBuf, currReadSize - DICT_SIZE, dictBuf, 0, DICT_SIZE);
                hasDict = true;
              }

            currBlockBuf = new byte[BLOCK_SIZE];
            System.arraycopy(nextBlockBuf, 0, currBlockBuf, 0, BLOCK_SIZE);
            if((currReadSize = nextReadSize) > 0) {
                // nextBlockBuf = new byte[BLOCK_SIZE];
                if((nextReadSize = System.in.read(nextBlockBuf)) < 0) {
                    last = true;
                }
            }
            else {
                done = true;
            }
            i += 1;
            if (i == num_proccess) {
                i = 0;
            }
        }
        executor.shutdown();
        
        // trailer
        while(!executor.isTerminated()) {}
        byte[] trailerBuf = new byte[TRAILER_SIZE];
        writeTrailer(inputSize, trailerBuf, 0);
        outStream.write(trailerBuf);

        // oputput the result
        // System.out.println("CRC : " + crc.getValue() + " and length: " + inputSize);
        outStream.writeTo(System.out);
        outStream.close();
    }
}
