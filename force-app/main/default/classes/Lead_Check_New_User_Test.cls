@isTest
public class Lead_Check_New_User_Test {

    // Mock SUCCESS response
    class MockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            res.setBody('{' +
                '"data": {' +
                    '"stock_availability": "Available",' +
                    '"min_offer_price": 100.5,' +
                    '"price_to_user": 120.75,' +
                    '"lead": {' +
                        '"id": "L123",' +
                        '"leadType": "New",' +
                        '"leadStatus": 1,' +
                        '"createdUpdatedDate": {' +
                            '"createdAt": "2024-01-01"' +
                        '}' +
                    '}' +
                '}' +
            '}');

            return res;
        }
    }

    //  Mock ERROR response
    class MockError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Server Error');
            return res;
        }
    }

    //  SUCCESS TEST
    @isTest
    static void testSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        Lead_Check_New_User.LeadCheckRequest req = new Lead_Check_New_User.LeadCheckRequest();
        req.userPhone = '9999999999';
        req.productCategory = 'Steel';
        req.quantity = 10;

        Test.startTest();
        List<Lead_Check_New_User.LeadCheckResponse> resList =
            Lead_Check_New_User.checkStockAndPrice(new List<Lead_Check_New_User.LeadCheckRequest>{req});
        Test.stopTest();

        System.assertEquals(1, resList.size());
        System.assertEquals('Available', resList[0].stockAvailable);
        System.assertEquals('Success', resList[0].summary);
    }

    //  ERROR TEST
    @isTest
    static void testErrorResponse() {
        Test.setMock(HttpCalloutMock.class, new MockError());

        Lead_Check_New_User.LeadCheckRequest req = new Lead_Check_New_User.LeadCheckRequest();
        req.userPhone = '9999999999';

        Test.startTest();
        List<Lead_Check_New_User.LeadCheckResponse> resList =
            Lead_Check_New_User.checkStockAndPrice(new List<Lead_Check_New_User.LeadCheckRequest>{req});
        Test.stopTest();

        System.assert(resList[0].summary.contains('API Error'));
    }

   
    @isTest
    static void testNoIdentifier() {
        Lead_Check_New_User.LeadCheckRequest req = new Lead_Check_New_User.LeadCheckRequest();

        Test.startTest();
        List<Lead_Check_New_User.LeadCheckResponse> resList =
            Lead_Check_New_User.checkStockAndPrice(new List<Lead_Check_New_User.LeadCheckRequest>{req});
        Test.stopTest();

        System.assertEquals('User identifier missing.', resList[0].summary);
    }
}