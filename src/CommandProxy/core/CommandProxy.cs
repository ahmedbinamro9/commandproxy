using System;using System.Net;using System.Net.Sockets;using System.Diagnostics;using System.Security.Permissions;using System.Xml;using System.Threading;using CommandProxy;using System.IO;using CommandProxy.Commands;namespace CommandProxy{	public class CommandProxy	{		private NetworkStream stream;		private AsyncCallback readCallback;		private AsyncCallback writeCallback;		private byte[] buffer;		private Socket client;        private bool requireAuthToken = true;        private string authToken;        public CommandProxy()        {            authToken = GenerateAuthToken();        }        public void LaunchAndRun(int port, bool requireAuthToken, string processPath)        {            Run(port, requireAuthToken);            //launch app here, pass port and auth token        }		public void Run(int port, bool requireAuthToken)		{            this.requireAuthToken = requireAuthToken;			buffer  = new byte[1024];					SocketPermission sPermission = new SocketPermission(PermissionState.None);			sPermission.AddPermission(NetworkAccess.Accept, TransportType.Tcp, "127.0.0.1", port);            IPAddress localAddr = IPAddress.Parse("127.0.0.1");			TcpListener tcpListener = new TcpListener(localAddr, port);			tcpListener.Start();					client = tcpListener.AcceptSocket();			stream = new NetworkStream(client);			        readCallback = new AsyncCallback(this.onStreamRead);	        writeCallback = new AsyncCallback(this.onStreamWrite);							if(client.Connected)			{				StartRead();								for(;;)				{										if(client == null || !client.Connected)					{						return;					}										Thread.Sleep(100);				}			}		}        private string GenerateAuthToken()        {            return System.Guid.NewGuid().ToString();        }	    private void StartRead(  )	    {	       Listen();	    }				private void onStreamRead(IAsyncResult ar)		{            int bytesRead;            try            {                bytesRead = stream.EndRead(ar);            }            catch (IOException)            {                return;            }		    if( bytesRead > 0 )		    {		      	string msg = System.Text.Encoding.ASCII.GetString(buffer, 0, bytesRead);		      	Console.WriteLine( msg );					if(!IsValidMessage(msg))				{					Console.WriteLine("Invalid Message Format");
                    Write(CreateErrorDocument("Invalid Message Format").OuterXml);					//right now, just ignore invalid messages					return;				}	                if(!IsAuthorized(msg))                {					Console.WriteLine("Message Not Authorized");
                    Write(CreateErrorDocument("Message Not Authorized").OuterXml);					return;                }				string response = HandleMessage(msg);							if(response == null)				{					//dont send response?
                    response = CreateErrorDocument("Command not recognized.").OuterXml;				}					Write(response);		    }		    else		    {				Quit();		    }		}		        //todo: do we need to authorize every call? or just the first one        //and then authorize the client?        private bool IsAuthorized(string msg)        {            if(!requireAuthToken)            {                return true;            }			XmlDocument xml = new XmlDocument();			xml.LoadXml(msg);            XmlAttribute tokenAttribute = xml.FirstChild.Attributes["authtoken"];            if (tokenAttribute == null)            {                return false;            }            string aToken = tokenAttribute.Value;            return (aToken.CompareTo(authToken) == 0);        }		private void Write(string s)		{			byte [] outMsg = StringToByteArray(s);	       	stream.BeginWrite(outMsg, 0, outMsg.Length, writeCallback, null);		}				private void Listen()		{			stream.BeginRead(buffer, 0, buffer.Length, readCallback, null);		}			private void onStreamWrite(IAsyncResult ar)		{	    	stream.EndWrite(ar);	    	Listen();		}			private byte[] StringToByteArray(string s)		{	 		System.Text.ASCIIEncoding  encoding=new System.Text.ASCIIEncoding();		    return encoding.GetBytes(s);			}			private bool IsValidMessage(string s)		{			XmlDocument xml = new XmlDocument();					try			{				xml.LoadXml(s);			}			catch(Exception)			{				return false;			}					return true;		}			private string HandleMessage(string s)		{			XmlDocument requestDocument = new XmlDocument();
            requestDocument.LoadXml(s);

            XmlNode commandNode = requestDocument.SelectSingleNode("/command");            if (commandNode == null)            {
                return CreateErrorDocument("Input not recognized").OuterXml;            }

            XmlDocument responseDocument = new XmlDocument();
            XmlNode responseElement = responseDocument.CreateNode(XmlNodeType.Element, "response", "");
            responseDocument.AppendChild(responseElement);

            string id = ExtractId(commandNode);
            XmlAttribute idAttribute = responseDocument.CreateAttribute("id");
            idAttribute.Value = id;
            responseElement.Attributes.SetNamedItem(idAttribute);			XmlNodeList children = commandNode.ChildNodes;					IProxyCommand command = null;
            XmlAttribute typeAttribute = responseDocument.CreateAttribute("type");					foreach (XmlNode node in children)			{				switch(node.Name)				{					case "exec":					{						command = new ExecCommand();                        try                        {
                            responseDocument = command.Exec(requestDocument, responseDocument);
                            typeAttribute.Value = "success";
                            responseDocument.FirstChild.Attributes.SetNamedItem(typeAttribute);

                            return responseDocument.OuterXml;                            //return CreateResponseNode(command.Exec(node), commandNode).OuterXml;                        }                        catch (Exception e)                        {
                            return CreateErrorDocument(e.Message, id).OuterXml;                        }					}                    case "screenshot":                    {                        command = new ScreenshotCommand();                        try                        {
                            responseDocument = command.Exec(requestDocument, responseDocument);

                            typeAttribute.Value = "success";
                            responseDocument.FirstChild.Attributes.SetNamedItem(typeAttribute);

                            return responseDocument.OuterXml;                            //return CreateResponseNode(command.Exec(node), commandNode).OuterXml;                        }                        catch (Exception e)                        {
                            return CreateErrorDocument(e.Message, id).OuterXml;                        }                    }				}			}			return null;		}        private string ExtractId(XmlNode commandNode)        {            XmlAttribute idAt = commandNode.Attributes["id"];            string id = null;            if (idAt != null)            {                id = idAt.Value;            }            return id;        }		public void Quit()		{			stream.Close(  );			client.Close(  );			stream = null;			client = null;		}

        public XmlDocument CreateErrorDocument(string msg)        {            string outXml = "<response type=\"error\"><message>" + msg + "</message></response>";            XmlTextReader xmlReader = new XmlTextReader(new StringReader(outXml));            XmlDocument xmlDocument = new XmlDocument();
            xmlDocument.AppendChild(xmlDocument.ReadNode(xmlReader));
            return xmlDocument;        }

        public XmlDocument CreateErrorDocument(string msg, string id)		{            XmlDocument errorResponse = CreateErrorDocument(msg);

            if (id == null)
            {
                return errorResponse;
            }

            XmlAttribute idAttribute = errorResponse.CreateAttribute("id");
            idAttribute.Value = id;

            errorResponse.FirstChild.Attributes.SetNamedItem(idAttribute);            return errorResponse;		}        private XmlAttribute CreateIdAttribute(string id)        {            XmlDocument t = new XmlDocument();            XmlAttribute a = t.CreateAttribute("id");            a.Value = id;            return a;        }/*		public XmlNode CreateResponseNode(XmlNode contentNode, XmlNode commandNode)		{            string outXml = "<response type=\"success\" />";						XmlTextReader xmlReader = new XmlTextReader(new StringReader(outXml));			XmlDocument xmlDocument = new XmlDocument();            XmlNode outNode = xmlDocument.ReadNode(xmlReader);            if(contentNode != null)            {                outNode.AppendChild(xmlDocument.ImportNode(contentNode, true));            }            string id = ExtractId(commandNode);            if (id != null)            {                outNode.Attributes.SetNamedItem(CreateIdAttribute(id));            }            return outNode;		} */		}}