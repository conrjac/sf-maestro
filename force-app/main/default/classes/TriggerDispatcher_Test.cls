@IsTest
private class TriggerDispatcher_Test {
    @IsTest
    static void beforeUpdate_runsEnabledHandlersInOrder() {
       
        Trigger_Handler__mdt rec1 = new Trigger_Handler__mdt(
            DeveloperName    = 'Acct_BeforeUpdate_Normalize',
            MasterLabel      = 'Acct BeforeUpdate Normalize',
            SObject_Type__c       = 'Account',
            Event__c         = 'beforeUpdate',
            Handler_Class__c = 'AccountNameNormalizerHandler',
            Is_Enabled__c    = true,
            Sequence__c      = 10
        );
        Trigger_Handler__mdt rec2 = new Trigger_Handler__mdt(
            DeveloperName    = 'Acct_BeforeUpdate_IndustryDefaults',
            MasterLabel      = 'Acct BeforeUpdate Industry Defaults',
            SObject_Type__c        = 'Account',
            Event__c         = 'beforeUpdate',
            Handler_Class__c = 'AccountIndustryDefaultsHandler',
            Is_Enabled__c    = true,
            Sequence__c      = 20
        );

        Account a = new Account(Name='  Acme  ', Type='Prospect');
        insert a;
        a.Type = 'Customer';
        update a;

        Account got = [SELECT Name, Industry, Type FROM Account WHERE Id = :a.Id];
        System.assertEquals('Acme', got.Name, 'Name trimmed by first handler');
        System.assertEquals('Manufacturing', got.Industry, 'Defaulted by second handler');
        System.assertEquals('Customer', got.Type);
    }

    @IsTest
    static void disabledHandler_doesNotRun() {
        Trigger_Handler__mdt rec3 = new Trigger_Handler__mdt(
            DeveloperName    = 'Acct_AfterInsert_WelcomeTask',
            MasterLabel      = 'Acct AfterInsert Welcome Task',
            SObject_Type__c   = 'Account',
            Event__c         = 'afterInsert',
            Handler_Class__c = 'AccountWelcomeTaskHandler',
            Is_Enabled__c    = false,
            Sequence__c      = 10
        );

        insert new Account(Name='No Task Please');

        // Assert no tasks created, etc.
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE Subject = 'Welcome'], 'Disabled means no run');
    }
}