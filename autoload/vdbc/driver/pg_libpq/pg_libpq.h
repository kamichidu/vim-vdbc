// The MIT License (MIT)
//
// Copyright (c) 2014 kamichidu
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
#ifndef VDBC_DRIVER_PG_LIBPQ_H_
#define VDBC_DRIVER_PG_LIBPQ_H_

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
    VDBC_API char const* const __cdecl vdbc_pg_libpq_initialize(char const* const libname);

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
    VDBC_API char const* const __cdecl vdbc_pg_libpq_terminate(char const* const handle);

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
    VDBC_API char const* const __cdecl vdbc_pg_libpq_connect(char const* const json);

    /**
     * \param json [in] a string that json object was serialized.
     * \return a string that json object was serialized.
     */
    VDBC_API char const* const __cdecl vdbc_pg_libpq_prepare(char const* const json);

    /**
     * \param json [in] a string that json object was serialized.
     * \return a string that json object was serialized.
     */
    VDBC_API char const* const __cdecl vdbc_pg_libpq_deallocate(char const* const json);

    /**
     * \param json [in] a string that json object was serialized.
     * \return a string that json object was serialized.
     */
    VDBC_API char const* const __cdecl vdbc_pg_libpq_execute(char const* const json);

    /**
     * \param json [in] a string that json object was serialized.
     * \return a string that json object was serialized.
     */
    VDBC_API char const* const __cdecl vdbc_pg_libpq_select_as_list(char const* const json);

    /**
     * \param json [in] a string that json object was serialized.
     * \return a string that json object was serialized.
     */
    VDBC_API char const* const __cdecl vdbc_pg_libpq_select_as_dict(char const* const json);

    /**
     * \param json [in] a string that json object was serialized.
     * \return a string that json object was serialized.
     */
    VDBC_API char const* const __cdecl vdbc_pg_libpq_disconnect(char const* const json);
}

#endif // VDBC_DRIVER_PG_LIBPQ_H_
