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
#include "pg_libpq.h"

#include "picojson.h"
#include <libpq-fe.h>
#include <map>
#include <memory>
#include <utility>
#include <sstream>

#include <cstdlib>

#ifdef _WIN32
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

    static std::map<int, std::shared_ptr<PGconn>> connections;
}

char const* const initialize(char const* const libname)
{
    static std::string r;

#ifdef _WIN32
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

char const* const terminate(char const* const handle)
{
    static std::string r;

#ifdef _WIN32
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

char const* const connect(char const* const a)
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

    if(args.find("host") != args.end() && args["host"].is<std::string>())
    {
        conninfo << " host=" << args["host"].get<std::string>();
    }
    if(args.find("port") != args.end() && args["port"].is<double>())
    {
        conninfo << " port=" << static_cast<int>(args["port"].get<double>());
    }
    if(args.find("user") != args.end() && args["user"].is<std::string>())
    {
        conninfo << " user=" << args["user"].get<std::string>();
    }
    if(args.find("password") != args.end() && args["password"].is<std::string>())
    {
        conninfo << " password=" << args["password"].get<std::string>();
    }
    if(args.find("dbname") != args.end() && args["dbname"].is<std::string>())
    {
        conninfo << " dbname=" << args["dbname"].get<std::string>();
    }

    std::shared_ptr<PGconn> conn(PQconnectdb(conninfo.str().c_str()), [](PGconn* p){
        std::system("echo 'PQfinish()' >> log");
        if(p)
        {
            PQfinish(p);
            std::system("echo 'PQfinish() done' >> log");
        }
    });

    if(PQstatus(conn.get()) != CONNECTION_OK)
    {
        std::system("echo 'connect error' >> log");
        return (r= for_error(PQerrorMessage(conn.get()))).c_str();
    }

    int const id= generate_id();
    connections[id]= conn;

    json::object retobj;

    retobj["success"]= json::value(1.);
    retobj["id"]=      json::value(static_cast<double>(id));

    return (r= json::value(retobj).serialize()).c_str();
}

char const* const disconnect(char const* const a)
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
        json::object retobj;

        retobj["success"]= json::value(1.);

        return (r= json::value(retobj).serialize()).c_str();
    }
    else
    {
        return (r= for_error("unknown id")).c_str();
    }
}

char const* const select_as_list(char const* const a)
{
    // picojson::object args= parse_args(args_);
    // connection_manager::lp_connection conn= conn_man.connect(args["id"].get<int>(), args["conninfo"].get<std::string>());

    return nullptr;
}
