@IsTest
private class ErrorLoggerTest {

    @IsTest
    static void testErrorLoggerInsert() {

        Test.startTest();

        try {
            throw new CalloutException('simulated callout failure');
        } catch (Exception e) {
            ErrorLogger.logError(
                'TestClass',
                'testMethod',
                e,
                '{"sample":"payload"}'
            );
        }

        Test.stopTest();

        List<Stainless_Error_Log__c> logs = [
            SELECT ClassName__c,
                   Method_Name__c,
                   Error_Message__c,
                   Stack_Trace__c,
                   Request_Payload__c
            FROM Stainless_Error_Log__c
        ];

        System.assertEquals(1, logs.size());
        System.assertEquals('TestClass', logs[0].ClassName__c);
        System.assertEquals(
            'simulated callout failure',
            logs[0].Error_Message__c
        );
        System.assertEquals(
            '{"sample":"payload"}',
            logs[0].Request_Payload__c
        );
    }

    @IsTest
    static void testErrorLoggerOverloadWithoutPayload() {

        Test.startTest();

        try {
            Integer x = 1 / 0; // Generates an exception
        } catch (Exception e) {
            ErrorLogger.logError(
                'TestClass',
                'testMethod2',
                e
            );
        }

        Test.stopTest();

        List<Stainless_Error_Log__c> logs = [
            SELECT Id,
                   Request_Payload__c
            FROM Stainless_Error_Log__c
        ];

        System.assertEquals(1, logs.size());
        System.assertEquals(null, logs[0].Request_Payload__c);
    }
}