@IsTest
public without sharing class OnboardingAddonUserTriggerHandlerTest {
    
    @isTest
    public static void setAddonPermissionWithUsers(){
        
        UserRole userRole = new UserRole(Name = 'SEO TEST');
        insert userRole;
        
        User admin = new User(Id = UserInfo.getUserId(), UserRoleId = userRole.Id);
        update admin;
        
        User newUser;
        
        System.runAs(admin){
            Account acc = new Account(name = 'Community teste');
            insert acc;
            
            Contact contact = new Contact();
            contact.FirstName = 'FirstName';
            contact.LastName = 'lastName';
            contact.AccountId = acc.Id;
            contact.Email = 'test@test.com';
            contact.Atonit_Mktplace__Area__c = 'Commercial';
            contact.Atonit_Mktplace__Post__c = 'Post';
            insert contact; 
            
            Profile profile = [SELECT Id, Name FROM Profile Where Name = 'Customer Community Plus User' Limit 1];        
            
            newUser = new User(
                profileId = profile.id, 
                username = 'test@test.com.'+System.currentTimeMillis(), 
                email = 'test@test.com.'+System.currentTimeMillis(),
                emailencodingkey = 'UTF-8', 
                localesidkey = 'en_US', 
                languagelocalekey = 'en_US', 
                timezonesidkey = 'America/Los_Angeles', 
                Atonit_Mktplace__Api_ExternalId_Prefix__c = 'community-teste',
                alias= String.valueOf(System.currentTimeMillis()).substring(0,8),
                lastname= 'Community teste user',
                contactId = contact.id
            );
            
            Test.startTest();
            insert newUser;  
            Test.stopTest();
        }
        
        Id permissionSetId = [SELECT Id 
                              FROM PermissionSet 
                              WHERE Name = 'Commerce_marketplace_Onboarding_addon'
                              WITH SYSTEM_MODE
                              LIMIT 1].Id;
        
        System.assertNotEquals(null, 
                               [SELECT id FROM PermissionSetAssignment WHERE PermissionSetId =: permissionSetId LIMIT 1], 
                               'PermissionSetAssignment can not be null!');
    }    
    
    @IsTest
    public static void setAddonPermissionWithoutUsers(){
        Profile profile = [SELECT Id, Name FROM Profile LIMIT 1];        
        
        User newUser = new User(
            profileId = profile.id, 
            username = 'test@test.com.'+System.currentTimeMillis(), 
            email = 'test@test.com.'+System.currentTimeMillis(),
            emailencodingkey = 'UTF-8', 
            localesidkey = 'en_US', 
            languagelocalekey = 'en_US', 
            timezonesidkey = 'America/Los_Angeles', 
            alias= String.valueOf(System.currentTimeMillis()).substring(0,8),
            lastname= 'Community teste user'
        );
        
        Test.startTest();
        insert newUser;  
        Test.stopTest();
        
        Id permissionSetId = [SELECT Id 
                              FROM PermissionSet 
                              WHERE Name = 'Commerce_marketplace_Onboarding_addon'
                              WITH SYSTEM_MODE
                              LIMIT 1].Id;
        
        System.assertEquals(true, 
                            [SELECT id FROM PermissionSetAssignment WHERE AssigneeId =: newUser.Id AND PermissionSetId =: permissionSetId].isEmpty(), 
                            'PermissionSetAssignment must to be null!');
    }
}