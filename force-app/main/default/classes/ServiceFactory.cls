/**
 * @description       : Example code for instantating services via factory design pattern. This class works as afactory to create
 *                      HTTPService singletons as per the Impl Class configured in custom meta data records for the service. For
 *                      now there is no shipping specific class so it returns baseclass itself i.e. HTTPService.
 * @author            : Code-It-Forward team members (main contributors) and Tom Zarr (content adaptation and editing for course)
 *                      To find out more about Code-It-Forward please consult these links:
 *                      https://sfdc.co/CodeItForwardCharter
 *                      https://sfdc.co/CodeItForwardRepository
 * @group             : Salesforce Commerce Partner Delivery Success (2026)
 * @last modified on  : 01-24-2026
 * @last modified by  : Tom Zarr
**/
public with sharing class ServiceFactory {

    private static HTTPService service;

    private ServiceFactory() {}

    public static HTTPService getService(String className)
    {
        if (service == null)
        {
            if (String.isNotEmpty(className))
            {
                Type t = Type.forName(className);
                service = (HTTPService) t.newInstance();
            }
            else
            {
                service = new HTTPService();
            }
        }

        return service;
    }
}