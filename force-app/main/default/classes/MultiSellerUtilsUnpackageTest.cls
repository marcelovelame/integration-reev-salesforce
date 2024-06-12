@IsTest
public class MultiSellerUtilsUnpackageTest {

    @IsTest
    public static void getSellers(){

        User sellerUser = [SELECT Id FROM User WHERE lastname= 'Community teste user' LIMIT 1];
        setUserPermission(sellerUser.Id);

        List<MultiSellerUtilsUnpackage.SellerOption> sellers = null;

        Test.startTest();
        System.runAs(sellerUser) {
            sellers = MultiSellerUtilsUnpackage.getSellers();
        }
        Test.stopTest();

        Atonit_Mktplace__Seller__c createdSeller = [SELECT Id, Atonit_Mktplace__Display_Name__c FROM Atonit_Mktplace__Seller__c limit 1];

        System.assertEquals(false,
                            sellers.isEmpty(),
                            'Seller options can not be empty!');

        System.assertEquals(createdSeller.Id,
                            sellers.get(0).value,
                            'Seller value must be equals to the created seller Id.');

         System.assertEquals(createdSeller.Atonit_Mktplace__Display_Name__c,
                            sellers.get(0).label,
                            'Seller label must be equals to the created seller Display Name.');
    }

    @IsTest
    public static void getSellersWithoutPermissions(){

        Boolean queryException = true;
		String errorMessage = '';

        User sellerUser = [SELECT Id FROM User WHERE lastname= 'Community teste user' LIMIT 1];
        List<MultiSellerUtilsUnpackage.SellerOption> sellers = null;

        Test.startTest();
        Try{
            System.runAs(sellerUser) {
                sellers = MultiSellerUtilsUnpackage.getSellers();
            }
            queryException = false;
        } catch(QueryException e){
            queryException = true;
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertEquals(true,
                            queryException,
                            'The execution must to throw an query exeption error.');

        System.assertEquals(true,
                            errorMessage.contains('is not supported. If you are attempting to use a custom object'),
                            'The execution must to throw an query exeption error, with a error message like this.');
    }

    @IsTest
    public static void getSellersWithoutSellers(){

        User sellerUser = [SELECT Id FROM User WHERE lastname= 'Community teste user' LIMIT 1];
        setUserPermission(sellerUser.Id);

        List<MultiSellerUtilsUnpackage.SellerOption> sellers = null;

        User actualUser = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];

        System.runAs(actualUser) {
            DELETE [SELECT id FROM Atonit_Mktplace__Seller__c];
        }

        Test.startTest();
        System.runAs(sellerUser) {
            sellers = MultiSellerUtilsUnpackage.getSellers();
        }
        Test.stopTest();

        System.assertEquals(true,
                            sellers.isEmpty(),
                            'The sellers list must be empty! All sellers were deleted previously!');
    }

    @IsTest
    public static void getSellersWithoutLinkedUserAccount(){

        List<MultiSellerUtilsUnpackage.SellerOption> sellers = null;

        User actualUser = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];

        Test.startTest();
        System.runAs(actualUser) {
            Atonit_Mktplace__Seller__c seller = [SELECT Atonit_Mktplace__Account__c FROM Atonit_Mktplace__Seller__c limit 1];
            seller.Atonit_Mktplace__Account__c = null;
            update seller;

            sellers = MultiSellerUtilsUnpackage.getSellers();
        }
        Test.stopTest();

        System.assertEquals(true,
                            sellers.isEmpty(),
                            'The sellers list must be empty! can not bring sellers without accounts!');
    }

    private static void setUserPermission(Id userId){
         insert new PermissionSetAssignment(
            AssigneeId = userId,
            PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Marketplace_Partner'][0].Id
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
            Atonit_Mktplace__Seller__c newSeller = buildApprovedMarketplaceSeller(true);
            newSeller.OwnerId = newUser.Id;
            insert newSeller;
        }
    }


    public static Atonit_Mktplace__Seller__c buildApprovedMarketplaceSeller(Boolean enabled){

        Atonit_Mktplace__CommissionTable__c commissionTable = new Atonit_Mktplace__CommissionTable__c();
        Insert commissionTable;

        Atonit_Mktplace__CommissionRule__c rule = new Atonit_Mktplace__CommissionRule__c();
        rule.Atonit_Mktplace__Active__c = true;
        rule.RecordTypeId = Atonit_Mktplace__CommissionRule__c.getSobjectType()
                                      .getDescribe()
                                      .getRecordTypeInfosByDeveloperName()
                                      .get('General')
                                      .getRecordTypeId();
        rule.Atonit_Mktplace__CommissionTable__c = commissionTable.Id;
        Insert rule;

        Atonit_Mktplace__Seller__c seller = new Atonit_Mktplace__Seller__c();
        seller.Atonit_Mktplace__Display_Name__c = 'Seller test';
        seller.Atonit_Mktplace__AvailableToShop__c = enabled;
        seller.Atonit_Mktplace__Account__c = [SELECT Id FROM Account WHERE name = 'Community teste' LIMIT 1].Id;
        seller.Atonit_Mktplace__Slug__c = 'community-teste';
        seller.Atonit_Mktplace__Status__c = 'Approved';
        seller.Atonit_Mktplace__AvailableToShop__c = true;
        seller.Atonit_Mktplace__CommissionTable__c = commissionTable.Id;
        return seller;
    }

}