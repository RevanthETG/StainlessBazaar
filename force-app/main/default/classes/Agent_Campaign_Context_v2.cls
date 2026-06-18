public with sharing class Agent_Campaign_Context_v2 {
    public class Request {
        @InvocableVariable(required=true)
        public String phoneNumber;

        @InvocableVariable(required=false)
        public String messagingSessionId;
    }

    public class Response {
        @InvocableVariable
        public String result;

        @InvocableVariable
        public String journeyId;
    }

    private class ApiResponse {
        public List<CampaignItem> items;
    }

    private class CampaignItem {
        public CampaignValues values;
    }

    private class CampaignValues {
        public String subscriberkey;
        public String memberid;
        public String phonenumber;
        public String campaignname;
        public String campaignsent;
        public String campaignsenttime;
        public String campiagnsenttime;
        public String jbdefinitionid;
    }

    @InvocableMethod(label='Get Campaign Context')
    public static List<Response> getCampaignByPhone(List<Request> requests) {
        List<Response> responses = new List<Response>();
        List<MessagingSession> sessionsToUpdate = new List<MessagingSession>();

        for (Request reqInput : requests) {
            Response resOutput = new Response();

            try {
                String phoneNumber = reqInput == null ? null : reqInput.phoneNumber;

                String filter = 'phonenumber eq \'' + String.escapeSingleQuotes(phoneNumber) + '\'';
                String encodedFilter = EncodingUtil.urlEncode(filter, 'UTF-8').replace('+', '%20');

                String endpoint = 'callout:mcapi/data/v1/customobjectdata/key/campaign_context/rowset'
                    + '?$filter=' + encodedFilter;

                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setMethod('GET');

                HttpResponse res = new Http().send(req);

                if (res.getStatusCode() == 200) {
                    ApiResponse data = (ApiResponse) JSON.deserialize(res.getBody(), ApiResponse.class);

                    if (data != null && data.items != null && !data.items.isEmpty()) {
                        Datetime sevenDaysAgo = System.now().addDays(-7);
                        CampaignValues selectedCampaign;
                        Datetime selectedSentTime;
                        String selectedSentTimeValue;

                        for (CampaignItem item : data.items) {
                            if (item == null || item.values == null) {
                                continue;
                            }

                            CampaignValues v = item.values;

                            if (String.isNotBlank(phoneNumber) && v.phonenumber != phoneNumber) {
                                continue;
                            }

                            String sentTimeValue = String.isNotBlank(v.campaignsenttime)
                                ? v.campaignsenttime
                                : v.campiagnsenttime;

                            Datetime sentTime = parseCampaignDateTime(sentTimeValue);

                            if (sentTime != null && sentTime >= sevenDaysAgo) {
                                if (selectedSentTime == null || sentTime > selectedSentTime) {
                                    selectedCampaign = v;
                                    selectedSentTime = sentTime;
                                    selectedSentTimeValue = sentTimeValue;
                                }
                            }
                        }

                        if (selectedCampaign != null) {
                            Map<String, String> resultMap = new Map<String, String>{
                                'phoneNumber' => selectedCampaign.phonenumber,
                                'campaignName' => selectedCampaign.campaignname,
                                'campaignSent' => selectedCampaign.campaignsent,
                                'campaignSentTime' => selectedSentTimeValue,
                                'journeyId' => selectedCampaign.jbdefinitionid
                            };

                            resOutput.result = JSON.serialize(resultMap);
                            resOutput.journeyId = selectedCampaign.jbdefinitionid;

                            if (String.isNotBlank(reqInput.messagingSessionId) &&
                                String.isNotBlank(selectedCampaign.jbdefinitionid)) {
                                sessionsToUpdate.add(new MessagingSession(
                                    Id = reqInput.messagingSessionId,
                                    Leadsource__c = selectedCampaign.jbdefinitionid
                                ));
                            }
                        } else {
                            resOutput.result = 'No campaign found in last 7 days';
                        }
                    } else {
                        resOutput.result = 'No records found';
                    }
                } else {
                    resOutput.result = 'API Error: ' + res.getBody();
                }
            } catch (Exception e) {
                resOutput.result = 'ERROR: ' + e.getMessage();
            }

            responses.add(resOutput);
        }

        if (!sessionsToUpdate.isEmpty()) {
            try {
                update sessionsToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating MessagingSession: ' + e.getMessage());
            }
        }

        return responses;
    }

    private static Datetime parseCampaignDateTime(String value) {
        if (String.isBlank(value)) {
            return null;
        }

        value = value.trim();

        try {
            return Datetime.valueOf(value);
        } catch (Exception ignored) {
        }

        try {
            return Datetime.parse(value);
        } catch (Exception ignored) {
        }

        try {
            List<String> parts = value.split('\\s+');
            if (parts.size() < 2) {
                return null;
            }

            List<String> dateParts = parts[0].split('/');
            List<String> timeParts = parts[1].split(':');

            if (dateParts.size() != 3 || timeParts.size() < 2) {
                return null;
            }

            Integer month = Integer.valueOf(dateParts[0]);
            Integer day = Integer.valueOf(dateParts[1]);
            Integer year = Integer.valueOf(dateParts[2]);

            Integer hour = Integer.valueOf(timeParts[0]);
            Integer minute = Integer.valueOf(timeParts[1]);
            Integer second = timeParts.size() > 2 ? Integer.valueOf(timeParts[2]) : 0;

            if (parts.size() > 2) {
                String meridiem = parts[2].toUpperCase();

                if (meridiem == 'PM' && hour < 12) {
                    hour += 12;
                } else if (meridiem == 'AM' && hour == 12) {
                    hour = 0;
                }
            }

            return Datetime.newInstance(
                Date.newInstance(year, month, day),
                Time.newInstance(hour, minute, second, 0)
            );
        } catch (Exception ignored) {
        }

        return null;
    }
}