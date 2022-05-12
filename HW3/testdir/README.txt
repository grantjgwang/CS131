CS131 Homework3

The goal of the homework was to build a multithread compressor, Pigzj, that behave similar to 
pigz. However, I sucessfully set up multithread and have the compressor working on the smaller 
files but the program results in some issue on bigger files. In SEASnet Linux server, the real 
time, CPU time, and file system space that are needed to build each programs are listed as 
following: 

- time gzip <$input >gzip.gz
    real    0m7.232s
    user    0m7.141s
    sys     0m0.057s

- time pigz <$input >pigz.gz
    real    0m3.445s
    user    0m7.057s
    sys     0m0.090s

- time java Pigzj <$input >Pigzj.gz
    real    0m10.431s
    user    0m38.274s
    sys     0m0.451s

- time ./pigzj <$input >pigzj.gz
    real    0m15.260s
    user    0m43.841s
    sys     0m0.510s

- ls -l gzip.gz pigz.gz Pigzj.gz pigzj.gz
    -rw-r--r-- 1 jenggang csugrad 43476941 May 11 17:52 gzip.gz
    -rw-r--r-- 1 jenggang csugrad 43351345 May 11 17:53 pigz.gz
    -rw-r--r-- 1 jenggang csugrad 44230199 May 11 17:55 pigzj.gz
    -rw-r--r-- 1 jenggang csugrad 44234775 May 11 17:53 Pigzj.gz

If we check the outputs of the uncompressed results from the Pigzj compressor, there is some 
difference in line 72. I was unable to fix the issue in the given time after helps from all
the kindest people. 

- gzip -d <Pigzj.gz | cmp - $input
    /usr/local/cs/jdk-17.0.2/lib/modules differ: byte 131139, line 72

- gzip -d <pigzj.gz | cmp - $input
    /usr/local/cs/jdk-17.0.2/lib/modules differ: byte 131191, line 72

If we compare each the number of processors and the times for each program, the following 
tables can be observed. 

- time pigz -p 1 <$input >pigz1.gz
    real    0m7.095s
    user    0m6.958s
    sys     0m0.079s

- time pigz -p 5 <$input >pigz5.gz
    real    0m1.978s
    user    0m7.014s
    sys     0m0.140s

- time pigz -p 10 <$input >pigz10.gz
    real    0m2.009s
    user    0m7.054s
    sys     0m0.108s

The compression ratio uncompressed size divided by compressed size of pigz is about 2.925. 

- time java Pigzj -p 1 <$input >Pigzj1.gz
    real    0m7.846s
    user    0m14.040s
    sys     0m0.376s

- time java Pigzj -p 5 <$input >Pigzj5.gz
    real    0m12.176s
    user    0m45.175s
    sys     0m0.452s

- time java Pigzj -p 10 <$input >Pigzj10.gz
    real    0m21.032s
    user    1m20.536s
    sys     0m0.477s

The compression ratio for Pigzj is about 2.866.

- time ./pigzj -p 1 <$input >pigzj1.gz
    real    0m8.054s
    user    0m14.085s
    sys     0m0.463s

- time ./pigzj -p 5 <$input >pigzj5.gz
    real    0m15.265s
    user    0m49.889s
    sys     0m0.513s

- time ./pigzj -p 10 <$input >pigzj10.gz
    real    0m25.195s
    user    1m25.058s
    sys     0m0.493s

The compression ratio of ./pigzj is about 2.867. The compression ratios of the three 
programs are close but the ratio for pigz is slightly larger. With the performing times
and the compression ratio, pigz has better performance comparing to the other three.

If we use strace to trace the system calls by four programs, the summary tables as 
shown can be found. 

- strace -c gzip <$input >gzip.gz
    % time     seconds  usecs/call     calls    errors syscall
    ------ ----------- ----------- --------- --------- ----------------
    65.27    0.005545          33       166           write
    27.36    0.002324           0      3872           read
    4.91    0.000417         417         1           execve
    0.58    0.000049           4        12           rt_sigaction
    0.46    0.000039           6         6           mmap
    0.41    0.000035           8         4           mprotect
    0.20    0.000017          17         1           munmap
    0.20    0.000017           8         2           openat
    0.18    0.000015           5         3           fstat
    0.09    0.000008           2         4           close
    0.09    0.000008           4         2         1 arch_prctl
    0.08    0.000007           7         1         1 access
    0.06    0.000005           5         1           lseek
    0.06    0.000005           5         1         1 ioctl
    0.05    0.000004           4         1           brk
    ------ ----------- ----------- --------- --------- ----------------
    100.00    0.008495           2      4077         3 total

- strace -c pigz <$input >pigz.gz
    % time     seconds  usecs/call     calls    errors syscall
    ------ ----------- ----------- --------- --------- ----------------
    83.00    0.088814         110       804         3 futex
    16.53    0.017691          18       978           read
    0.26    0.000278          18        15           mprotect
    0.12    0.000124           5        22           munmap
    0.06    0.000063          12         5           clone
    0.03    0.000031           1        28           mmap
    0.01    0.000010           1         8           brk
    0.00    0.000000           0         6           close
    0.00    0.000000           0         6           fstat
    0.00    0.000000           0         3           lseek
    0.00    0.000000           0         3           rt_sigaction
    0.00    0.000000           0         1           rt_sigprocmask
    0.00    0.000000           0         2         2 ioctl
    0.00    0.000000           0         1         1 access
    0.00    0.000000           0         1           execve
    0.00    0.000000           0         2         1 arch_prctl
    0.00    0.000000           0         1           set_tid_address
    0.00    0.000000           0         6           openat
    0.00    0.000000           0         1           set_robust_list
    0.00    0.000000           0         1           prlimit64
    ------ ----------- ----------- --------- --------- ----------------
    100.00    0.107011          56      1894         7 total

- strace -c java Pigzj <$input >Pigzj.gz
    % time     seconds  usecs/call     calls    errors syscall
    ------ ----------- ----------- --------- --------- ----------------
    99.75    0.444009      148003         3         1 futex
    0.07    0.000316           5        56        45 openat
    0.04    0.000180           7        25           mmap
    0.03    0.000148           3        39        36 stat
    0.03    0.000148           8        17           mprotect
    0.02    0.000070           5        13           read
    0.01    0.000054           4        11           fstat
    0.01    0.000053           4        11           close
    0.01    0.000031          15         2           munmap
    0.00    0.000018          18         1           clone
    0.00    0.000014           4         3           lseek
    0.00    0.000014           3         4           brk
    0.00    0.000013           6         2           readlink
    0.00    0.000011           5         2         1 access
    0.00    0.000008           4         2           rt_sigaction
    0.00    0.000007           3         2           getpid
    0.00    0.000005           5         1           rt_sigprocmask
    0.00    0.000005           5         1           prlimit64
    0.00    0.000004           2         2         1 arch_prctl
    0.00    0.000004           4         1           set_tid_address
    0.00    0.000004           4         1           set_robust_list
    0.00    0.000000           0         1           execve
    ------ ----------- ----------- --------- --------- ----------------
    100.00    0.445116        2225       200        84 total

- strace -c ./pigzj <$input >pigzj.gz
    % time     seconds  usecs/call     calls    errors syscall
    ------ ----------- ----------- --------- --------- ------------------
    24.12    0.035142          24      1444           munmap
    22.17    0.032305          32      1009           read
    17.03    0.024816       24816         1           write
    14.72    0.021442           5      3761           nanosleep
    12.02    0.017511           5      2954           mmap
    8.81    0.012839         987        13           futex
    0.62    0.000907           1       491           sched_yield
    0.11    0.000158           3        42        12 lseek
    0.10    0.000152          38         4           clone
    0.08    0.000117           5        20           openat
    0.08    0.000116           3        35           fstat
    0.06    0.000082           3        22           close
    0.02    0.000025           8         3           socket
    0.02    0.000022           2         8           brk
    0.01    0.000021          10         2           getdents64
    0.01    0.000014           0        17           mprotect
    0.01    0.000014           2         6           rt_sigaction
    0.00    0.000005           5         1           setsockopt
    0.00    0.000005           1         3           sched_getaffinity
    0.00    0.000004           4         1         1 getsockname
    0.00    0.000000           0         2           rt_sigprocmask
    0.00    0.000000           0         1         1 access
    0.00    0.000000           0         1           execve
    0.00    0.000000           0         2         1 arch_prctl
    0.00    0.000000           0         1           set_tid_address
    0.00    0.000000           0         1           set_robust_list
    0.00    0.000000           0         6           prlimit64
    ------ ----------- ----------- --------- --------- ------------------
    100.00    0.145697          14      9851        15 total

According to the summary table, gzip program use a lot time on reading and writing. And, 
my implement of Pigzj waste over 99% of the time performing futex system call, which is
waiting for certain condition. It might be the part that the processor is waiting for 
the other to compress before it can start compress its block. Although I expect that the
time it takes on waiting processors should occupy the most of the total time, but I did 
not expect it that large so I believe there is some issue in my program. As mentioned 
above, my program satify all the condition on smaller files but it is not workling on 
those bigger files. There is some issue with my program to work on files with big size.
Also, if the number of thread scale up or the number of processor is over the number 
system have, the program is going to have a great performance. After comparing the 
performing time, summary table of tracing system calls, and the table of increasing 
processor affect on time, the pigz program worls better than others in general. 

