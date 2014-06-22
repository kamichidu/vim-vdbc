all: pg_libpq sqlite3_libsqlite3

pg_libpq:
	make -C autoload/vdbc/driver/pg_libpq/

sqlite3_libsqlite3:
	make -C autoload/vdbc/driver/sqlite3_libsqlite3/

clean:
	make -C autoload/vdbc/driver/pg_libpq/ clean
	make -C autoload/vdbc/driver/sqlite3_libsqlite3/ clean
