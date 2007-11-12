using System.Xml;

interface IProxyCommand
{
	XmlNode Exec(XmlNode node);
}