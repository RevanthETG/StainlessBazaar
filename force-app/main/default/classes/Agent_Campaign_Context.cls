public with sharing class Agent_Campaign_Context {

    public class Request {
        @InvocableVariable(required=true)
        public String phoneNumber;
    }

    public class Response {
        @InvocableVariable
        public String result; 
    }

    private class ApiResponse {
        public List<CampaignItem> items;
    }

    private class CampaignItem {
        public CampaignValues values;
    }

    private class CampaignValues {
        public String phonenumber;
        public String campaignname;
        public String campaignsent;
    }

    @InvocableMethod(label='Get Campaign Context')
    public static List<Response> getCampaignByPhone(List<Request> requests) {

        List<Response> responses = new List<Response>();

        for (Request reqInput : requests) {

            Response resOutput = new Response();

            try {
                String filter = 'phonenumber eq "' + reqInput.phoneNumber + '"';
                String encodedFilter = EncodingUtil.urlEncode(filter, 'UTF-8').replace('+', '%20');

                String endpoint = 'callout:mcapi/data/v1/customobjectdata/key/campaign_context/rowset' +
                                  '?$filter=' + encodedFilter;

                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setMethod('GET');

                HttpResponse res = new Http().send(req);

                if (res.getStatusCode() == 200) {
                    ApiResponse data = (ApiResponse) JSON.deserialize(res.getBody(), ApiResponse.class);

                    if (data?.items != null && !data.items.isEmpty()) {
                        CampaignValues v = data.items[0].values;

                        // Create map like your debug
                        Map<String, String> resultMap = new Map<String, String>{
                            'phoneNumber' => v.phonenumber,
                            'campaignName' => v.campaignname,
                            'campaignSent' => v.campaignsent
                        };

                        // Convert to JSON string (best for Agentforce)
                        resOutput.result = JSON.serialize(resultMap);
                    }
                }

            } catch (Exception e) {
                resOutput.result = 'ERROR: ' + e.getMessage();
            }

            responses.add(resOutput);
        }

        return responses;
    }
}