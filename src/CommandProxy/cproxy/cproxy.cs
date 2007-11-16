/*
    The MIT License

    Copyright (c) 2007 Mike Chambers

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
*/

using System;
using CommandProxy;

/// <summary>
///     command line appliction for launching CommandProxy
/// </summary>
public class cproxy
{
    /// <summary>
    ///     main entry point for command line application
    /// </summary>
    public static void Main(string[] args)
    {
        string path = null;
        bool requireAuthToken = false;

        if (args.Length > 0)
        {
            requireAuthToken = true;
            path = args[0];
        }

        //create a new instance of the command proxy
        CommandProxy.CommandProxy proxy;
        if (path == null)
        {
            //hard code port
            int port = 10000;

            Console.WriteLine("Launching Proxy : auth:" + requireAuthToken + " port:" + port);
            proxy = new CommandProxy.CommandProxy(requireAuthToken, port);
            proxy.Run();
        }
        else
        {
            try
            {
                proxy = new CommandProxy.CommandProxy(requireAuthToken);

                Console.WriteLine("launching app : " + path);

                //todo: should we verify path?
                proxy.LaunchAndRun(path);
            }
            catch(Exception e)
            {
                Console.WriteLine("Could not start proxy : " + e.Message);
                return;
            }
        }

        //start the run loop, passing in the port to use, and whether an auth
        //token should be used
        //proxy.Run();
    }
}