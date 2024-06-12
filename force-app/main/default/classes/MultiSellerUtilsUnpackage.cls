public without sharing class MultiSellerUtilsUnpackage {

    @AuraEnabled
	public static List<SellerOption> getSellers(){
        Id userId = UserInfo.getUserId();

        List<User> users = [SELECT Id, Contact.AccountId
                            FROM User
                            WHERE Id =: userId
                            WITH USER_MODE];

        List<Atonit_Mktplace__Seller__c> sellers = new List<Atonit_Mktplace__Seller__c>();
        List<SellerOption> options = new List<SellerOption>();

        if(!users.isEmpty()){
            Id userAccountId = users.get(0).Contact.AccountId;
            if(userAccountId == null){
               return options;
            }
            sellers = [SELECT Id, Atonit_Mktplace__Display_Name__c 
                        FROM Atonit_Mktplace__Seller__c
                        WHERE Atonit_Mktplace__Status__c = 'Approved'
                        AND (Atonit_Mktplace__Onboarding_Status__c = 'New' OR Atonit_Mktplace__Onboarding_Status__c =: 'Onboarding Completed')
                        AND Atonit_Mktplace__Account__c =: userAccountId
                        WITH USER_MODE
                        ORDER BY CreatedDate DESC];
 
            if(!sellers.isEmpty()){     
                for(Atonit_Mktplace__Seller__c seller : sellers){
                    SellerOption option = new SellerOption(seller.Atonit_Mktplace__Display_Name__c, seller.Id);
                    options.add(option);
                }
            }
        }
        return options;
    }

    @TestVisible
    private class SellerOption{

        @AuraEnabled
        public String label {get; set;}

        @AuraEnabled
        public String value {get; set;}

        public SellerOption(String label, String value){
            this.label = label;
            this.value = value;
        }
    }
}