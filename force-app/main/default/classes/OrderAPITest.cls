@IsTest
private class OrderAPITest {

    private class OrderAPISuccessMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        System.assertEquals('GET', req.getMethod());

        System.assert(
            req.getEndpoint().contains('/sales-force/customer_orders?phone=919321150211'),
            'Endpoint should contain encoded phone parameter'
        );

        System.assertEquals(
            'application/json',
            req.getHeader('Content-Type')
        );

        System.assertEquals(
            'SBZ-SECURE-KEY-8eab41d0-51ce-4f1b-a6d2-f93f1c3e5b7f',
            req.getHeader('x-access-token')
        );

        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"statusCode":200,"data":{"memberId":1075,"member_phone":"9321150211","member_name":"VSTAR ENTERPRISE","leads":[{"id":24906,"leadStatus":20,"leadStatusName":"Pending for TAX Invoice","productCategory":"Coils [HR/CR]","productDescription":"Coil","deliveryInDays":7,"state":"Maharashtra","deliveryCity":"Vasai","brand":"Imported","ssGrade":"200","subGrade":"N7","invoiceDate":null}]},"message":"Member last 5 leads retrieved successfully","pagination":null}');
        return res;
    }
}

    private class OrderAPIErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setStatus('Internal Server Error');
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message":"Something went wrong"}');
            return res;
        }
    }

    

    @IsTest
    static void testGetCustomerOrdersMissingPhone() {
        OrderAPI.OrderRequest request = new OrderAPI.OrderRequest();
        request.phone = null;

        Test.startTest();
        List<OrderAPI.OrderResponse> responses =
            OrderAPI.getCustomerOrders(new List<OrderAPI.OrderRequest>{ request });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(false, responses[0].success);
        System.assertEquals('Phone number is required.', responses[0].message);
    }

    @IsTest
    static void testGetCustomerOrdersApiError() {
        Test.setMock(HttpCalloutMock.class, new OrderAPIErrorMock());

        OrderAPI.OrderRequest request = new OrderAPI.OrderRequest();
        request.phone = '919321150211';

        Test.startTest();
        List<OrderAPI.OrderResponse> responses =
            OrderAPI.getCustomerOrders(new List<OrderAPI.OrderRequest>{ request });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(false, responses[0].success);
        System.assertEquals(500, responses[0].httpStatusCode);
        System.assert(responses[0].message.contains('API Error'));
    }
}