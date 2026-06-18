@IsTest
private class Agent_Campaign_Context_v2_Test {
    private static String recentMarketingCloudDate() {
        Date d = Date.today().addDays(-1);
        return d.month() + '/' + d.day() + '/' + d.year() + ' 11:09:42 PM';
    }

    private static String oldMarketingCloudDate() {
        Date d = Date.today().addDays(-20);
        return d.month() + '/' + d.day() + '/' + d.year() + ' 11:09:42 PM';
    }

    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            res.setBody(
                '{"items":[' +
                    '{"keys":{},"values":{' +
                        '"subscriberkey":"1234567890",' +
                        '"memberid":"1234567890",' +
                        '"campaignsent":"{Brand: Laxcon,Product Category: Coils [HR/CR]}",' +
                        '"campiagnsenttime":"' + recentMarketingCloudDate() + '",' +
                        '"jbdefinitionid":"journey-123",' +
                        '"phonenumber":"1234567890"' +
                    '}}' +
                ']}'
            );

            return res;
        }
    }

    private class MultipleRecordsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            res.setBody(
                '{"items":[' +
                    '{"keys":{},"values":{' +
                        '"campaignsent":"Old requested phone campaign",' +
                        '"campiagnsenttime":"' + oldMarketingCloudDate() + '",' +
                        '"jbdefinitionid":"old-journey",' +
                        '"phonenumber":"1234567890"' +
                    '}},' +
                    '{"keys":{},"values":{' +
                        '"campaignsent":"Recent different phone campaign",' +
                        '"campiagnsenttime":"' + recentMarketingCloudDate() + '",' +
                        '"jbdefinitionid":"wrong-phone-journey",' +
                        '"phonenumber":"9999999999"' +
                    '}},' +
                    '{"keys":{},"values":{' +
                        '"campaignsent":"Recent requested phone campaign",' +
                        '"campiagnsenttime":"' + recentMarketingCloudDate() + '",' +
                        '"jbdefinitionid":"correct-phone-journey",' +
                        '"phonenumber":"1234567890"' +
                    '}}' +
                ']}'
            );

            return res;
        }
    }

    private class NoRecordsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"items":[]}');
            return res;
        }
    }

    private class ApiErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }

    @IsTest
    static void testCampaignFoundInLastSevenDays() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Agent_Campaign_Context_v2.Request req = new Agent_Campaign_Context_v2.Request();
        req.phoneNumber = '1234567890';
        req.messagingSessionId = null;

        Test.startTest();
        List<Agent_Campaign_Context_v2.Response> responses =
            Agent_Campaign_Context_v2.getCampaignByPhone(
                new List<Agent_Campaign_Context_v2.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertNotEquals(null, responses[0].result);
        System.assertEquals('journey-123', responses[0].journeyId);
        System.assert(responses[0].result.contains('Laxcon'));
        System.assert(responses[0].result.contains('journey-123'));
    }

    @IsTest
    static void testMultipleRecordsUsesMatchingRecentPhone() {
        Test.setMock(HttpCalloutMock.class, new MultipleRecordsMock());

        Agent_Campaign_Context_v2.Request req = new Agent_Campaign_Context_v2.Request();
        req.phoneNumber = '1234567890';

        Test.startTest();
        List<Agent_Campaign_Context_v2.Response> responses =
            Agent_Campaign_Context_v2.getCampaignByPhone(
                new List<Agent_Campaign_Context_v2.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals('correct-phone-journey', responses[0].journeyId);
        System.assert(responses[0].result.contains('Recent requested phone campaign'));
    }

    @IsTest
    static void testNoRecordsFound() {
        Test.setMock(HttpCalloutMock.class, new NoRecordsMock());

        Agent_Campaign_Context_v2.Request req = new Agent_Campaign_Context_v2.Request();
        req.phoneNumber = '1234567890';

        Test.startTest();
        List<Agent_Campaign_Context_v2.Response> responses =
            Agent_Campaign_Context_v2.getCampaignByPhone(
                new List<Agent_Campaign_Context_v2.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals('No records found', responses[0].result);
        System.assertEquals(null, responses[0].journeyId);
    }

    @IsTest
    static void testApiError() {
        Test.setMock(HttpCalloutMock.class, new ApiErrorMock());

        Agent_Campaign_Context_v2.Request req = new Agent_Campaign_Context_v2.Request();
        req.phoneNumber = '1234567890';

        Test.startTest();
        List<Agent_Campaign_Context_v2.Response> responses =
            Agent_Campaign_Context_v2.getCampaignByPhone(
                new List<Agent_Campaign_Context_v2.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals('API Error: Internal Server Error', responses[0].result);
    }
}