using CommandProxy;

public class cproxy
{
    public static void Main()
    {
        int port = 10000;
        bool requireAuthToken = false;

        CommandProxy.CommandProxy proxy = new CommandProxy.CommandProxy();
        proxy.Run(port, requireAuthToken);
    }
}