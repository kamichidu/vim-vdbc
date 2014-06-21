#include "sqlite3_libsqlite3.h"

#include "picojson.h"
#include <sqlite3.h>
#include <map>
#include <memory>
#include <utility>
#include <sstream>
#include <stdint.h>
#include <cstdlib>
#include <fstream>

#ifdef _WIN32
#  include <windows.h>
#else
#  include <dlfcn.h>
#endif

namespace
{
    namespace json= picojson;

    std::pair<json::object, std::string> const parse_json(std::string const& json)
    {
        typedef std::pair<json::object, std::string> return_type;

        json::value root;
        std::string error;

        json::parse(root, json.begin(), json.end(), &error);

        if(root.is<json::object>())
        {
            return return_type(root.get<json::object>(), error);
        }
        else
        {
            return return_type(json::object(), "it's not a object type");
        }
    }

    int const generate_id()
    {
        static int current_id= 0;

        return ++current_id;
    }

    std::string const for_error(std::string const& message)
    {
        json::object obj;

        obj["success"]= json::value(0.);
        obj["message"]= json::value(message);

        return json::value(obj).serialize();
    }

    std::string const ptr2str(void const* const p)
    {
        std::stringstream ss;

        ss << p;

        return ss.str();
    }

    void* const str2ptr(std::string const& s)
    {
        std::stringstream ss(s);
        void* p;

        ss >> p;

        return p;
    }

    bool bind_values_to_statement(std::shared_ptr<sqlite3_stmt> stmt, json::array const& values)
    {
        {
            int const result= sqlite3_clear_bindings(stmt.get());
            switch(result)
            {
                case SQLITE_OK:
                    break;
                default:
                    return false;
            }
        }

        int const nparams= sqlite3_bind_parameter_count(stmt.get());
        for(int idx= 0; idx < nparams; ++idx)
        {
            if(idx < values.size())
            {
                json::value const value= values.at(idx);

                if(value.is<std::string>())
                {
                    std::string const s= value.get<std::string>();

                    sqlite3_bind_text(stmt.get(), idx + 1, s.c_str(), s.length(), SQLITE_TRANSIENT);
                }
                else if(value.is<double>())
                {
                    sqlite3_bind_double(stmt.get(), idx + 1, value.get<double>());
                }
                else
                {
                    sqlite3_bind_null(stmt.get(), idx + 1);
                }
            }
        }

        return true;
    }

    static std::map<int, std::shared_ptr<sqlite3_stmt>> statements;
    static std::map<int, std::shared_ptr<sqlite3>> connections;
}

char const* const vdbc_sqlite3_libsqlite3_initialize(char const* const libname)
{
    static std::string r;

#ifdef _WIN32
    void* handle= LoadLibrary(libname);
#else
    void* handle= dlopen(libname, RTLD_NOW);

    if(!handle)
    {
        return (r= for_error(dlerror())).c_str();
    }
#endif

    json::object retobj;

    retobj["success"]= json::value(1.);
    retobj["handle"]=  json::value(ptr2str(handle));

    return (r= json::value(retobj).serialize()).c_str();
}

char const* const vdbc_sqlite3_libsqlite3_terminate(char const* const handle)
{
    static std::string r;

#ifdef _WIN32
    void* p= str2ptr(handle);

    FreeLibrary(static_cast<HMODULE>(p));
#else
    void* p= str2ptr(handle);

    if(!p)
    {
        return (r= for_error("null handle")).c_str();
    }

    if(dlclose(p) != 0)
    {
        return (r= for_error(dlerror())).c_str();
    }
#endif

    json::object retobj;

    retobj["success"]= json::value(1.);

    return (r= json::value(retobj).serialize()).c_str();
}

char const* const vdbc_sqlite3_libsqlite3_connect(char const* const a)
{
    static std::string r;

    json::object args;
    {
        std::pair<json::object, std::string> const parsed= parse_json(a);

        if(!parsed.second.empty())
        {
            return (r= for_error(parsed.second)).c_str();
        }

        args= parsed.first;
    }

    std::stringstream conninfo;

    if(args.find("dbname") != args.end() && args["dbname"].is<std::string>())
    {
        conninfo << args["dbname"].get<std::string>();
    }

    sqlite3* pconn= nullptr;
    int result= sqlite3_open_v2(conninfo.str().c_str(), &pconn,
        SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_READWRITE |
        SQLITE_OPEN_CREATE | SQLITE_OPEN_URI,
        nullptr);
    if (result != 0) {
        return (r= for_error(sqlite3_errmsg(pconn))).c_str();
    }
    if (pconn == nullptr) {
        return (r= for_error("sqlite succeeded without returning a database")).c_str();
    }
    std::shared_ptr<sqlite3> conn(pconn, [](sqlite3* p){
        if(p) {
            sqlite3_close(p);
        }
    });

    int const id= generate_id();
    connections[id]= conn;

    json::object retobj;

    retobj["success"]= json::value(1.);
    retobj["id"]=      json::value(static_cast<double>(id));

    return (r= json::value(retobj).serialize()).c_str();
}

char const* const vdbc_sqlite3_libsqlite3_disconnect(char const* const a)
{
    static std::string r;

    json::object args;
    {
        std::pair<json::object, std::string> const parsed= parse_json(a);

        if(!parsed.second.empty())
        {
            return (r= for_error(parsed.second)).c_str();
        }

        args= parsed.first;
    }

    int const id= static_cast<int>(args["id"].get<double>());
    if(connections.find(id) != connections.end())
    {
        connections.erase(id);

        json::object retobj;

        retobj["success"]= json::value(1.);

        return (r= json::value(retobj).serialize()).c_str();
    }
    else
    {
        return (r= for_error("unknown id")).c_str();
    }
}

char const* const vdbc_sqlite3_libsqlite3_prepare(char const* const a)
{
    static std::string r;

    json::object args;
    {
        std::pair<json::object, std::string> const parsed= parse_json(a);

        if(!parsed.second.empty())
        {
            return (r= for_error(parsed.second)).c_str();
        }

        args= parsed.first;
    }

    int const id= static_cast<int>(args["id"].get<double>());
    if(connections.find(id) == connections.end())
    {
        return (r= for_error("unknown id")).c_str();
    }
    std::shared_ptr<sqlite3> const conn= connections.at(id);

    std::string const query= args["query"].get<std::string>();

    sqlite3_stmt* pstmt= nullptr;
    const char* tail= nullptr;
    int result= sqlite3_prepare_v2(conn.get(), query.c_str(), -1, &pstmt, &tail);
    if (result != 0) {
        return (r= for_error(sqlite3_errmsg(conn.get()))).c_str();
    }
    result= sqlite3_reset(pstmt);
    if (result != SQLITE_ROW && result != SQLITE_OK && result != SQLITE_DONE) {
        return (r= for_error(sqlite3_errmsg(conn.get()))).c_str();
    }
    std::shared_ptr<sqlite3_stmt> stmt(pstmt, [](sqlite3_stmt* p){
        if(p)
        {
            sqlite3_finalize(p);
        }
    });

    int const statement_id= generate_id();
    statements[statement_id]= stmt;

    json::object retobj;

    retobj["success"]=      json::value(1.);
    retobj["statement_id"]= json::value(static_cast<double>(statement_id));

    return (r= json::value(retobj).serialize()).c_str();
}

char const* const vdbc_sqlite3_libsqlite3_deallocate(char const* const a)
{
    static std::string r;

    json::object args;
    {
        std::pair<json::object, std::string> const parsed= parse_json(a);

        if(!parsed.second.empty())
        {
            return (r= for_error(parsed.second)).c_str();
        }

        args= parsed.first;
    }

    int const statement_id= static_cast<int>(args["statement_id"].get<double>());
    if(statements.find(statement_id) != statements.end())
    {
        statements.erase(statement_id);

        json::object retobj;

        retobj["success"]= json::value(1.);

        return (r= json::value(retobj).serialize()).c_str();
    }
    else
    {
        return (r= for_error("unknown statement id")).c_str();
    }
}

char const* const vdbc_sqlite3_libsqlite3_execute(char const* const a)
{
    static std::string r;

    json::object args;
    {
        std::pair<json::object, std::string> const parsed= parse_json(a);

        if(!parsed.second.empty())
        {
            return (r= for_error(parsed.second)).c_str();
        }

        args= parsed.first;
    }

    int const statement_id= static_cast<int>(args["statement_id"].get<double>());
    if(statements.find(statement_id) == statements.end())
    {
        return (r= for_error("unknown statement id")).c_str();
    }
    std::shared_ptr<sqlite3_stmt> stmt= statements.at(statement_id);

    if(!stmt)
    {
        return (r= for_error("prepared statement is not found")).c_str();
    }

    {
        int const result= sqlite3_reset(stmt.get());
        switch(result)
        {
            case SQLITE_OK:
                break;
            default:
                return (r= for_error(sqlite3_errmsg(sqlite3_db_handle(stmt.get())))).c_str();
        }
    }

    if(!bind_values_to_statement(stmt, args["bind_values"].get<json::array>()))
    {
        return (r= for_error("failed to bind values")).c_str();
    }

    while(1)
    {
        int const result = sqlite3_step(stmt.get());
        switch(result)
        {
            case SQLITE_DONE:
                goto leave_while;
            case SQLITE_ROW:
            case SQLITE_OK:
                break;
            default:
                return (r= for_error(sqlite3_errmsg(sqlite3_db_handle(stmt.get())))).c_str();
        }
    }
leave_while:

    json::object retobj;

    retobj["success"]= json::value(1.);

    return (r= json::value(retobj).serialize()).c_str();
}

char const* const vdbc_sqlite3_libsqlite3_select_as_list(char const* const a)
{
    static std::string r;

    json::object args;
    {
        std::pair<json::object, std::string> const parsed= parse_json(a);

        if(!parsed.second.empty())
        {
            return (r= for_error(parsed.second)).c_str();
        }

        args= parsed.first;
    }

    int const statement_id= static_cast<int>(args["statement_id"].get<double>());
    if(statements.find(statement_id) == statements.end())
    {
        return (r= for_error("unknown statement id")).c_str();
    }
    std::shared_ptr<sqlite3_stmt> stmt= statements.at(statement_id);

    if(!stmt)
    {
        return (r= for_error("prepared statement is not found")).c_str();
    }

    {
        int const result= sqlite3_reset(stmt.get());
        switch(result)
        {
            case SQLITE_OK:
                break;
            default:
                return (r= for_error(sqlite3_errmsg(sqlite3_db_handle(stmt.get())))).c_str();
        }
    }

    if(!bind_values_to_statement(stmt, args["bind_values"].get<json::array>()))
    {
        return (r= for_error("failed to bind values")).c_str();
    }

    int const nfields= sqlite3_column_count(stmt.get());
    json::array tuples;
    while(1)
    {
        int const result = sqlite3_step(stmt.get());
        switch(result)
        {
            case SQLITE_DONE:
                goto leave_while;
            case SQLITE_ROW:
            case SQLITE_OK:
                break;
            default:
                return (r= for_error(sqlite3_errmsg(sqlite3_db_handle(stmt.get())))).c_str();
        }

        json::array fields;
        for(int col= 0; col < nfields; ++col)
        {
            std::string const value(reinterpret_cast<char const*>(sqlite3_column_text(stmt.get(), col)));

            fields.push_back(json::value(value));
        }
        tuples.push_back(json::value(fields));
    }
leave_while:

    json::object retobj;

    retobj["success"]= json::value(1.);
    retobj["result"]=  json::value(tuples);

    return (r= json::value(retobj).serialize()).c_str();
}

char const* const vdbc_sqlite3_libsqlite3_select_as_dict(char const* const a)
{
    static std::string r;

    json::object args;
    {
        std::pair<json::object, std::string> const parsed= parse_json(a);

        if(!parsed.second.empty())
        {
            return (r= for_error(parsed.second)).c_str();
        }

        args= parsed.first;
    }

    int const id= static_cast<int>(args["id"].get<double>());
    if(connections.find(id) == connections.end())
    {
        return (r= for_error("unknown id")).c_str();
    }
    std::shared_ptr<sqlite3> const conn= connections.at(id);

    int const statement_id= static_cast<int>(args["statement_id"].get<double>());
    if(statements.find(statement_id) == statements.end())
    {
        return (r= for_error("unknown statement id")).c_str();
    }
    std::shared_ptr<sqlite3_stmt> stmt= statements.at(statement_id);

    if(!stmt)
    {
        return (r= for_error("prepared statement is not found")).c_str();
    }

    {
        int const result= sqlite3_reset(stmt.get());
        switch(result)
        {
            case SQLITE_OK:
                break;
            default:
                return (r= for_error(sqlite3_errmsg(sqlite3_db_handle(stmt.get())))).c_str();
        }
    }

    if(!bind_values_to_statement(stmt, args["bind_values"].get<json::array>()))
    {
        return (r= for_error("failed to bind values")).c_str();
    }

    int const nfields= sqlite3_column_count(stmt.get());
    json::array tuples;
    while(1)
    {
        int const result = sqlite3_step(stmt.get());
        switch(result)
        {
            case SQLITE_DONE:
                goto leave_while;
            case SQLITE_ROW:
            case SQLITE_OK:
                break;
            default:
                return (r= for_error(sqlite3_errmsg(sqlite3_db_handle(stmt.get())))).c_str();
        }

        json::object fields;
        for(int col= 0; col < nfields; ++col)
        {
            std::string const label(sqlite3_column_name(stmt.get(), col));
            std::string const value(reinterpret_cast<char const*>(sqlite3_column_text(stmt.get(), col)));

            fields[label]= json::value(value);
        }

        tuples.push_back(json::value(fields));
    }
leave_while:

    json::object retobj;

    retobj["success"]= json::value(1.);
    retobj["result"]=  json::value(tuples);

    return (r= json::value(retobj).serialize()).c_str();
}
