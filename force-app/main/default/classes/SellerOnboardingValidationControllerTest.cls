@isTest
public with sharing class SellerOnboardingValidationControllerTest {
    
    @isTest 
    public static void checkProducts(){
        User sellerUser = [SELECT Id FROM User WHERE lastname= 'Community teste user' LIMIT 1];
        setUserPermission(sellerUser.Id);
        
        Test.startTest();
        boolean result = true;
        System.runAs(sellerUser) {
            result = SellerOnboardingValidationController.checkProducts([SELECT Id FROM Atonit_Mktplace__Seller__c limit 1].Id);
        }
        Test.stopTest();
        
        System.assertEquals(false, 
                            result, 
                            'Seller was not defined with Status onboarding equals to Onboarding Completed!');
    }
    	
    @isTest 
    public static void checkProductsWithoutPermissions(){
        User sellerUser = [SELECT Id FROM User WHERE lastname= 'Community teste user' LIMIT 1];
        
        boolean queryException;
        String errorMessage;
        
        Test.startTest();
        System.runAs(sellerUser) {
            try{
                SellerOnboardingValidationController.checkProducts([SELECT Id FROM Atonit_Mktplace__Seller__c limit 1].Id);
                queryException = false;
            } catch(QueryException e){
                queryException = true;
                errorMessage = e.getMessage();
            }
        }
        Test.stopTest();
        System.assertEquals(true, 
                            queryException,
                            'The execution must to throw an query exeption error.');
        
        System.assertEquals(true, 
                            errorMessage.contains('is not supported. If you are attempting to use a custom object'), 
                            'The execution must to throw an query exeption error, with a error message like this.');
    }
    
    @isTest 
    public static void completeOnboarding(){
        User sellerUser = [SELECT Id FROM User WHERE lastname= 'Community teste user' LIMIT 1];
        setUserPermission(sellerUser.Id);
        
        Test.startTest();
        System.runAs(sellerUser) {
            SellerOnboardingValidationController.completeOnboarding([SELECT Id FROM Atonit_Mktplace__Seller__c limit 1].Id);
        }
        Test.stopTest();
        
        Atonit_Mktplace__Seller__c seller = [SELECT Id, Atonit_Mktplace__Onboarding_Status__c 
                                             FROM Atonit_Mktplace__Seller__c 
                                             LIMIT 1];
        
        System.assertEquals('Onboarding completed', 
                            seller.Atonit_Mktplace__Onboarding_Status__c, 
                            'The seller status must to be Onboarding completed!');
    }
    
    @isTest 
    public static void completeOnboardingWithoutPermissions(){
        User sellerUser = [SELECT Id FROM User WHERE lastname= 'Community teste user' LIMIT 1];
        
        boolean queryException;
        String errorMessage;
        
        Test.startTest();
        System.runAs(sellerUser) {
            try{
                SellerOnboardingValidationController.completeOnboarding([SELECT Id FROM Atonit_Mktplace__Seller__c limit 1].Id);
                queryException = false;
            } catch(QueryException e){
                queryException = true;
                errorMessage = e.getMessage();
            }
        }
        Test.stopTest();
        System.assertEquals(true, 
                            queryException,
                            'The execution must to throw an query exeption error.');
        
        System.assertEquals(true, 
                            errorMessage.contains('is not supported. If you are attempting to use a custom object'), 
                            'The execution must to throw an query exeption error, with a error message like this.');
    }
    
    @isTest
    public static void getProgress(){
        User sellerUser = [SELECT Id FROM User WHERE lastname= 'Community teste user' LIMIT 1];
        setUserPermission(sellerUser.Id);
        
        SellerOnboardingValidationController.OnboardingComplete onboardingObject;

        Test.startTest();
        System.runAs(sellerUser) {
            onboardingObject = SellerOnboardingValidationController.getProgress([SELECT Id FROM Atonit_Mktplace__Seller__c limit 1].Id);
        }
        Test.stopTest();
        
        System.assertEquals(true, onboardingObject.Category, 'Category list can not be empty!');
        System.assertEquals(true, onboardingObject.Product, 'Product list can not be empty!');
        System.assertEquals(false, onboardingObject.Profile, 'Profile need to be incomplete!');
        System.assertEquals(true, onboardingObject.Pricebook, 'Pricebook list can not be empty!');
        System.assertEquals(true, onboardingObject.Inventory, 'Inventory list can not be empty!');
        System.assertEquals(false, onboardingObject.MatchedCategory, 'MatchedCategory list need to be empty!');
        System.assertEquals(true, onboardingObject.ShippingMethod, 'ShippingMethod list can not be empty!');
        System.assertEquals(true, onboardingObject.LandingPage, 'LandingPage list can not be empty!');
        System.assertEquals(86, onboardingObject.Progress, 'Progress need to be 86!');
    }
    
    private static void setUserPermission(Id userId){
        insert new PermissionSetAssignment(
            AssigneeId = userId,
            PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Marketplace_Partner'][0].Id
        );
        insert new PermissionSetAssignment(
            AssigneeId = userId,
            PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Commerce_marketplace_Onboarding_addon'][0].Id
        );
    }
    
    
	@testSetup 
    public static void setup(){
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
        
        newUser = [SELECT Id FROM User WHERE lastname= 'Community teste user' LIMIT 1];
        
        System.runAs(newUser) { 
            Atonit_Mktplace__Seller__c newSeller = new Atonit_Mktplace__Seller__c();                   
            newSeller.Atonit_Mktplace__Account__c = [SELECT Id FROM Account WHERE name = 'Community teste' LIMIT 1].Id;            
            newSeller.Atonit_Mktplace__Slug__c = 'community-teste';
            newSeller.Atonit_Mktplace__Status__c = 'Approved';
            newSeller.Atonit_Mktplace__Onboarding_Status__c = 'New';
            newSeller.Atonit_Mktplace__Display_Name__c = 'Seller test';
            newSeller.OwnerId = newUser.Id;
            insert newSeller;
            
            Atonit_Mktplace__Category__c category = new Atonit_Mktplace__Category__c();
            category.Name = 'Seller category';
            category.Atonit_Mktplace__Seller__c = newSeller.Id;
            category.Atonit_Mktplace__Is_Storefront__c = true;
            category.RecordTypeId = [SELECT Id 
                                     FROM RecordType 
                                     WHERE SObjectType = 'Atonit_Mktplace__Category__c'
                                     AND Name LIKE '%marketplace%'].Id;
            Insert category;
            
            Atonit_Mktplace__Product__c product = new Atonit_Mktplace__Product__c();
            product.Atonit_Mktplace__Seller__c = newSeller.Id;
            product.Atonit_Mktplace__Name__c = 'Seller product';
            Insert product;
            
            Atonit_Mktplace__Pricebook__c pricebook = new Atonit_Mktplace__Pricebook__c();
            pricebook.Atonit_Mktplace__Seller__c = newSeller.Id;
            Insert pricebook;
            
            Atonit_Mktplace__Price_Book_Entry__c pbEntry = new Atonit_Mktplace__Price_Book_Entry__c();
            pbEntry.Atonit_Mktplace__Price_Book__c = pricebook.Id;
            pbEntry.Atonit_Mktplace__Price__c = 1;
            pbEntry.Atonit_Mktplace__Quantity__c = 1;
            Insert pbEntry;
            
            Atonit_Mktplace__Inventory__c inventory = new Atonit_Mktplace__Inventory__c();
        	inventory.Atonit_Mktplace__Seller__c = newSeller.Id;
            inventory.Atonit_Mktplace__Name__c = 'Seller inventory';
            Insert inventory;
            
            Atonit_Mktplace__Inventory_Record__c inventoryRecord = new Atonit_Mktplace__Inventory_Record__c();
            inventoryRecord.Atonit_Mktplace__Quantity__c = 1;
            inventoryRecord.Atonit_Mktplace__Inventory__c = inventory.Id;
            Insert inventoryRecord;
            
            Atonit_Mktplace__Shipping_Method__c shippingMethod = new Atonit_Mktplace__Shipping_Method__c();
            shippingMethod.Atonit_Mktplace__Name__c = 'Seller Shipping method';
            shippingMethod.Atonit_Mktplace__Seller__c = newSeller.Id;
            Insert shippingMethod;
            
            Atonit_Mktplace__Shipping_Rate__c shippingRate = new Atonit_Mktplace__Shipping_Rate__c();
            shippingRate.Atonit_Mktplace__Shipping_Method__c = shippingMethod.Id;
            Insert shippingRate;
            
            Atonit_Mktplace__Landing_Page_Content__c landing = new Atonit_Mktplace__Landing_Page_Content__c();
            landing.Atonit_Mktplace__Seller__c = newSeller.Id;
			Insert landing;
        }
    }
}