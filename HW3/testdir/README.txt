time gzip <$input >gzip.gz

    real    0m7.232s
    user    0m7.141s
    sys     0m0.057s

time pigz <$input >pigz.gz

    real    0m3.445s
    user    0m7.057s
    sys     0m0.090s

time java Pigzj <$input >Pigzj.gz

    real    0m7.620s
    user    0m14.007s
    sys     0m0.369s

time ./pigzj <$input >pigzj.gz

    real    0m8.192s
    user    0m14.184s
    sys     0m0.361s

ls -l gzip.gz pigz.gz Pigzj.gz pigzj.gz

    -rw-r--r-- 1 jenggang csugrad 43476941 May  9 00:26 gzip.gz
    -rw-r--r-- 1 jenggang csugrad 43351345 May  9 00:27 pigz.gz
    -rw-r--r-- 1 jenggang csugrad 44228917 May  9 00:29 pigzj.gz
    -rw-r--r-- 1 jenggang csugrad 44240076 May  9 00:27 Pigzj.gz

gzip -d <Pigzj.gz | cmp - $input

    - /usr/local/cs/jdk-17.0.2/lib/modules differ: byte 131073, line 72

gzip -d <pigzj.gz | cmp - $input

    - /usr/local/cs/jdk-17.0.2/lib/modules differ: byte 131073, line 72

