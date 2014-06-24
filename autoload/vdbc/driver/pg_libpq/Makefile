CXX=clang++
CXXFLAGS=-std=c++11 -Wall -O2 -fPIC -shared
LDFLAGS=-lpq -ldl
TARGET=../../../../lib/pg_libpq.so
SRC=pg_libpq.cpp
INCDIR=
LIBDIR=

all: pg_libpq

pg_libpq:
	${CXX} ${CXXFLAGS} ${INCDIR} -o ${TARGET} ${SRC} ${LIBDIR} ${LDFLAGS}

clean:
	${RM} ${TARGET}
