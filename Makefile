CC=clang++
CFLAGS=-std=c++11 -Wall -O2 -fPIC --shared
LDFLAGS=-lpq -ldl

pg_libpq:
	${CC} ${LDFLAGS} -o pg_libpq.so ${CFLAGS} autoload/vdbc/driver/pg_libpq/pg_libpq.cpp
