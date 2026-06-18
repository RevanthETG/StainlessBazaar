public class Customer_status {
    
    // Invocable method for use in Flow or Agentforce
    @InvocableMethod(label='Check Customer Status and Update Lead' 
                     description='Calls Stainless Bazaar API to check customer status and update lead'
                     category='Stainless Bazaar')
    public static List<APIResponse> checkCustomerStatusAndUpdateLead(List<APIRequest> requests) {
        List<APIResponse> responses = new List<APIResponse>();
        
        for (APIRequest request : requests) {
            responses.add(makeAPICallout(request));
        }
        
        return responses;
    }
    
    // Main method to make the API callout
    public static APIResponse makeAPICallout(APIRequest request) {
        APIResponse response = new APIResponse();
        
        try {
            // Validate that at least one identifier is provided
            if (String.isBlank(request.member_email) && 
                String.isBlank(request.member_phone) && 
                String.isBlank(request.member_name)) {
                response.summary = 'Error: At least one identifier (email, phone, or name) must be provided';
                return response;
            }
            
            // Prepare the HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:StainlessBazaar/sales-force/check-customer-status-and-update-lead');
            req.setMethod('POST');
            req.setHeader('Content-Type','application/json');
            // FIX 1: Removed premature req.setBody(jsonBody) and duplicate setTimeout(20000).
            //         Timeout is set once below after building the body.
            
            // Build the request body dynamically based on provided inputs
            Map<String, Object> requestBody = new Map<String, Object>();
            
            // Add member identifier based on what's provided
            if (String.isNotBlank(request.member_email)) {
                requestBody.put('member_email', request.member_email);
            }
            if (String.isNotBlank(request.member_phone)) {
                requestBody.put('member_phone', request.member_phone);
            }
            if (String.isNotBlank(request.member_name)) {
                requestBody.put('member_name', request.member_name);
            }
            
            // Add lead details only if provided
            if (request.leadId != null) {
                requestBody.put('leadId', request.leadId);
            }
            if (String.isNotBlank(request.leadStatus)) {
                requestBody.put('leadStatus', request.leadStatus);
            }
            
            // FIX 2: Added missing fields that were declared in APIRequest but never sent
            if (String.isNotBlank(request.price))     requestBody.put('price', request.price);
            if (String.isNotBlank(request.quantity))  requestBody.put('quantity', request.quantity);
            if (String.isNotBlank(request.thickness)) requestBody.put('thickness', request.thickness);
            if (String.isNotBlank(request.size))      requestBody.put('size', request.size);
            if (String.isNotBlank(request.finish))    requestBody.put('finish', request.finish);
            
            System.debug('Request Body: ' + requestBody);
            req.setBody(JSON.serialize(requestBody));
            req.setTimeout(120000); // 120 seconds timeout
            
            // Make the callout
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            System.debug('Response Status: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());
            
            // Process the response
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> data = (Map<String, Object>) responseMap.get('data');
                Map<String, Object> customerStatus = (Map<String, Object>) data.get('customerStatus');
                
                // Parse customer details
                response.memberId = String.valueOf(customerStatus.get('memberId'));
                response.member_email = (String) customerStatus.get('member_email');
                response.member_phone = (String) customerStatus.get('member_phone');
                response.member_name = (String) customerStatus.get('member_name');
                response.memberStatus = (String) customerStatus.get('member_status');
                
                // Parse buyer manager details
                response.buyerManagerFirstName = (String) customerStatus.get('buyerManagerFirstName');
                response.buyerManagerLastName = (String) customerStatus.get('buyerManagerLastName');
                response.buyerManagerEmail = (String) customerStatus.get('buyerManagerEmail');
                response.buyerManagerPhone = (String) customerStatus.get('buyerManagerPhone');
                
                response.message = (String) responseMap.get('message');
                
                // Build summary
                response.summary = 'Customer found: ' + response.member_name + ' (ID: ' + response.memberId + '). ' +
                                 'Status: ' + response.memberStatus + '. ' +
                                 'Email: ' + response.member_email + ', Phone: ' + response.member_phone + '. ' +
                                 'Buyer Manager: ' + response.buyerManagerFirstName + ' ' + response.buyerManagerLastName + 
                                 ' (Email: ' + response.buyerManagerEmail + ', Phone: ' + response.buyerManagerPhone + ').';
                
            } else {
                response.summary = 'Error: HTTP ' + res.getStatusCode() + ' - ' + res.getStatus() + 
                                 '. Response: ' + res.getBody();
            }
            
        } catch (CalloutException e) {
            response.summary = 'Callout failed: ' + e.getMessage() + '. Please try again or contact support.';
        } catch (Exception e) {
            response.summary = 'An error occurred while checking customer status: ' + e.getMessage() + 
                             '. Please try again or contact support.';
        }
        
        return response;
    }
    
    // Input wrapper class for invocable method
    public class APIRequest {

        @InvocableVariable(label='Member Email' description='Customer email address' required=false)
        public String member_email;
        
        @InvocableVariable(label='Member Phone' description='Customer phone number' required=false)
        public String member_phone;
        
        @InvocableVariable(label='Member Name' description='Customer name' required=false)
        public String member_name;
        
        @InvocableVariable(label='Lead ID' description='Salesforce Lead ID' required=false)
        public Integer leadId;
        
        @InvocableVariable(label='Lead Status' description='Status of the lead' required=false)
        public String leadStatus;

        @InvocableVariable(label='price' description='price agreed on negotiation' required=false)
        public String price;

        @InvocableVariable(label='quantity' description='quantity of the product' required=false)
        public String quantity;

        @InvocableVariable(label='thickness' description='thickness of the product' required=false)
        public String thickness;

        @InvocableVariable(label='size' description='size of the product' required=false)
        public String size;

        @InvocableVariable(label='finish' description='finish of the product' required=false)
        public String finish;
    }
    
    // Output wrapper class for invocable method
    public class APIResponse {
        @InvocableVariable(description='Member ID of the customer')
        public String memberId;
        
        @InvocableVariable(description='Email address of the customer')
        public String member_email;
        
        @InvocableVariable(description='Phone number of the customer')
        public String member_phone;
        
        @InvocableVariable(description='Name of the customer')
        public String member_name;
        
        @InvocableVariable(description='Current status of the customer (active/inactive)')
        public String memberStatus;
        
        @InvocableVariable(description='Buyer Manager First Name')
        public String buyerManagerFirstName;
        
        @InvocableVariable(description='Buyer Manager Last Name')
        public String buyerManagerLastName;
        
        @InvocableVariable(description='Buyer Manager Email')
        public String buyerManagerEmail;
        
        @InvocableVariable(description='Buyer Manager Phone')
        public String buyerManagerPhone;
        
        @InvocableVariable(description='Response message from the API')
        public String message;
        
        @InvocableVariable(description='Human-readable summary of the customer check results for the agent')
        public String summary;
        
        public APIResponse() {
            this.memberId = '';
            this.member_email = '';
            this.member_phone = '';
            this.member_name = '';
            this.memberStatus = '';
            this.buyerManagerFirstName = '';
            this.buyerManagerLastName = '';
            this.buyerManagerEmail = '';
            this.buyerManagerPhone = '';
            this.message = '';
            this.summary = '';
        }
    }
}