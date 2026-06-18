public with sharing class Lead_Check_New_User {

    @InvocableMethod(label='Check LeadCheckService for new user - Stainless Bazar')
    public static List<LeadCheckResponse> checkStockAndPrice(List<LeadCheckRequest> requests) {

        List<LeadCheckResponse> responses = new List<LeadCheckResponse>();

        for (LeadCheckRequest request : requests) {

            LeadCheckResponse response = new LeadCheckResponse();

            try {

                RequestWrapper body = new RequestWrapper();

                // -------- USER IDENTIFIER --------
                if(String.isNotBlank(request.userPhone)){
                    body.user_phone = request.userPhone;
                }
                else if(String.isNotBlank(request.userName)){
                    body.user_name = request.userName;
                }
                else if(String.isNotBlank(request.userEmail)){
                    body.user_email = request.userEmail;
                }
                else{
                    response.summary = 'User identifier missing.';
                    responses.add(response);
                    continue;
                }

                // -------- LEAD DETAILS --------
                body.lead = new LeadWrapper();
                body.lead.product_category = request.productCategory;
                body.lead.product_description = request.productDescription;
                body.lead.delivery_in_days = request.deliveryInDays;
                body.lead.state = request.state;
                body.lead.delivery_city = request.deliveryCity;
                body.lead.brand = request.brand;
                body.lead.ss_grade = request.ssGrade;
                body.lead.sub_grade = request.subGrade;
                body.lead.lead_type = request.leadType;
                body.lead.lead_source = request.leadSource;
                body.lead.lead_status = request.leadStatus;
                body.lead.remark = request.remark;
                body.lead.journey_id = request.journeyId;
                body.lead.buyer_type_id = request.buyerTypeId;

                // -------- PRODUCT SPEC --------
                ProductSpecWrapper spec = new ProductSpecWrapper();
                spec.thickness = request.thickness;
                spec.size = request.size;
                spec.finish = request.finish;
                spec.quantity = request.quantity;
                spec.unit = request.unit;

                body.productSpecification = new List<ProductSpecWrapper>{spec};

                // -------- MEMBER CREATE --------
                body.memberCreate = new NewMemberWrapper();
                body.memberCreate.ownerContactNumber = request.userPhone;
                body.memberCreate.companyName = request.userName;
                body.memberCreate.ownerName = request.ownerName;
                body.memberCreate.contactPerson = request.ownerName;
                body.memberCreate.email = request.userEmail;
                body.memberCreate.contactPersonNo = request.userPhone;
                body.memberCreate.address = request.address;
                body.memberCreate.pincode = request.pincode;
                body.memberCreate.memberState = request.memberState;
                body.memberCreate.city = request.city;
                body.memberCreate.businessCategory = request.businessCategory;
                body.memberCreate.memberType = request.memberType;
                body.memberCreate.gstNo = request.gstNo;

                // -------- SERIALIZE JSON --------
                String jsonBody = JSON.serialize(body);

                System.debug('REQUEST JSON -> ' + jsonBody);

                // -------- HTTP CALLOUT --------
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                //code here

                req.setEndpoint('callout:StainlessBazaar/sales-force/whatsapp_lead_check_stock_fetch_price');
                req.setMethod('POST');
                req.setHeader('Content-Type','application/json');
                req.setTimeout(20000);
                req.setBody(jsonBody);

                HttpResponse res = http.send(req);

                Integer statusCode = res.getStatusCode();
                String responseBody = res.getBody();

                System.debug('RESPONSE STATUS -> ' + statusCode);
                System.debug('RESPONSE BODY -> ' + responseBody);

                // -------- HANDLE RESPONSE --------
                if(statusCode >= 200 && statusCode < 300){

                    ResponseWrapper apiResponse =
                        (ResponseWrapper) JSON.deserialize(responseBody, ResponseWrapper.class);

                    if(apiResponse != null && apiResponse.data != null){

                        response.stockAvailable = apiResponse.data.stock_availability;
                        response.minOfferPrice = apiResponse.data.min_offer_price;
                        response.priceToUser = apiResponse.data.price_to_user;

                        if(apiResponse.data.lead != null){
                            response.leadId = apiResponse.data.lead.id;
                            response.leadType = apiResponse.data.lead.leadType;
                            response.leadStatus = String.valueOf(apiResponse.data.lead.leadStatus);

                            if(apiResponse.data.lead.createdUpdatedDate != null){
                                response.createdAt = apiResponse.data.lead.createdUpdatedDate.createdAt;
                            }
                        }

                        response.summary = 'Success';
                    }
                    else{
                        response.summary = 'API returned empty response';
                    }

                }
                else{
                    response.summary = 'API Error: ' + statusCode + ' | ' + responseBody;
                }

            }
            catch(CalloutException ce){
                ErrorLogger.logError('Lead_Check_New_User', 'checkStockAndPrice', ce, JSON.serialize(request));
                response.summary = 'Callout Exception: ' + ce.getMessage();
                System.debug('ERROR -> ' + ce.getMessage());

            }
            catch(Exception e){
                ErrorLogger.logError('Lead_Check_New_User', 'checkStockAndPrice', e, JSON.serialize(request));
                response.summary = 'Exception: ' + e.getMessage();
                System.debug('ERROR -> ' + e.getMessage());

            }

            responses.add(response);
        }

        return responses;
    }

    // -------- REQUEST CLASSES --------

    public class RequestWrapper{
        public String user_phone;
        public String user_name;
        public String user_email;
        public LeadWrapper lead;
        public List<ProductSpecWrapper> productSpecification;
        public NewMemberWrapper memberCreate;
    }

    public class NewMemberWrapper{
        public String ownerContactNumber;
        public String companyName;
        public String ownerName;
        public String contactPerson;
        public String email;
        public String contactPersonNo;
        public String address;
        public String pincode;
        public String memberState;
        public String city;
        public String businessCategory;
        public String memberType;
        public String gstNo;
    }

    public class LeadWrapper{
        public String product_category;
        public String product_description;
        public Integer delivery_in_days;
        public String state;
        public String delivery_city;
        public String brand;
        public String ss_grade;
        public String sub_grade;
        public String lead_type;
        public String lead_source;
        public Integer lead_status;
        public String remark;
        public String journey_id;
        public String buyer_type_id;
    }

    public class ProductSpecWrapper{
        public String thickness;
        public String size;
        public String finish;
        public Decimal quantity;
        public String unit;
    }

    // -------- RESPONSE CLASSES --------

    public class ResponseWrapper{
        public DataWrapper data;
    }

    public class DataWrapper{
        public String stock_availability;
        public Decimal min_offer_price;
        public Decimal price_to_user;
        public LeadData lead;
    }

    public class LeadData{
        public String id;
        public String leadType;
        public Integer leadStatus;
        public DateWrapper createdUpdatedDate;
    }

    public class DateWrapper{
        public String createdAt;
    }

    // -------- FLOW INPUT --------

    public class LeadCheckRequest{

        @InvocableVariable public String userPhone;
        @InvocableVariable public String userName;
        @InvocableVariable public String userEmail;

        @InvocableVariable public String productCategory;
        @InvocableVariable public String productDescription;
        @InvocableVariable public Integer deliveryInDays;
        @InvocableVariable public String state;
        @InvocableVariable public String deliveryCity;
        @InvocableVariable public String brand;
        @InvocableVariable public String ssGrade;
        @InvocableVariable public String subGrade;
        @InvocableVariable public String leadType;
        @InvocableVariable public String leadSource;
        @InvocableVariable public Integer leadStatus;
        @InvocableVariable public String remark;
        @InvocableVariable public String journeyId;
        @InvocableVariable public String buyerTypeId;

        @InvocableVariable public String thickness;
        @InvocableVariable public String size;
        @InvocableVariable public String finish;
        @InvocableVariable public Decimal quantity;
        @InvocableVariable public String unit;

        @InvocableVariable public String ownerName;
        @InvocableVariable public String address;
        @InvocableVariable public String pincode;
        @InvocableVariable public String city;           // memberCreate.city (distinct from deliveryCity)
        @InvocableVariable public String memberState;    // NEW — memberCreate.memberState (distinct from lead state)
        @InvocableVariable public String businessCategory;
        @InvocableVariable public String memberType;
        @InvocableVariable public String gstNo;
    }

    // -------- FLOW OUTPUT --------

    public class LeadCheckResponse{

        @InvocableVariable public String stockAvailable;
        @InvocableVariable public Decimal minOfferPrice;
        @InvocableVariable public Decimal priceToUser;
        @InvocableVariable public String leadId;
        @InvocableVariable public String leadType;
        @InvocableVariable public String leadStatus;
        @InvocableVariable public String createdAt;
        @InvocableVariable public String summary;
    }
}