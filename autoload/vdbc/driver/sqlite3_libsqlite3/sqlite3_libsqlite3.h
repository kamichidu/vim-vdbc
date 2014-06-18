#ifndef VDBC_DRIVER_SQLITE3_LIBSQLITE3_H_
#define VDBC_DRIVER_SQLITE3_LIBSQLITE3_H_

#ifdef _WIN32
#  define VDBC_API __declspec(dllexport)
#else
#  define VDBC_API
#endif

extern "C"
{
    /**
     * initialize the dynamic library.
     * this function must to be called before using other functions.
     *
     * this function will returns a json below.
     *
     *   * success - if initialization succeeded to be 1, otherwise 0
     *   * handle  - a dynamic library handle.
     *               this key is only available when succeeded.
     *   * message - an error message.
     *               this key is only available when error occured.
     *
     * NOTE: this function must be called only once!
     *
     * \param libname [in] self library name.
     * \return a string that json object was serialized.
     */
    VDBC_API char const* const __cdecl vdbc_sqlite3_libsqlite3_initialize(char const* const libname);

    /**
     * terminate the dynamic library.
     * this function must to be called after using other functions.
     *
     * this function will returns a json below.
     *
     *   * success - if terminating succeeded to be 1, otherwise 0
     *   * message - an error message.
     *               this key is only available when error occured.
     *
     * NOTE: this function must be called only once!
     *
     * \param handle [in] a handle that was returned initialize().
     * \return a string that json object was serialized.
     */
    VDBC_API char const* const __cdecl vdbc_sqlite3_libsqlite3_terminate(char const* const handle);

    /**
     * create new connection for postgresql database.
     * connection info. will be passed as json.
     * valid keys are
     *
     *   * host - a host name
     *   * port - a port number
     *   * user - an username
     *   * password - a password
     *   * dbname - a database name
     *
     * this function will returns a json described below.
     *
     *   * id - connection id for other functions.
     *          this key is only available if connection succeeded.
     *   * success - if connection succeeded to be 1, otherwise 0
     *   * message - an error message.
     *               this key is only available if connection failed.
     *
     * \param json [in] a string that json object was serialized.
     * \return a string that json object was serialized.
     */
    VDBC_API char const* const __cdecl vdbc_sqlite3_libsqlite3_connect(char const* const json);

    /**
     * \param json [in] a string that json object was serialized.
     * \return a string that json object was serialized.
     */
    VDBC_API char const* const __cdecl vdbc_sqlite3_libsqlite3_execute(char const* const json);

    /**
     * \param json [in] a string that json object was serialized.
     * \return a string that json object was serialized.
     */
    VDBC_API char const* const __cdecl vdbc_sqlite3_libsqlite3_select_as_list(char const* const json);

    /**
     * \param json [in] a string that json object was serialized.
     * \return a string that json object was serialized.
     */
    VDBC_API char const* const __cdecl vdbc_sqlite3_libsqlite3_select_as_dict(char const* const json);

    /**
     * \param json [in] a string that json object was serialized.
     * \return a string that json object was serialized.
     */
    VDBC_API char const* const __cdecl vdbc_sqlite3_libsqlite3_disconnect(char const* const json);
}

#endif // VDBC_DRIVER_SQLITE3_LIBSQLITE3_H_
