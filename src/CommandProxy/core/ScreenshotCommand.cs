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
using System.Collections.Generic;
using System.Text;
using System.Drawing;
using System.Windows.Forms;
using System.Drawing.Imaging;
using System.Xml;
using System.IO;

namespace CommandProxy.Commands
{
    /// <summary>
    /// Class that provides access to taking screenshots of the users system.
    /// </summary>
    class ScreenshotCommand : IProxyCommand
    {
/*
<screenshot format="">
	<path></path>
</screenshot>
*/

        /// <summary>
        /// Takes input from the client and executes the command based on the input.
        /// </summary>
        /// <param name="requestDocument">An XmlDocument of the request from the client</param>
        /// <param name="responseDocument">The XmlDocument that will be sent back to the client</param>
        /// <returns></returns>
        public XmlDocument Exec(XmlDocument requestDocument, XmlDocument responseDocument)
        {
            //create the default ImageFormat and set the png
            ImageFormat format = ImageFormat.Png;

            //get the screenshot command element
            XmlNode commandNode = requestDocument.FirstChild.SelectSingleNode("screenshot");

            //grab the format attribute
            XmlAttribute formatAt = commandNode.Attributes["format"];

            //check if it exists
            if (formatAt != null)
            {
                //do a switch on the format attribute to find out which format we should use
                switch (formatAt.Value)
                {
                    //png
                    case "png":
                    {
                        format = ImageFormat.Png;
                        break;
                    }
                    //jpg
                    case "jpg":
                    {
                        format = ImageFormat.Jpeg;
                        break;
                    }
                    //gif
                    case "gif":
                    {
                        format = ImageFormat.Gif;
                        break;
                    }
                }
            }

            //grab the path element
            XmlNode pathNode = commandNode.SelectSingleNode("path");

            //string to hold the path to save the screenshot to
            string path;

            //check and see if path element was specified
            if (pathNode == null)
            {
                //if it is not specified, generate a temp file name and path to use
                path = Path.GetTempFileName();
            }
            else
            {
                //use specified file path
                //todo: should we check that the dir path exists?
                path = pathNode.InnerXml;
            }

            //take the screenshot
            try
            {
                //pass the path and image format to use
                TakeScreenShot(path, format);
            }
            catch (Exception)
            {
                //catch any exceptions and rethrow then
                throw new Exception("Error taking screenshot");
            }

            //read the path xml and path used into an xml reader
            XmlTextReader xmlReader = new XmlTextReader(new StringReader("<path>" + path + "</path>"));

            //create the path element node
            XmlNode pathElement = responseDocument.ReadNode(xmlReader);

            //appaend the path element to the response document
            responseDocument.FirstChild.AppendChild(pathElement);

            //return the response document
            return responseDocument;
        }

        /// <summary>
        /// Takes a screenshot of the user's display
        /// </summary>
        /// <param name="path">The path to save the screenshot to</param>
        /// <param name="format">The image format to save the screenshot to</param>
        private void TakeScreenShot(string path, ImageFormat format)
        {
            //do everything in a try block in case anything goes wrong
            try
            {
                //get the bounds for the desktop display
                Rectangle bounds = Screen.GetBounds(Point.Empty);

                //create a new bitmap using the bounds from the desktop
                using (Bitmap bitmap = new Bitmap(bounds.Width, bounds.Height))
                {
                    //create a new graphics instance from the bitmap
                    using (Graphics g = Graphics.FromImage(bitmap))
                    {
                        //copy the data from the screen into the graphics instance
                        g.CopyFromScreen(Point.Empty, Point.Empty, bounds.Size);
                    }

                    //write the bitmap out to the file system using the specified image
                    //format
                    bitmap.Save(path, format);
                }
            }
            catch (Exception e)
            {
                //rethrow any errors
                throw e;
            }
        }
    }
}
