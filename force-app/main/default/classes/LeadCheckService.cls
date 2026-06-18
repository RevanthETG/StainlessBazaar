public with sharing class LeadCheckService {

    @InvocableMethod(label='Check LeadCheckService Apex Stock and Fetch Price - Stainless Bazar')
    public static List<LeadCheckResponse> checkStockAndPrice(List<LeadCheckRequest> requests) {

        List<LeadCheckResponse> responses = new List<LeadCheckResponse>();

        for (LeadCheckRequest request : requests) {

            LeadCheckResponse response = new LeadCheckResponse();

            try {
                RequestWrapper body = new RequestWrapper();

                if (String.isNotBlank(request.userPhone)) {
                    body.user_phone = request.userPhone;
                } else if (String.isNotBlank(request.userName)) {
                    body.user_name = request.userName;
                } else if (String.isNotBlank(request.userEmail)) {
                    body.user_email = request.userEmail;
                } else {
                    response.summary = 'User identifier missing.';
                    responses.add(response);
                    continue;
                }

                body.lead = new LeadWrapper();
                body.lead.product_category = request.productCategory;
                body.lead.product_description = request.productDescription;
                body.lead.delivery_in_days = request.deliveryInDays == null ? null : String.valueOf(request.deliveryInDays);
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

                ProductSpecWrapper spec = new ProductSpecWrapper();
                spec.thickness = request.thickness;
                spec.size = request.size;
                spec.finish = request.finish;
                spec.quantity = request.quantity;
                spec.unit = request.unit;

                body.productSpecification = new List<ProductSpecWrapper>{ spec };

                body.memberCreate = new MemberCreateWrapper();
                body.memberCreate.ownerContactNumber = request.ownerContactNumber;
                body.memberCreate.companyName = request.companyName;
                body.memberCreate.ownerName = request.ownerName;
                body.memberCreate.contactPerson = request.contactPerson;
                body.memberCreate.email = request.memberEmail;
                body.memberCreate.contactPersonNo = request.contactPersonNo;
                body.memberCreate.address = request.address;
                body.memberCreate.pincode = request.pincode;
                body.memberCreate.memberState = request.memberState;
                body.memberCreate.city = request.city;
                body.memberCreate.businessCategory = request.businessCategory;
                body.memberCreate.memberType = request.memberType;
                body.memberCreate.gstNo = request.gstNo;

                String jsonBody = JSON.serialize(body);
                System.debug('REQUEST JSON -> ' + jsonBody);

                Http http = new Http();
                HttpRequest req = new HttpRequest();

                req.setEndpoint('https://stagingevolveapi.stainlessbazaar.com/sales-force/whatsapp_lead_check_stock_fetch_price');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('x-access-token', 'SBZ-SECURE-KEY-8eab41d0-51ce-4f1b-a6d2-f93f1c3e5b7f');
                req.setBody(jsonBody);

                HttpResponse res = http.send(req);

                System.debug('RESPONSE STATUS -> ' + res.getStatusCode());
                System.debug('RESPONSE BODY -> ' + res.getBody());

                if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {

                    ResponseWrapper apiResponse =
                        (ResponseWrapper) JSON.deserialize(res.getBody(), ResponseWrapper.class);

                    if (apiResponse != null && apiResponse.data != null) {
                        response.stockAvailable = apiResponse.data.stock_availability;
                        response.minOfferPrice = apiResponse.data.min_offer_price;
                        response.priceToUser = apiResponse.data.price_to_user;

                        if (apiResponse.data.lead != null) {
                            response.leadId = apiResponse.data.lead.id;
                            response.leadType = apiResponse.data.lead.leadType;
                            response.leadStatus = String.valueOf(apiResponse.data.lead.leadStatus);

                            if (apiResponse.data.lead.createdUpdatedDate != null) {
                                response.createdAt = apiResponse.data.lead.createdUpdatedDate.createdAt;
                            }
                        }

                        response.summary = 'Success';
                    } else {
                        response.summary = 'Success, but empty API response data.';
                    }

                } else {
                    response.summary = 'API Error: ' + res.getStatus() + ' - ' + res.getBody();
                }

            } catch (Exception e) {
                ErrorLogger.logError('LeadCheckService', 'checkStockAndPrice', e, JSON.serialize(request));
                response.summary = 'Exception: ' + e.getMessage();
                System.debug('ERROR -> ' + e.getMessage());
            }

            responses.add(response);
        }

        return responses;
    }

   

    public class RequestWrapper {
        public String user_phone;
        public String user_name;
        public String user_email;
        public LeadWrapper lead;
        public List<ProductSpecWrapper> productSpecification;
        public MemberCreateWrapper memberCreate;
    }

    public class LeadWrapper {
        public String product_category;
        public String product_description;
        public String delivery_in_days;
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

    public class ProductSpecWrapper {
        public String thickness;
        public String size;
        public String finish;
        public Decimal quantity;
        public String unit;
    }

    public class MemberCreateWrapper {
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

    public class ResponseWrapper {
        public DataWrapper data;
    }

    public class DataWrapper {
        public String stock_availability;
        public Decimal min_offer_price;
        public Decimal price_to_user;
        public LeadData lead;
    }

    public class LeadData {
        public String id;
        public String leadType;
        public Integer leadStatus;
        public DateWrapper createdUpdatedDate;
    }

    public class DateWrapper {
        public String createdAt;
    }

    public class LeadCheckRequest {
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

        @InvocableVariable public String ownerContactNumber;
        @InvocableVariable public String companyName;
        @InvocableVariable public String ownerName;
        @InvocableVariable public String contactPerson;
        @InvocableVariable public String memberEmail;
        @InvocableVariable public String contactPersonNo;
        @InvocableVariable public String address;
        @InvocableVariable public String pincode;
        @InvocableVariable public String memberState;
        @InvocableVariable public String city;
        @InvocableVariable public String businessCategory;
        @InvocableVariable public String memberType;
        @InvocableVariable public String gstNo;
    }

    public class LeadCheckResponse {
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