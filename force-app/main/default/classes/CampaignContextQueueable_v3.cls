public with sharing class CampaignContextQueueable_v3 implements Queueable, Database.AllowsCallouts {

    private Map<String, String> phoneToSessionMap;

    private class CampaignFetchResult {
        String responseJson;
        String journeyId;
    }

    public CampaignContextQueueable_v3(Map<String, String> phoneToSessionMap) {
        this.phoneToSessionMap = phoneToSessionMap;
    }

    public void execute(QueueableContext context) {
        Map<String, CampaignFetchResult> sessionToResultMap = new Map<String, CampaignFetchResult>();

        for (String phoneNumber : phoneToSessionMap.keySet()) {
            try {
                CampaignFetchResult campaignResponse = fetchCampaignFromMC(phoneNumber);

                if (campaignResponse != null && String.isNotBlank(campaignResponse.responseJson)) {
                    String sessionId = phoneToSessionMap.get(phoneNumber);
                    sessionToResultMap.put(sessionId, campaignResponse);
                } else {
                    System.debug('No campaign data for phone: ' + phoneNumber);
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Queueable Error: ' + e.getMessage());
            }
        }

        if (!sessionToResultMap.isEmpty()) {
            updateMessagingSessions(sessionToResultMap);
        }
    }

    private static CampaignFetchResult fetchCampaignFromMC(String phoneNumber) {
        String filter = 'phonenumber eq "' + String.escapeSingleQuotes(phoneNumber) + '"';
        String encodedFilter = EncodingUtil.urlEncode(filter, 'UTF-8').replace('+', '%20');

        String endpoint = 'callout:mcapi/data/v1/customobjectdata/key/campaign_context/rowset?$filter=' + encodedFilter;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);

        HttpResponse res = new Http().send(req);

        System.debug('RAW RESPONSE: ' + res.getBody());

        if (res.getStatusCode() == 200) {
            Campaign_Context_v2.ApiResponse data =
                (Campaign_Context_v2.ApiResponse) JSON.deserialize(res.getBody(), Campaign_Context_v2.ApiResponse.class);

            if (data != null && data.items != null && !data.items.isEmpty()) {
                Campaign_Context_v2.CampaignValues v = data.items[0].values;

                Map<String, String> resultMap = new Map<String, String>{
                    'phoneNumber' => v.phonenumber,
                    'campaignName' => v.campaignname,
                    'campaignSent' => v.campaignsent,
                    'campiagnsenttime' => v.campiagnsenttime,
                    'jbdefinitionid' => v.jbdefinitionid
                };

                CampaignFetchResult result = new CampaignFetchResult();
                result.responseJson = JSON.serialize(resultMap);
                result.journeyId = v.jbdefinitionid;

                return result;
            }
        }

        return null;
    }

    private static void updateMessagingSessions(Map<String, CampaignFetchResult> sessionToResultMap) {
        List<MessagingSession> sessionsToUpdate = new List<MessagingSession>();

        for (String sessionId : sessionToResultMap.keySet()) {
            CampaignFetchResult result = sessionToResultMap.get(sessionId);

            MessagingSession sessionRecord = new MessagingSession(
                Id = sessionId,
                Last_Campaign_Context__c = result.responseJson
            );

            if (String.isNotBlank(result.journeyId)) {
                sessionRecord.Leadsource__c = result.journeyId;
            }

            sessionsToUpdate.add(sessionRecord);
        }

        if (!sessionsToUpdate.isEmpty()) {
            if (Test.isRunningTest()) {
                return;
            }

            update sessionsToUpdate;
        }
    }
}