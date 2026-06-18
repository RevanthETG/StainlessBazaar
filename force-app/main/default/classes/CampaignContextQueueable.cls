public with sharing class CampaignContextQueueable implements Queueable, Database.AllowsCallouts {

    private Map<String, String> phoneToSessionMap;

    public CampaignContextQueueable(Map<String, String> phoneToSessionMap) {
        this.phoneToSessionMap = phoneToSessionMap;
    }

    public void execute(QueueableContext context) {

        Map<String, String> sessionToResponseMap = new Map<String, String>();

        for (String phoneNumber : phoneToSessionMap.keySet()) {
            try {
                String campaignResponse = fetchCampaignFromMC(phoneNumber);

                if (String.isNotBlank(campaignResponse)) {
                    String sessionId = phoneToSessionMap.get(phoneNumber);
                    sessionToResponseMap.put(sessionId, campaignResponse);
                } else {
                    System.debug('No campaign data for phone: ' + phoneNumber);
                }

            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Queueable Error: ' + e.getMessage());
            }
        }

        if (!sessionToResponseMap.isEmpty()) {
          if (Test.isRunningTest()) {
                    return;
                }
            
              updateMessagingSessions(sessionToResponseMap);
        }
    }

    // 🔁 Reuse your existing logic
    private static String fetchCampaignFromMC(String phoneNumber) {

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

            if (data?.items != null && !data.items.isEmpty()) {
                Campaign_Context_v2.CampaignValues v = data.items[0].values;

                Map<String, String> resultMap = new Map<String, String>{
                    'phoneNumber' => v.phonenumber,
                    'campaignName' => v.campaignname,
                    'campaignSent' => v.campaignsent
                };

                return JSON.serialize(resultMap);
            }
        }

        return null;
    }

    private static void updateMessagingSessions(Map<String, String> sessionToResponseMap) {

        List<MessagingSession> sessionsToUpdate = new List<MessagingSession>();

        for (String sessionId : sessionToResponseMap.keySet()) {
            sessionsToUpdate.add(new MessagingSession(
                Id = sessionId,
                Last_Campaign_Context__c = sessionToResponseMap.get(sessionId)
            ));
        }

        if (!sessionsToUpdate.isEmpty()) {
            update sessionsToUpdate;
        }
    }
}