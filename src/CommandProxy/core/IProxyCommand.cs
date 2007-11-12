using System.Xml;

interface IProxyCommand
{
	XmlDocument Exec(XmlDocument requestDocument, XmlDocument responseDocument);
}