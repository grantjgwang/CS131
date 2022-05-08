import java.io.*;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.zip.*;

public class MultithreadCompressor {
    public final static int BLOCK_SIZE = 1024*128;
    public final static int DICT_SIZE = 1024*32;
    private final static int GZIP_MAGIC = 0x8b1f;
    private final static int TRAILER_SIZE = 8;

    private int num_proccess;
    public ByteArrayOutputStream outStream = new ByteArrayOutputStream();
    private CRC32 crc = new CRC32();

    public MultithreadCompressor(int num_available_process) {
        this.num_proccess = num_available_process;
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
            3               // Operating system (OS) or "(byte)0xff"
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
        long inputSize = 0;
        byte[] currBlockBuf = new byte[BLOCK_SIZE];
        byte[] nextBlockBuf = new byte[BLOCK_SIZE];
        byte[] dictBuf = new byte[DICT_SIZE];
        ThreadPoolExecutor executor = (ThreadPoolExecutor) Executors.newFixedThreadPool(num_proccess);
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
            compressor.reset();
            ThreadCompressor threadCompressor = new ThreadCompressor(compressor, currBlockBuf, hasDict, dictBuf, currReadSize, last, outStream);
            executor.execute(threadCompressor);
            if (currReadSize >= DICT_SIZE) {
                System.arraycopy(currBlockBuf, currReadSize - DICT_SIZE, dictBuf, 0, DICT_SIZE);
                hasDict = true;
              } else {
                hasDict = false;
            }

            if((currReadSize = nextReadSize) > 0) {
                currBlockBuf = nextBlockBuf;
                if((nextReadSize = System.in.read(nextBlockBuf)) < 0) {
                    last = true;
                }
            }
            else {
                done = true;
            }
        }
        executor.shutdown();
        // trailer
        byte[] trailerBuf = new byte[TRAILER_SIZE];
        writeTrailer(inputSize, trailerBuf, 0);
        outStream.write(trailerBuf);

        // oputput the result
        outStream.writeTo(System.out);
        outStream.close();
    }
}
