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
            className__c        = truncate(className, 255),
            Method_Name__c       = truncate(methodName, 255),
            Error_Message__c     = truncate(ex.getMessage(), 255),
            Stack_Trace__c        = truncate(ex.getStackTraceString(), 255),
            Line_Number__c        = String.valueOf(ex.getLineNumber()),
            Request_Payload__c    = truncate(payload, 255)
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

    /**
     * Safely truncates a string to maxLen characters so inserts
     * never silently fail with STRING_TOO_LONG against the
     * Text(255) fields on Stainless_Error_Log__c.
     */
    private static String truncate(String value, Integer maxLen) {
        if (String.isBlank(value)) {
            return value;
        }
        return value.length() > maxLen ? value.substring(0, maxLen) : value;
    }
}