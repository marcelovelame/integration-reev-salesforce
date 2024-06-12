public with sharing class SellerOnboardingValidationController {

    @AuraEnabled
    public static Boolean checkProducts(Id sellerId) {
        Atonit_Mktplace__Seller__c seller = [SELECT Atonit_Mktplace__Onboarding_Status__c 
                                            FROM Atonit_Mktplace__Seller__c 
                                            WHERE Id =: sellerId 
                                            WITH USER_MODE];
        return (seller.Atonit_Mktplace__Onboarding_Status__c == 'Onboarding Completed');
    }

    @AuraEnabled
    public static void completeOnboarding(Id sellerId) {
        Atonit_Mktplace__Seller__c seller = [SELECT Atonit_Mktplace__Onboarding_Status__c 
                                            FROM Atonit_Mktplace__Seller__c 
                                            WHERE Id =: sellerId 
                                            WITH USER_MODE];
        seller.Atonit_Mktplace__Onboarding_Status__c = 'Onboarding Completed';  
        update as system seller;      
    }

    @AuraEnabled
    public static OnboardingComplete getProgress(Id sellerId) {
        OnboardingComplete onboarding = new OnboardingComplete();

        Atonit_Mktplace__Seller__c seller = [SELECT Id, Atonit_Mktplace__Logo_URL__c, Atonit_Mktplace__Delivery_Policy__c FROM Atonit_Mktplace__Seller__c WHERE Id =: sellerId WITH USER_MODE].Size() > 0 ?
			[SELECT Id, Atonit_Mktplace__Logo_URL__c, Atonit_Mktplace__Delivery_Policy__c FROM Atonit_Mktplace__Seller__c WHERE Id =: sellerId WITH USER_MODE][0] :
        	null;
        onboarding.Profile = seller == null?
			false:
        	!String.isBlank(seller.Atonit_Mktplace__Logo_URL__c) && !String.isBlank(seller.Atonit_Mktplace__Delivery_Policy__c);  

        onboarding.Category = [SELECT Id FROM Atonit_Mktplace__Category__c WHERE Atonit_Mktplace__Seller__c =: sellerId WITH SYSTEM_MODE].Size() > 0;
        onboarding.Product = [SELECT Id FROM Atonit_Mktplace__Product__c WHERE Atonit_Mktplace__Seller__c =: sellerId WITH USER_MODE].Size() > 0;
        onboarding.Pricebook = [SELECT Id FROM Atonit_Mktplace__Price_Book_Entry__c WHERE Atonit_Mktplace__Price_Book__r.Atonit_Mktplace__Seller__c =: sellerId WITH USER_MODE].Size() > 0;
        onboarding.Inventory = [SELECT Id FROM Atonit_Mktplace__Inventory_Record__c WHERE Atonit_Mktplace__Inventory__r.Atonit_Mktplace__Seller__c =: sellerId WITH USER_MODE].Size() > 0;
        onboarding.MatchedCategory = [SELECT Id FROM Atonit_Mktplace__Category__c WHERE Atonit_Mktplace__Matched_Category__c != NULL AND Atonit_Mktplace__Seller__c =: sellerId WITH SYSTEM_MODE].Size() > 0;
        onboarding.ShippingMethod = [SELECT Id FROM Atonit_Mktplace__Shipping_Rate__c WHERE Atonit_Mktplace__Shipping_Method__r.Atonit_Mktplace__Seller__c =: sellerId WITH USER_MODE].Size() > 0;
        onboarding.LandingPage = [SELECT Id FROM Atonit_Mktplace__Landing_Page_Content__c WHERE Atonit_Mktplace__Seller__c =: sellerId WITH USER_MODE].Size() > 0;
        onboarding.Progress = 0;
        onboarding.Progress += onboarding.Profile? 14 : 0;
        onboarding.Progress += onboarding.Category? 14 : 0;
        onboarding.Progress += onboarding.Product? 15 : 0;
        onboarding.Progress += onboarding.Pricebook? 15 : 0;
        onboarding.Progress += onboarding.Inventory? 14 : 0;
        onboarding.Progress += onboarding.MatchedCategory? 14 : 0;  
        onboarding.Progress += onboarding.ShippingMethod? 14 : 0; 
        return onboarding;
    } 


    public class OnboardingComplete {
        @AuraEnabled public Boolean Profile {get;set;} 
        @AuraEnabled public Boolean Category {get;set;} 
        @AuraEnabled public Boolean Product {get;set;} 
        @AuraEnabled public Boolean Pricebook {get;set;} 
        @AuraEnabled public Boolean Inventory {get;set;} 
        @AuraEnabled public Boolean MatchedCategory {get;set;}
        @AuraEnabled public Boolean ShippingMethod {get;set;} 
        @AuraEnabled public Boolean LandingPage {get;set;} 
        @AuraEnabled public Integer Progress {get;set;} 
    }
}