CC=clang++
CFLAGS=-std=c++11 -Wall -O2 -fPIC --shared
LDFLAGS=-lpq -ldl

pg_libpq:
	${CC} ${CFLAGS} -o autoload/vdbc/driver/pg_libpq.so autoload/vdbc/driver/pg_libpq/pg_libpq.cpp ${LDFLAGS}
