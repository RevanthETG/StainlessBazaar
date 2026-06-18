@isTest
public class CustomerStatusTest {

    
    class MockSuccessResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String body = '{' +
                '"message": "Customer found",' +
                '"data": {' +
                    '"customerStatus": {' +
                        '"memberId": "12345",' +
                        '"member_email": "test@example.com",' +
                        '"member_phone": "9999999999",' +
                        '"member_name": "Test User",' +
                        '"member_status": "Active",' +
                        '"buyerManagerFirstName": "John",' +
                        '"buyerManagerLastName": "Doe",' +
                        '"buyerManagerEmail": "john.doe@example.com",' +
                        '"buyerManagerPhone": "8888888888"' +
                    '}' +
                '}' +
            '}';

            res.setBody(body);
            return res;
        }
    }

    /*
     * Mock class for error response (500)
     */
    class MockErrorResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setStatus('Internal Server Error');
            res.setBody('Something went wrong');
            return res;
        }
    }

    /*
     * Mock class to simulate callout exception
     */
    class MockExceptionResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Simulated callout failure');
        }
    }

    // ✅ Test SUCCESS scenario
    @isTest
    static void testSuccessResponse() {
        Test.setMock(HttpCalloutMock.class, new MockSuccessResponse());

        Customer_status.APIRequest req = new Customer_status.APIRequest();
        req.member_email = 'test@example.com';

        Test.startTest();
        Customer_status.APIResponse res = Customer_status.makeAPICallout(req);
        Test.stopTest();

        System.assertEquals('12345', res.memberId);
        System.assertEquals('Test User', res.member_name);
        System.assertEquals('Active', res.memberStatus);
        System.assert(res.summary.contains('Customer found'));
    }

    // ✅ Test ERROR HTTP response
    @isTest
    static void testErrorResponse() {
        Test.setMock(HttpCalloutMock.class, new MockErrorResponse());

        Customer_status.APIRequest req = new Customer_status.APIRequest();
        req.member_phone = '9999999999';

        Test.startTest();
        Customer_status.APIResponse res = Customer_status.makeAPICallout(req);
        Test.stopTest();

        System.assert(res.summary.contains('Error: HTTP'));
    }

    // ✅ Test CALLOUT EXCEPTION
    @isTest
    static void testCalloutException() {
        Test.setMock(HttpCalloutMock.class, new MockExceptionResponse());

        Customer_status.APIRequest req = new Customer_status.APIRequest();
        req.member_name = 'Test User';

        Test.startTest();
        Customer_status.APIResponse res = Customer_status.makeAPICallout(req);
        Test.stopTest();

        System.assert(res.summary.contains('Callout failed'));
    }

    // ✅ Test VALIDATION (no input)
    @isTest
    static void testValidationFailure() {
        Customer_status.APIRequest req = new Customer_status.APIRequest();

        Test.startTest();
        Customer_status.APIResponse res = Customer_status.makeAPICallout(req);
        Test.stopTest();

        System.assert(res.summary.contains('At least one identifier'));
    }

    // ✅ Test Invocable Method
    @isTest
    static void testInvocableMethod() {
        Test.setMock(HttpCalloutMock.class, new MockSuccessResponse());

        Customer_status.APIRequest req = new Customer_status.APIRequest();
        req.member_email = 'test@example.com';

        List<Customer_status.APIRequest> reqList = new List<Customer_status.APIRequest>{ req };

        Test.startTest();
        List<Customer_status.APIResponse> responses =
            Customer_status.checkCustomerStatusAndUpdateLead(reqList);
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(responses[0].summary.contains('Customer found'));
    }
}