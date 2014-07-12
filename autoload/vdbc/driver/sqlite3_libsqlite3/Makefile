CC=clang
CCFLAGS=-Wall -O2 -fPIC
CXX=clang++
CXXFLAGS=-std=c++11 -Wall -O2 -fPIC
LDFLAGS=-ldl
TARGET=../../../../lib/sqlite3_libsqlite3.so
OBJS=sqlite3_libsqlite3.o sqlite3.o
INCDIR=-I.
LIBDIR=

all: sqlite3_libsqlite3

sqlite3_libsqlite3: ${OBJS}
	${CXX} -fPIC -shared -o ${TARGET} ${OBJS} ${LIBDIR} ${LDFLAGS}

.c.o:
	${CC} ${CCFLAGS} ${INCDIR} -o $(<:%.c=%.o) -c $<

.cpp.o:
	${CXX} ${CXXFLAGS} ${INCDIR} -o $(<:%.cpp=%.o) -c $<

clean:
	${RM} ${TARGET} ${OBJS}
