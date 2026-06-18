@IsTest
private class Campaign_Context_v2_Test {

    class MockHttpResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{"items":[{"values":{' +
                    '"phonenumber":"8686793220",' +
                    '"campaignname":"Test Campaign",' +
                    '"campaignsent":"true",' +
                    '"campiagnsenttime":"5/12/2026 11:09:42 PM",' +
                    '"jbdefinitionid":"journey-123"' +
                '}}]}'
            );
            return res;
        }
    }

    class NoRecordsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"items":[]}');
            return res;
        }
    }

    class ApiErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }

    @IsTest
    static void testOtherBranches() {
        List<Campaign_Context_v2.Response> res1 =
            Campaign_Context_v2.getCampaignByPhone(null);
        System.assertEquals(0, res1.size());

        List<Campaign_Context_v2.Response> res2 =
            Campaign_Context_v2.getCampaignByPhone(new List<Campaign_Context_v2.Request>());
        System.assertEquals(0, res2.size());

        Campaign_Context_v2.Request missingSessionReq = new Campaign_Context_v2.Request();
        missingSessionReq.phoneNumber = '8686793220';
        missingSessionReq.messagingSessionId = '';

        List<Campaign_Context_v2.Response> res3 =
            Campaign_Context_v2.getCampaignByPhone(new List<Campaign_Context_v2.Request>{ missingSessionReq });

        System.assertEquals(false, res3[0].success);
        System.assertEquals('ERROR: MessagingSession ID is required', res3[0].result);

        Campaign_Context_v2.Request missingPhoneReq = new Campaign_Context_v2.Request();
        missingPhoneReq.phoneNumber = '';
        missingPhoneReq.messagingSessionId = '0Mw000000000001AAA';

        List<Campaign_Context_v2.Response> res4 =
            Campaign_Context_v2.getCampaignByPhone(new List<Campaign_Context_v2.Request>{ missingPhoneReq });

        System.assertEquals(false, res4[0].success);
        System.assertEquals('ERROR: Phone number is required', res4[0].result);
    }

    @IsTest
    static void testMainSuccessWithJourneyId() {
        Campaign_Context_v2.Request req = new Campaign_Context_v2.Request();
        req.phoneNumber = '8686793220';
        req.messagingSessionId = '0Mw000000000001AAA';

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        List<Campaign_Context_v2.Response> responses =
            Campaign_Context_v2.getCampaignByPhone(new List<Campaign_Context_v2.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].success);
        System.assertEquals('Campaign context fetch initiated', responses[0].result);
    }

    @IsTest
    static void testQueueableNoRecords() {
        Campaign_Context_v2.Request req = new Campaign_Context_v2.Request();
        req.phoneNumber = '8686793220';
        req.messagingSessionId = '0Mw000000000001AAA';

        Test.setMock(HttpCalloutMock.class, new NoRecordsMock());

        Test.startTest();
        List<Campaign_Context_v2.Response> responses =
            Campaign_Context_v2.getCampaignByPhone(new List<Campaign_Context_v2.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].success);
    }

    @IsTest
    static void testQueueableApiError() {
        Campaign_Context_v2.Request req = new Campaign_Context_v2.Request();
        req.phoneNumber = '8686793220';
        req.messagingSessionId = '0Mw000000000001AAA';

        Test.setMock(HttpCalloutMock.class, new ApiErrorMock());

        Test.startTest();
        List<Campaign_Context_v2.Response> responses =
            Campaign_Context_v2.getCampaignByPhone(new List<Campaign_Context_v2.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].success);
    }
}