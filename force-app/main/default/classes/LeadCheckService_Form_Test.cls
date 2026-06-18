@isTest
public class LeadCheckService_Form_Test {

    //  Mock SUCCESS
    class MockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            res.setBody('{' +
                '"data": {' +
                    '"stock_availability": "In Stock",' +
                    '"min_offer_price": 200,' +
                    '"price_to_user": 250,' +
                    '"lead": {' +
                        '"id": "L456",' +
                        '"leadType": "Repeat",' +
                        '"leadStatus": 2,' +
                        '"createdUpdatedDate": {' +
                            '"createdAt": "2024-02-01"' +
                        '}' +
                    '}' +
                '}' +
            '}');

            return res;
        }
    }

    // ✅ Mock FAILURE
    class MockFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setStatus('Bad Request');
            return res;
        }
    }

    // ✅ SUCCESS TEST
    @isTest
    static void testSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        LeadCheckService_Form.LeadCheckRequest req = new LeadCheckService_Form.LeadCheckRequest();
        req.userEmail = 'test@test.com';
        req.productCategory = 'Steel';
        req.quantity = 5;

        Test.startTest();
        List<LeadCheckService_Form.LeadCheckResponse> resList =
            LeadCheckService_Form.checkStockAndPrice(new List<LeadCheckService_Form.LeadCheckRequest>{req});
        Test.stopTest();

        System.assertEquals(1, resList.size());
        System.assertEquals('In Stock', resList[0].stockAvailable);
        System.assertEquals('Success', resList[0].summary);
    }

    // ✅ ERROR TEST
    @isTest
    static void testError() {
        Test.setMock(HttpCalloutMock.class, new MockFailure());

        LeadCheckService_Form.LeadCheckRequest req = new LeadCheckService_Form.LeadCheckRequest();
        req.userPhone = '8888888888';

        Test.startTest();
        List<LeadCheckService_Form.LeadCheckResponse> resList =
            LeadCheckService_Form.checkStockAndPrice(new List<LeadCheckService_Form.LeadCheckRequest>{req});
        Test.stopTest();

        System.assert(resList[0].summary.contains('API Error'));
    }

    // ✅ NO IDENTIFIER TEST
    @isTest
    static void testNoIdentifier() {
        LeadCheckService_Form.LeadCheckRequest req = new LeadCheckService_Form.LeadCheckRequest();

        Test.startTest();
        List<LeadCheckService_Form.LeadCheckResponse> resList =
            LeadCheckService_Form.checkStockAndPrice(new List<LeadCheckService_Form.LeadCheckRequest>{req});
        Test.stopTest();

        System.assertEquals('User identifier missing.', resList[0].summary);
    }
}