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
using System.Net;
using System.Net.Sockets;
using System.Diagnostics;
using System.Security.Permissions;
using System.Xml;
using System.Threading;
using CommandProxy;
using System.IO;
using CommandProxy.Commands;

namespace CommandProxy
{
    /// <summary>
    ///     Provides a proxy between a remote application and 
    ///     expanded desktop functionality.
    /// </summary>
	public class CommandProxy
	{
        //the network stream used to communicate with the remote application
		private NetworkStream stream;

        //callback when data is sent on the stream
		private AsyncCallback readCallback;

        //callback when data is written to stream
		private AsyncCallback writeCallback;

        //buffer used to read and write data to and from the stream
		private byte[] buffer;

        //socket used to communicate with remote application
		private Socket client;

        //whether an authorization token is required. If this is set to
        //true, then when the remote application is launched by proxy
        //it will be passed a token, which must present in any communication
        //with the proxy (otherwise messages are ignored).
        private bool requireAuthToken = true;

        //the authorization token
        private string authToken;

        //the port that the proxy will listen on for incoming connections
        private int port;

        /// <summary>
        ///     Constructor
        /// </summary>
        /// <param name="port">The port to use for incoming connections</param>
        /// <param name="requireAuthToken">Whether or not an authorization token should
        /// be required to communicate with the proxy</param>
        public CommandProxy(bool requireAuthToken, int port)
        {
            //generator
            if (requireAuthToken)
            {
                authToken = GenerateAuthToken();
            }

            this.port = port;
        }

        /// <summary>
        ///     Constructor
        /// </summary>
        /// <param name="requireAuthToken">Whether or not an authorization token should
        /// be required to communicate with the proxy</param>
        public CommandProxy(bool requireAuthToken)
        {
            this.requireAuthToken = requireAuthToken;

            //find an avaliable port
            port = FindAvaliablePort();
        }

        /// <summary>
        ///     Find a tcp port that is not in use and that can be used
        ///     by the proxy
        /// </summary>
        /// <returns>A port number that can be used by the proxy</returns>
        private int FindAvaliablePort()
        {
            //todo : we need to loop through and make sure we can
            //use the port
            return 10000;
        }

        /// <summary>
        ///     API to start the proxy run cycle, and the launch the application
        ///     that will connect back to it (passing the port and authToken if required)
        /// </summary>
        /// <param name="processPath">The file path of the application to be launched
        /// that will connect back to the proxys</param>
        public void LaunchAndRun(string processPath)
        {
            //start the run loop
            Run();

            //todo: impliment LaunchApp api
            //launch application
            //LaunchApp();
        }

        /// <summary>
        ///     Starts run loop for proxy. Loop will run until a connection is made
        ///     and the disconnected.
        /// 
        ///     It will only allow a single connection from the local machine. Once that
        ///     connection is dropped or closed, the run loop will return and exit.
        /// </summary>
		public void Run()
		{

            //initialize buffer. We use 1024, as otherwise messages where being split up which
            //made them difficult to work with
            //todo: fix this so buffer size doesnt matter
			buffer  = new byte[1024];
		
            //create a SocketPermission instance to set permissions on socket. No permissions by default
			SocketPermission sPermission = new SocketPermission(PermissionState.None);

            //allow connections ONLY from localhost, via TCP, and the specified port
			sPermission.AddPermission(NetworkAccess.Accept, TransportType.Tcp, "127.0.0.1", port);

            //bind to the local address
            IPAddress localAddr = IPAddress.Parse("127.0.0.1");

            //create a tcpListener on the local address and specified port to listen
            //for incoming connections
			TcpListener tcpListener = new TcpListener(localAddr, port);

            //start listening
			tcpListener.Start();
		
            //wait for first connection. The method blocks until a connection is
            //received
			client = tcpListener.AcceptSocket();

            //create a network stream to communicate with the client
			stream = new NetworkStream(client);
		
            //set the read call back for when data comes in on stream
	        readCallback = new AsyncCallback(this.onStreamRead);

            //set the write call back for when data is written to stream
	        writeCallback = new AsyncCallback(this.onStreamWrite);		
		
            //make sure client is connected
			if(client.Connected)
			{
                //start listening on the socket
                Listen();
				
                //start infinite loop. We do this so we can check for connection
                //and exit the run loop if the connection is dropped
				for(;;)
				{					
                    //make sure we are still connected to the client
					if(client == null || !client.Connected)
					{
                        //if not, exit run loop
						return;
					}
					
                    //sleep for 100 milliseconds. We do this so the loop doesnt
                    //run as fast as possible and eat up CPU unecessarily
					Thread.Sleep(100);
				}
			}
		}

        /// <summary>
        ///     Generates an authorization token
        /// </summary>
        /// <returns>a string based authorization token</returns>
        private string GenerateAuthToken()
        {
            return System.Guid.NewGuid().ToString();
        }
	
        /// <summary>
        ///     Callback handler called asyncronously when data is received on the
        ///     network stream from the client
        /// </summary>
        /// <param name="ar">The IAsyncResult with infomation about the data written to
        ///     the stream</param>
		private void onStreamRead(IAsyncResult ar)
		{
            //number of bytes read from the stream
            int bytesRead;
            try
            {
                //read the bytes from the stream
                bytesRead = stream.EndRead(ar);
            }
            catch (IOException)
            {
                //if anything goes wrong, just return
                return;
            }

            //if we read some bytes
		    if( bytesRead > 0 )
		    {
                //convert the bytes to a string (since that is what is being sent to and from
                //the client)
		      	string msg = System.Text.Encoding.ASCII.GetString(buffer, 0, bytesRead);

                //write out message to Console (this is temp for development)
		      	Console.WriteLine( msg );
	
                //check that the message is a valid message
				if(!IsValidMessage(msg))
				{
                    //if not, write an error to the client and return
					Console.WriteLine("Invalid Message Format");
                    Write(CreateErrorDocument("Invalid Message Format").OuterXml);
					//right now, just ignore invalid messages
					return;
				}
	
                //check if the client is authorized to communicate with proxy
                if(!IsAuthorized(msg))
                {
                    //if not, write an error to the client and return
					Console.WriteLine("Message Not Authorized");
                    Write(CreateErrorDocument("Message Not Authorized").OuterXml);

                    //todo: should we disconnect the client here?

					return;
                }

                //pass the message to be handled by the proxy.
                //capture the output
				string response = HandleMessage(msg);
			
                //check if response is null
				if(response == null)
				{
                    //todo: is this necessary?

					//todo: dont send response?

                    //write an error to the client and return
                    Write(CreateErrorDocument("Command not recognized.").OuterXml);

                    return;
				}
	
                //write the response from the command to the client
				Write(response);
		    }
		    else
		    {
                //if stream is empty, exit
                //todo: why do we exit here? What does empty stream represent?
				Quit();
		    }
		}
		
        //todo: do we need to authorize every call? or just the first one
        //and then authorize the client?
        /// <summary>
        ///     Returns whether the received command is authorized to be 
        ///     executed.
        /// </summary>
        /// <param name="msg">The raw message from the client</param>
        /// <returns>a bool indicating whether the command is authorized to be executed.</returns>
        private bool IsAuthorized(string msg)
        {
            //if auth tokens are not required
            if(!requireAuthToken)
            {
                //authorize command
                return true;
            }

            //parse msg into XML
            //todo: should we catch parsing error here
			XmlDocument xml = new XmlDocument();
			xml.LoadXml(msg);

            //get acces to the authtoken attribute
            XmlAttribute tokenAttribute = xml.FirstChild.Attributes["authtoken"];

            //if it doesnt exist
            if (tokenAttribute == null)
            {
                //dont authorize
                return false;
            }

            //get token value
            string aToken = tokenAttribute.Value;

            //return true if it matches auth token, false if it does not
            return (aToken.CompareTo(authToken) == 0);
        }

        /// <summary>
        ///     Writes the specified string to the network stream to send
        ///     to the client
        /// </summary>
        /// <param name="s">The string to write to the stream</param>
		private void Write(string s)
		{
            //convert the string to a bytearray
			byte [] outMsg = StringToByteArray(s);

            //write bytearray to the stream
	       	stream.BeginWrite(outMsg, 0, outMsg.Length, writeCallback, null);
		}
		
        /// <summary>
        ///     Listen for incoming messages from the stream.
        /// </summary>
		private void Listen()
		{
            //read from the stream (event will be broadcast when data is avaliable)
			stream.BeginRead(buffer, 0, buffer.Length, readCallback, null);
		}
	
        /// <summary>
        ///     Event handler called when data is written to the stream
        /// </summary>
        /// <param name="ar"></param>
		private void onStreamWrite(IAsyncResult ar)
		{
	    	stream.EndWrite(ar);

            //listen for incoming data
	    	Listen();
		}
	
        /// <summary>
        ///     Converts a string to a bytearray
        /// </summary>
        /// <param name="s">The string to be converted to bytearray</param>
        /// <returns>A bytearray with representing the specified string</returns>
		private byte[] StringToByteArray(string s)
		{
	 		System.Text.ASCIIEncoding  encoding = new System.Text.ASCIIEncoding();
		    return encoding.GetBytes(s);	
		}
	
        /// <summary>
        ///     Take a string and returns a bool indicating whether the string is
        ///     in the correct message format (in this case XML)
        /// </summary>
        /// <param name="s">The messgae to be checked</param>
        /// <returns>a bool indicating is the message is in the correct format.</returns>
		private bool IsValidMessage(string s)
		{
			XmlDocument xml = new XmlDocument();
		
            //basically, just check that it is well formed XML.
			try
			{
				xml.LoadXml(s);
			}
			catch(Exception)
			{
				return false;
			}
		
			return true;
		}
	
        /// <summary>
        ///     Parses, validates and dispatches messages from the client
        /// </summary>
        /// <param name="s">The raw message sent from the client</param>
        /// <returns>the response to be returned to the client</returns>
		private string HandleMessage(string s)
		{
            //parse the request from the client into an XML document
			XmlDocument requestDocument = new XmlDocument();

            //load the message into the document
            requestDocument.LoadXml(s);

            //get a reference to the command element node.
            XmlNode commandNode = requestDocument.SelectSingleNode("/command");

            //check that there is a command element
            if (commandNode == null)
            {
                //if not, the message is formatted wrong and we cant recognize it.
                //return an error message to send to the client
                return CreateErrorDocument("Input not recognized").OuterXml;
            }

            //create an XMLDocument to hold to response to be sent back to the client
            XmlDocument responseDocument = new XmlDocument();

            //create the top level response element
            XmlNode responseElement = responseDocument.CreateNode(XmlNodeType.Element, "response", "");

            //add the response element to the response document
            responseDocument.AppendChild(responseElement);

            //get the id for the command
            string id = ExtractId(commandNode);

            //create a new attribute named id
            XmlAttribute idAttribute = responseDocument.CreateAttribute("id");

            //set its value to the request id
            idAttribute.Value = id;

            //add the new id element to the response id
            responseElement.Attributes.SetNamedItem(idAttribute);


            //get child nodes from the request document. Each one should
            //represent a command (there should be only one)
			XmlNodeList children = commandNode.ChildNodes;
		
            //IProxyCommand that contains the command sent from the client
			IProxyCommand command = null;

            //attribute tha holds response type
            XmlAttribute typeAttribute = responseDocument.CreateAttribute("type");
		
            //loop through all of the command nodes (usually only one)
			foreach (XmlNode node in children)
			{
                //look at the node name. This will indicate the command
				switch(node.Name)
				{
                    //exececute command
					case "exec":
					{
                        //create a new ExecCommand instance
						command = new ExecCommand();

                        //try and run the command
                        try
                        {
                            //pass in the response and request document, capture the response document
                            //with output from the command included
                            responseDocument = command.Exec(requestDocument, responseDocument);

                            //set the type attribute to success
                            typeAttribute.Value = "success";

                            //add the type attribute to the response document
                            responseDocument.FirstChild.Attributes.SetNamedItem(typeAttribute);

                            //return a string of XML representing the response document to send to
                            //the client
                            return responseDocument.OuterXml;
                        }
                        catch (Exception e)
                        {
                            //something went wrong, create error document and send its xml to the client
                            return CreateErrorDocument(e.Message, id).OuterXml;
                        }
					}
                    //screenshot command
                    case "screenshot":
                    {
                        //create the screenshot command
                        command = new ScreenshotCommand();

                        try
                        {
                            //pass in the response and request document, capture the response document
                            //with output from the command included
                            responseDocument = command.Exec(requestDocument, responseDocument);

                            //set the type attribute to success
                            typeAttribute.Value = "success";

                            //add the type attribute to the response document
                            responseDocument.FirstChild.Attributes.SetNamedItem(typeAttribute);

                            //return a string of XML representing the response document to send to
                            //the client
                            return responseDocument.OuterXml;
                        }
                        catch (Exception e)
                        {
                            //something went wrong, create error document and send its xml to the client
                            return CreateErrorDocument(e.Message, id).OuterXml;
                        }
                    }
				}
			}

            //if we get to here we didnt recognize the command, so we just return null
            //todo: should this move to switch defaul
            //todo: should be through an error?
			return null;
		}

        /// <summary>
        /// Extra the request id from the specified XmlNode
        /// </summary>
        /// <param name="commandNode">The node that contains the id parameter</param>
        /// <returns>the id for the request</returns>
        private string ExtractId(XmlNode commandNode)
        {
            //get the id attrbute from the node
            XmlAttribute idAt = commandNode.Attributes["id"];

            string id = null;

            //check and see if the attribute existed
            if (idAt != null)
            {
                //get the id
                id = idAt.Value;
            }

            //return the id
            return id;
        }

        /// <summary>
        ///  Closes the stream. The will cause the run loop to exit (although not immediately)
        /// </summary>
		public void Quit()
		{
            //close the stream
			stream.Close(  );

            //close the client connection
			client.Close(  );

            //reset stream and client
			stream = null;
			client = null;
		}
        /// <summary>
        ///     Takes an error message and returns an XmlDocument representing 
        ///     an error message to send back to the client
        /// </summary>
        /// <param name="msg">The error message</param>
        /// <returns>XmlDocument representing the error message and condition</returns>
        public XmlDocument CreateErrorDocument(string msg)
        {
            //create the stub string of xml
            string outXml = "<response type=\"error\"><message>" + msg + "</message></response>";

            //read the string into an XmlTextReader
            XmlTextReader xmlReader = new XmlTextReader(new StringReader(outXml));

            //create a new XmlDocument
            XmlDocument xmlDocument = new XmlDocument();

            //append the error xml message to the XmlDocumet
            xmlDocument.AppendChild(xmlDocument.ReadNode(xmlReader));

            //return the XmlDocument
            return xmlDocument;
        }

        /// <summary>
        ///     Takes an error message and returns an XmlDocument representing 
        ///     an error message to send back to the client.
        /// </summary>
        /// <param name="msg">The error message</param>
        /// <param name="id">The command / request id to be associated with the error</param> 
        /// <returns>XmlDocument representing the error message and condition</returns>
        public XmlDocument CreateErrorDocument(string msg, string id)
		{
            //create the error XmlDocument
            XmlDocument errorResponse = CreateErrorDocument(msg);

            //check if id is specified
            if (id == null)
            {
                //if not, return error document
                return errorResponse;
            }

            //create the id attribute
            XmlAttribute idAttribute = errorResponse.CreateAttribute("id");

            //add the value to the id attribute
            idAttribute.Value = id;

            //attach the id attribute to the root of the XmlDocument
            errorResponse.FirstChild.Attributes.SetNamedItem(idAttribute);

            //return the error XmlDocument
            return errorResponse;
		}
	}
}
