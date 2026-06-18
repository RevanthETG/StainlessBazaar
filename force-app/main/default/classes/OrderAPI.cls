public with sharing class OrderAPI {

    @InvocableMethod(label='Get Customer Orders - Stainless Bazaar')
    public static List<OrderResponse> getCustomerOrders(List<OrderRequest> requests) {

        List<OrderResponse> responses = new List<OrderResponse>();

        for (OrderRequest request : requests) {
            OrderResponse response = new OrderResponse();

            try {
                if (String.isBlank(request.phone)) {
                    response.success = false;
                    response.message = 'Phone number is required.';
                    responses.add(response);
                    continue;
                }

                Http http = new Http();
                HttpRequest req = new HttpRequest();

                // Using Named Credential 
                req.setEndpoint('callout:StainlessBazaar/sales-force/customer_orders?phone=' +
                    EncodingUtil.urlEncode(request.phone, 'UTF-8'));
                req.setMethod('GET');
                req.setHeader('Content-Type', 'application/json');
                req.setTimeout(20000);

                HttpResponse res = http.send(req);

                response.httpStatusCode = res.getStatusCode();
                response.rawBody = res.getBody();

                System.debug('ORDER API STATUS -> ' + res.getStatusCode());
                System.debug('ORDER API BODY -> ' + res.getBody());

                if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                    ApiResponse apiResponse =
                        (ApiResponse) JSON.deserialize(res.getBody(), ApiResponse.class);

                    response.success = true;
                    response.apiStatusCode = apiResponse.statusCode;
                    response.message = apiResponse.message;

                    if (apiResponse.data != null) {
                        response.memberId = apiResponse.data.memberId;
                        response.memberPhone = apiResponse.data.member_phone;
                        response.memberName = apiResponse.data.member_name;
                        response.leads = apiResponse.data.leads;
                    }
                } else {
                    response.success = false;
                    response.message = 'API Error: ' + res.getStatusCode() + ' | ' + res.getBody();
                }

            } catch (Exception e) {
                ErrorLogger.logError('OrderAPI', 'getCustomerOrders', e, JSON.serialize(request));
                response.success = false;
                response.message = 'Exception: ' + e.getMessage();
                System.debug('ORDER API ERROR -> ' + e.getMessage());
            }

            responses.add(response);
        }

        System.debug('ORDER API FINAL RESPONSES -> ' + JSON.serializePretty(responses));

        return responses;
    }

    public class OrderRequest {
        @InvocableVariable(required=true)
        public String phone;
    }

    public class OrderResponse {
        @InvocableVariable public Boolean success;
        @InvocableVariable public Integer httpStatusCode;
        @InvocableVariable public Integer apiStatusCode;
        @InvocableVariable public String message;

        @InvocableVariable public Integer memberId;
        @InvocableVariable public String memberPhone;
        @InvocableVariable public String memberName;

        @InvocableVariable public List<LeadOrder> leads;

        @InvocableVariable public String rawBody;
    }

    public class ApiResponse {
        public Integer statusCode;
        public OrderData data;
        public String message;
        public Object pagination;
    }

    public class OrderData {
        public Integer memberId;
        public String member_phone;
        public String member_name;
        public List<LeadOrder> leads;
    }

    public class LeadOrder {
        @InvocableVariable public Integer id;
        @InvocableVariable public Integer leadStatus;
        @InvocableVariable public String leadStatusName;
        @InvocableVariable public String productCategory;
        @InvocableVariable public String productDescription;
        @InvocableVariable public Integer deliveryInDays;
        @InvocableVariable public String state;
        @InvocableVariable public String deliveryCity;
        @InvocableVariable public String brand;
        @InvocableVariable public String ssGrade;
        @InvocableVariable public String subGrade;
        @InvocableVariable public String invoiceDate;
    }
}