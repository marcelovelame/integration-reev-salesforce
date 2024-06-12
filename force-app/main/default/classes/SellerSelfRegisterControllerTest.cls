@isTest
public class SellerSelfRegisterControllerTest {
    
    @testSetup 
    static void setup(){
        UserRole role = new UserRole(DeveloperName = 'TesteRole', Name = 'Teste Role');
        insert role;
        
        Profile profileAdmin = [SELECT Id, Name FROM Profile Where Name = 'System Administrator' or Name = 'Administrador do sistema' Limit 1];
        
        User user = new User();
        user.Username = System.currentTimeMillis() + 'usertest@yopmail.com';
        user.FirstName = 'teste';
        user.LastName = 'teste admin';
        user.Alias = 'admin';
        user.CommunityNickname = 'usrBps';
        user.TimeZoneSidKey = 'America/Sao_Paulo';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.LocaleSidKey = 'pt_BR';
        user.LanguageLocaleKey = 'pt_BR';
        user.Email = System.currentTimeMillis() +'test@yopmail.com';
        user.ProfileId = profileAdmin.Id;
        user.IsActive = true;      
        user.Atonit_Mktplace__Api_ExternalId_Prefix__c = 'admin';
        user.UserRoleId = role.Id;
        insert user;
        
        Id adminPermission = [SELECT Id FROM PermissionSet WHERE Name = 'Marketplace_Admin'][0].Id;
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :user.Id AND PermissionSetId = :adminPermission] == 0)
            insert new PermissionSetAssignment(
                AssigneeId = user.Id,
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Marketplace_Admin'][0].Id
            );
        
        
        System.runAs(user) { 
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
            
            Contact contact2 = new Contact();
            contact2.FirstName = 'FirstName2';
            contact2.LastName = 'lastName2';
            contact2.AccountId = acc.Id;
            contact2.Email = 'test2@test.com';       
            contact2.Atonit_Mktplace__Area__c = 'Commercial';
            contact2.Atonit_Mktplace__Post__c = 'Post';
            insert contact2; 
            
            Profile profile = [SELECT Id, Name FROM Profile Where Name = 'Customer Community Plus User' Limit 1];
            UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
            
            
            User newUser = new User(
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
            insert newUser;         
        }
        
        User newUser = [SELECT Id, Atonit_Mktplace__Api_ExternalId_Prefix__c FROM User WHERE lastname= 'Community teste user' LIMIT 1];
        System.runAs(newUser) { 
            Atonit_Mktplace__Seller__c newSeller = new Atonit_Mktplace__Seller__c();                   
            newSeller.Atonit_Mktplace__Account__c = [SELECT Id FROM Account WHERE name = 'Community teste' LIMIT 1].Id;            
            newSeller.OwnerId = newUser.Id;
            newSeller.Atonit_Mktplace__Reproved_Message__c = 'test';
            newSeller.Atonit_Mktplace__Slug__c = 'community-teste';
            insert newSeller;
        }
        
    }  
    
    @IsTest
    static void testIsValidPassword() {
        Test.startTest();
        Boolean resp = SellerSelfRegisterController.isValidPassword('password?@12334', 'password?@12334'); 
        Test.stopTest();
        System.assert(resp == true);   
    } 
    
    @IsTest
    static void testNotValidPassword() {
        Test.startTest();
        Boolean resp = SellerSelfRegisterController.isValidPassword('password?@12334', 'dummyPassword'); 
        Test.stopTest();
        System.assert(resp == false);        
    }
    
    @IsTest
    static void testChangePassword() {
        Test.startTest();
        String resp = SellerSelfRegisterController.changePassword('password?@12334', 'password?@12334');
        Test.stopTest();
        System.assert(resp == null);
    }
    
    @IsTest
    static void testSiteAsContainerEnabled() {
        Test.startTest();
        Boolean resp = SellerSelfRegisterController.siteAsContainerEnabled('https://portaleu1-developer-edition.eu11.force.com');
        Test.stopTest();
        System.assertNotEquals(null,resp);
    }
    
    @IsTest
    static void testSiteAsContainerNotEnabled() {
        Test.startTest();
        Boolean resp = SellerSelfRegisterController.siteAsContainerEnabled('https://portal.force.com');
        Test.stopTest();
        System.assert(resp == false);
    }
    
    @IsTest
    static void testuserContactData() {
        Account acc = [SELECT Id, Name FROM Account Where name = 'Community teste' Limit 1];
        Test.startTest();
        List<Contact> resp = SellerSelfRegisterController.getUserContactData(acc.Id);
        Test.stopTest();
        System.assert(!resp.isEmpty());
    }
    
    @IsTest
    static void testLoggedUser() { 
        Account accountUserData = new Account(name = 'test Account UserData');
        insert accountUserData;
        User user = [SELECT Id, Email FROM User Where LastName = 'Community teste user' Limit 1];       
        System.runAs(user) { 
            Test.startTest();            
            String resp = SellerSelfRegisterController.getLoggedUser();
            Test.stopTest();   
            System.assert(resp != 'notlogged');
        }                
    }
    
    @IsTest
    static void testUserData() { 
        User user = [SELECT Id, Email FROM User Where LastName = 'Community teste user' Limit 1];       
        System.runAs(user) {
            Test.startTest();
            List<SObject> resp = SellerSelfRegisterController.getUserData();
            Test.stopTest();
            System.assert(!resp.isEmpty());
        }
    }
    
    @IsTest
    static void testgetFieldsHelpText() { 
        Test.startTest();
        Map<String, String> resp = SellerSelfRegisterController.getFieldsHelpText();
        Test.stopTest();
        System.assert(!resp.isEmpty());
    }
    
    @IsTest
    static void testGetReprovedMessage() { 
        Account accountUserData = new Account(name = 'test Account UserData');
        insert accountUserData;
        User user = [SELECT Id, Email FROM User Where LastName = 'Community teste user' Limit 1];       
        System.runAs(user) { 
            Test.startTest();            
            String resp = SellerSelfRegisterController.getReprovedMessage();
            Test.stopTest();   
            System.assert(resp == 'test');
        }
        
    }
    
    @IsTest
    static void testSaveDraft() {        
        User user = [SELECT Id, Email FROM User Where LastName = 'teste admin' Limit 1];
        Map < String, String > paramsMap = initializeParams();        																																																																																				 																						                                                                                                                                                                                                                                                                
        //System.runAs(user) { 
        Test.startTest();
        Map<String, String> resp = SellerSelfRegisterController.saveDraft(true, '', paramsMap.get('Country'), paramsMap.get('CompanyType'),'Teste Name teste',paramsMap.get('State'),paramsMap.get('City'),paramsMap.get('Phone'),paramsMap.get('Email'),paramsMap.get('Password'),paramsMap.get('ConfirmPassword'),true);      
        
        Test.stopTest();
        system.debug(resp);
        System.assert(resp.get('accountId') != null);  
        // }
    }    
    
    @IsTest
    static void testSaveDraftDisplayName() {
        Account acc = [SELECT Id, Name FROM Account Where name = 'Community teste' Limit 1];
        User user = [SELECT Id, Email FROM User Where LastName = 'Community teste user' Limit 1];
        Atonit_Mktplace__Seller__c seller = [SELECT Id, Atonit_Mktplace__Display_Name__c FROM Atonit_Mktplace__Seller__c Where OwnerId =: user.Id  Limit 1];
        
        Map < String, String > paramsMap = initializeParams();        																																																																																				 																						                                                                                                                                                                                                                                                        
        Test.startTest();            
        Map<String, String> resp = SellerSelfRegisterController.saveDraft(true, '', paramsMap.get('Country'), paramsMap.get('CompanyType'),seller.Atonit_Mktplace__Display_Name__c ,paramsMap.get('State'),paramsMap.get('City'),paramsMap.get('Phone'),paramsMap.get('Email'),paramsMap.get('Password'),paramsMap.get('ConfirmPassword'),true);
        Test.stopTest();
        System.assert(resp.get('error') == 'Display Name already registered');
        
    }
    
    @IsTest
    static void testSaveDraftUpdateAccount() {
        Account acc = [SELECT Id, Name FROM Account Where name = 'Community teste' Limit 1]; 
        User user = [SELECT Id, Email FROM User Where LastName = 'Community teste user' Limit 1];
        
        Map < String, String > paramsMap = initializeParams(); 
        Map<String, String> resp;
        Test.startTest(); 
        System.runAs(user){
            resp = SellerSelfRegisterController.saveDraft(true, acc.Id, paramsMap.get('Country'), paramsMap.get('CompanyType'),paramsMap.get('Name'),paramsMap.get('State'),paramsMap.get('City'),paramsMap.get('Phone'),'testnew2@testenew.com',paramsMap.get('Password'),paramsMap.get('ConfirmPassword'),true);
        }
        Test.stopTest();         
        System.assert(resp.get('accountId') == acc.Id);        
    } 
    
    @IsTest
    static void testSaveDraftPasswordsDontmatch() {        
        Map < String, String > paramsMap = initializeParams(); 
        Test.startTest();
        Map<String, String>  resp = SellerSelfRegisterController.saveDraft(true, '', paramsMap.get('Country'), paramsMap.get('CompanyType'),'Name teste 0'+System.currentTimeMillis(),paramsMap.get('State'),paramsMap.get('City'),paramsMap.get('Phone'),paramsMap.get('Email'),'123QWE123',paramsMap.get('ConfirmPassword'),true);
        Test.stopTest();
        System.assert(resp.get('error') == Label.site.passwords_dont_match);       
    } 
    
    @IsTest
    static void testUpdateSellerApi() { 
        User user = [SELECT Id, Email FROM User Where LastName = 'Community teste user' Limit 1];
        Atonit_Mktplace__Seller__c seller = [SELECT Id, Atonit_Mktplace__Display_Name__c FROM Atonit_Mktplace__Seller__c Where OwnerId =: user.Id  Limit 1];
        AuraHandledException exp = null;
        Test.startTest(); 
        try {
            String resp = SellerSelfRegisterController.updateSellerApi(seller.Id);
        } catch (AuraHandledException expectedException) {
            exp = expectedException;
        }
        Test.stopTest();
        System.assertEquals(null, exp);   
    }
    
    @IsTest
    static void testSaveDraftInvalid() {        
        Account acc = [SELECT Id, Name FROM Account Where name = 'Community teste' Limit 1];
        Map < String, String > paramsMap = initializeParams(); 
        Map<String, String> resp = new Map<String, String>();
        AuraHandledException exp = null;
        Test.startTest(); 
        try {
            SellerSelfRegisterController.saveDraft(true, '0000', paramsMap.get('Country'), paramsMap.get('CompanyType'),'Name teste 1'+System.currentTimeMillis(),paramsMap.get('State'),paramsMap.get('City'),paramsMap.get('Phone'),paramsMap.get('Email'),paramsMap.get('Password'),paramsMap.get('ConfirmPassword'),true);
        } catch (AuraHandledException expectedException) {
            exp = expectedException;
        }
        Test.stopTest();
        System.assert(resp.get('error') != '');       
    }   
    
    @IsTest
    static void LightningSelfRegisterControllerInstantiation() {
        SellerSelfRegisterController controller = new SellerSelfRegisterController();
        System.assertNotEquals(controller, null);
    }     
    
    @isTest
    static void testSetExperienceId() {
        Test.startTest();
        String resp = SellerSelfRegisterController.setExperienceId('123');
        Test.stopTest();
        System.assert(resp != null);
    }
    
    @isTest
    static void testInvalidSetExperienceId() {
        Test.startTest();
        String resp = SellerSelfRegisterController.setExperienceId(null);
        Test.stopTest();
        System.assert(resp == null);
    }
    
    @isTest
    static void testSaveContacts() {
        Account acc = [SELECT Id, Name FROM Account Where name = 'Community teste' Limit 1];      
        Contact contact =  [Select id from Contact where AccountId = :acc.Id order by CreatedDate asc limit 1];
        Test.startTest();
        String resp = SellerSelfRegisterController.saveContacts(acc.Id,'[{"Id":"'+contact.Id+'","Area":"Commercial","Post":"teste","Name":"teste","LastName":"teste","MobilePhone":"teste","Email":"testepdk1@yopmail.com"},{"Id":"1","Area":"Commercial","Post":"teste","Name":"teste","LastName":"rwrw","MobilePhone":"testepdk1@yopma","Email":"testepdk1@yopmail.com"}]"}}]');
        Test.stopTest();
        System.assert(resp == null);
    }  
    
    @isTest
    static void testInvalidSaveContacts() {                      
        AuraHandledException exp = null;
        Test.startTest(); 
        try {
            Account test = new Account();
            test.name = 'Acc';
            Insert test;
            SellerSelfRegisterController.saveContacts(test.Id,'[{"Id":"","teste":"Commercial"}]');
        } catch (AuraHandledException expectedException) {
            exp = expectedException;
        }
        Test.stopTest();
        
        System.assertEquals(null, exp);   
        
    }
    
    @isTest
    static void testUpdateSeller() {
        User user = [SELECT Id, Email FROM User Where LastName = 'Community teste user' Limit 1];  
        Atonit_Mktplace__Seller__c seller = [SELECT Id, Atonit_Mktplace__Display_Name__c FROM Atonit_Mktplace__Seller__c Where OwnerId =: user.Id  Limit 1];
        Test.startTest();      
        System.runAs(user) { 
            SellerSelfRegisterController.updateSeller(seller.Id,user.Email,'http://my.company.salesforce.com');
        }
        Test.stopTest();
        Atonit_Mktplace__Seller__c sellerAfterUpdate = [SELECT Id, Atonit_Mktplace__Status__c FROM Atonit_Mktplace__Seller__c Where OwnerId =: user.Id Limit 1]; 
        System.assert(sellerAfterUpdate.Atonit_Mktplace__Status__c == 'Pending');
    }
    
    @isTest
    static void testInvalidUpdateSeller() {                
        AuraHandledException exp = null;
        User user = [SELECT Id, Email FROM User Where LastName = 'Community teste user' Limit 1];  
        Test.startTest();
        try {
            System.runAs(user) { 
                SellerSelfRegisterController.updateSeller('teste123','teste@teste.com','http://my.company.salesforce.com');
            }
        } catch (AuraHandledException expectedException) {
            exp = expectedException;
        }
        Test.stopTest();
        
        System.assertEquals(null, exp);
    }
    
    public static Map < String, String > initializeParams() {
        
        Map < String, String > paramsMap = new Map < String, String > ();        
        String accountId = 'testuser123';
        String Country = 'Chile';
        String startUrl = 'http://my.company.salesforce.com';
        String CompanyType = 'Legal Entity';
        String Name = 'Name';
        String TaxId = '123456789';
        String State = 'State';
        String City = 'City';
        String Phone = '123456789';
        String Email = 'email@email.com';       
        String Password = 'Password123!@';
        String ConfirmPassword = 'Password123!@';        
        String AccountType = 'Current Account';
        String Bank = 'Bank';
        String AccountNumber = '123456789';
        
        paramsMap.put('accountId', accountId);
        paramsMap.put('Country', Country);
        paramsMap.put('startUrl', startUrl);
        paramsMap.put('CompanyType', CompanyType);
        paramsMap.put('Name', Name);
        paramsMap.put('TaxId', TaxId);
        paramsMap.put('State', State);
        paramsMap.put('City', City);     
        paramsMap.put('Phone', Phone);   
        paramsMap.put('Email', Email);
        paramsMap.put('Password', Password);
        paramsMap.put('ConfirmPassword', ConfirmPassword);
        paramsMap.put('ConfirmPassword', ConfirmPassword);
        paramsMap.put('Bank', Bank);
        paramsMap.put('AccountNumber', AccountNumber);
        
        return paramsMap;
    }
}