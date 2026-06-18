public without sharing class ErrorLogger {

    public static void logError(String className, String methodName, Exception ex) {
        logError(className, methodName, ex, null);
    }

    public static void logError(
        String className,
        String methodName,
        Exception ex,
        String payload
    ) {
        Stainless_Error_Log__c log = new Stainless_Error_Log__c(
            ClassName__c = className,
            Method_Name__c = methodName,
            Error_Message__c = ex.getMessage(),
            Stack_Trace__c = ex.getStackTraceString(),
            Line_Number__c = String.valueOf(ex.getLineNumber()),
            Request_Payload__c = payload
        );

        try {
            insert log;
        } catch (Exception loggingEx) {
            System.debug(
                LoggingLevel.ERROR,
                'Error Logger failed: ' + loggingEx.getMessage()
            );
        }
    }
}