CXX=clang++
CXXFLAGS=-std=c++11 -Wall -O2 -fPIC -shared
LDFLAGS=-lsqlite3 -ldl
TARGET=../../../../lib/sqlite3_libsqlite3.so
SRC=sqlite3_libsqlite3.cpp
INCDIR=
LIBDIR=

all: sqlite3_libsqlite3

sqlite3_libsqlite3:
	${CXX} ${CXXFLAGS} ${INCDIR} -o ${TARGET} ${SRC} ${LIBDIR} ${LDFLAGS}

clean:
	${RM} ${TARGET}
