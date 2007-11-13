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

using System.Xml;
using System.Diagnostics;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System.ComponentModel;
using System;


/*
<command authtoken="">
	<exec>
		<path></path>
		<arguments>
			<arg></arg>
		</arguments>
	</exec>
</command>

<command authtoken=""><exec><path>/Applications/TextEdit.app/Contents/MacOS/TextEdit</path><arguments><arg></arg></arguments></exec></command>
*/

namespace CommandProxy.Commands
{
    /// <summary>
    ///     Class that provides access to executing programs.
    /// </summary>
	public class ExecCommand :IProxyCommand
	{
        /// <summary>
        /// Takes input from the client and executes the command based on the input.
        /// </summary>
        /// <param name="requestDocument">An XmlDocument of the request from the client</param>
        /// <param name="responseDocument">The XmlDocument that will be sent back to the client</param>
        /// <returns></returns>
		public XmlDocument Exec(XmlDocument requestDocument, XmlDocument responseDocument)
		{
            //grab the command node for exec. In this case it is the exec element
            XmlNode commandNode = requestDocument.FirstChild.SelectSingleNode("exec");

            //grab the path node / element
            XmlNode pathNode = commandNode.SelectSingleNode("path");

            //check if the path element is present
            if (pathNode == null)
            {
                //if not, throw an exception
                throw new Exception("Path not found");
            }

            //path to the application to execute
            string path = pathNode.InnerXml;

            //grab all of the arg elements (which each represent an argument to pass
            //to the application when it is launched
            XmlNodeList argNodes = commandNode.SelectNodes("arguments/arg");

            //create a string builder to build and hold the args.
            StringBuilder args = new StringBuilder();

            //check if there are any arguments
            if (argNodes != null && argNodes.Count > 0)
            {
                //loop through all of the argument nodes
                foreach (XmlNode a in argNodes)
                {
                    //todo: wrap these in double quotes?

                    //grab the argument and append it to the string builder
                    args.Append(CleanArgument(a.InnerXml));

                    //add a space to seperate the args
                    args.Append(" ");
                }
            }

            //get the capture attribute
            XmlAttribute captureAt = commandNode.Attributes["capture"];

            //whether we capture output
            bool capture = false;

            //check to see if the capture attribute was specified
            if (captureAt != null)
            {
                //figure out the value of the capture attribute
                capture = (captureAt.Value == "true") ? true : false;
            }
	
            //create a process to launch the app
			Process p = new Process();

            //set the path of the executable
			p.StartInfo.FileName = path;

            //get a string of the args
            string argStr = args.ToString();

            //check if there are any args
            if (argStr.Length > 0)
            {
                //specify the args. remove the last charachter (which is a space that we added)
                p.StartInfo.Arguments = argStr.Remove(argStr.Length - 1);
            }

            //check if we need to capture output
            if (capture)
            {
                //this is required to capture output
                p.StartInfo.UseShellExecute = false;

                //redirect output to standard out so we can capture it
                p.StartInfo.RedirectStandardOutput = true;
            }


            try
            {
                //start the application
                p.Start();
            }
            catch (Win32Exception e)
            {
                //if something goes wrong, we just re-throw the error
                throw e;
            }

            //check if we need to capture output
            if(capture)
            {
                //read the output from the app into a string
                string output = p.StandardOutput.ReadToEnd();

                //wait for the application to exit (this will block)
                p.WaitForExit();

                //create the output element with the output from the application
                XmlTextReader xmlReader = new XmlTextReader(new StringReader("<output>" + output + "</output>"));

                //create a node from the xml string
                XmlNode outputNode = responseDocument.ReadNode(xmlReader);

                //add the output element to the response document
                responseDocument.FirstChild.AppendChild(outputNode);

            }

            //return the response document
            return responseDocument;
		}

        /// <summary>
        ///     Takes a string an escapes it to be passed as an argument
        /// </summary>
        /// <param name="s">A string to be escape as an argument</param>
        /// <returns>A string escape and ready to be used as an argument</returns>
        private string CleanArgument(string s)
        {
            //todo: need to figure out how to escape the strings
            //string outStr = "\"" + s.Replace("\"", "\"\"") + "\"";
            return s;
        }
	}
}
