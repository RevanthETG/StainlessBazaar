public with sharing class Campaign_Context_v2 {

    public class Request {
        @InvocableVariable(required=true)
        public String phoneNumber;
        
        @InvocableVariable(required=true)
        public String messagingSessionId;
    }

    public class Response {
        @InvocableVariable
        public String result;
        
        @InvocableVariable
        public Boolean success;
    }

    // Keep these public so Queueable can reuse
    public class ApiResponse {
        public List<CampaignItem> items;
    }

    public class CampaignItem {
        public CampaignValues values;
    }

    public class CampaignValues {
        public String phonenumber;
        public String campaignname;
        public String campaignsent;
        public String campiagnsenttime;
        public String jbdefinitionid;
    }

    @InvocableMethod(label='Get Campaign Context' description='Fetches campaign context from Marketing Cloud using Queueable')
    public static List<Response> getCampaignByPhone(List<Request> requests) {
        
        List<Response> responses = new List<Response>();
        
        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        Map<String, String> phoneToSessionMap = new Map<String, String>();

        for (Request reqInput : requests) {
            Response resOutput = new Response();

            if (String.isBlank(reqInput.phoneNumber)) {
                resOutput.success = false;
                resOutput.result = 'ERROR: Phone number is required';
                responses.add(resOutput);
                continue;
            }

            if (String.isBlank(reqInput.messagingSessionId)) {
                resOutput.success = false;
                resOutput.result = 'ERROR: MessagingSession ID is required';
                responses.add(resOutput);
                continue;
            }

            phoneToSessionMap.put(reqInput.phoneNumber, reqInput.messagingSessionId);

            resOutput.success = true;
            resOutput.result = 'Campaign context fetch initiated';
            responses.add(resOutput);
        }

       
        if (!phoneToSessionMap.isEmpty()) {
            System.enqueueJob(new CampaignContextQueueable_v3(phoneToSessionMap));
        }

        return responses;
    }
}