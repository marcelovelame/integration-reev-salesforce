global without sharing class SellerSelfRegisterController {
    public SellerSelfRegisterController() {
    }

    @TestVisible 
    public static boolean isValidPassword(String password, String confirmPassword) {
        return password == confirmPassword;
    }
    
    @TestVisible 
    public static boolean siteAsContainerEnabled(String communityUrl) {
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(communityUrl,'');
        return authConfig.isCommunityUsingSiteAsContainer();
    }
    
    @TestVisible 
    public static void validatePassword(User u, String password, String confirmPassword) {
        if(!Test.isRunningTest()) {
            Site.validatePassword(u, password, confirmPassword);
        }
        return;
    }
    
    @AuraEnabled
    public static String changePassword(String password, String confirmPassword) {
        Id userId = UserInfo.getUserId();
        User user =  [Select id, Username, FirstName, LastName from User where Id = :userId];
        validatePassword(user, password, confirmPassword);
        if(!Test.isRunningTest()) {
            System.setPassword(userId, password);  
        }
        return null;
    }
    
    @AuraEnabled
    public static List<SObject> getUserData() {                              
        
        User User =  [Select id, email from User where id = : UserInfo.getUserId() limit 1];
        List<Atonit_Mktplace__Seller__c> seller =  [Select id, Atonit_Mktplace__Country__c, Atonit_Mktplace__Company_Type__c, Atonit_Mktplace__Display_Name__c, Atonit_Mktplace__State__c, Atonit_Mktplace__City__c, Atonit_Mktplace__Terms_And_Conditions__c, Atonit_Mktplace__Logo_URL__c, Atonit_Mktplace__Account__c from Atonit_Mktplace__Seller__c where OwnerId = :User.id order by CreatedDate desc  limit 1];    
        List<SObject> data = new List<SObject>();  
        
        if(!seller.isEmpty()){
            Account account =  [Select id, Name, Phone from Account where id = : seller[0].Atonit_Mktplace__Account__c limit 1];                                  
            data.add(account);
            data.add(seller[0]);
            data.add(User);
        }
                
        return data;
    }
    
    @AuraEnabled
    public static String getReprovedMessage() {
        String name = userinfo.getName();        
        String msg = '';
        List<Atonit_Mktplace__Seller__c> seller =  [Select Atonit_Mktplace__Reproved_Message__c from Atonit_Mktplace__Seller__c where OwnerId = : UserInfo.getUserId() order by CreatedDate desc limit 1];            
        if(!seller.isEmpty()){
            msg = seller[0].Atonit_Mktplace__Reproved_Message__c;  
        }   
        return msg;
    }
    
    @AuraEnabled
    public static List<Contact> getUserContactData(String accountId) {       
        List<Contact> contact =  [Select id, Atonit_Mktplace__Area__c, Atonit_Mktplace__Post__c, LastName, MobilePhone, Email from Contact where AccountId = :accountId order by CreatedDate asc];
        return contact;
    }
    
    @AuraEnabled
    global static String setExperienceId(String expId) {
        try {
            if (expId != null) {
                Site.setExperienceId(expId);   
            }
            return null; 
        } catch (Exception ex) {
            return ex.getMessage();            
        }        
    }
    
    @AuraEnabled
    public static String getLoggedUser() {
        
        String name = userinfo.getName();        
        String status = 'notlogged';
        
        if(! Pattern.compile('(?i)\\bguest\\b').matcher(name).find() ){                    
            List<Atonit_Mktplace__Seller__c> seller =  [Select Atonit_Mktplace__Status__c from Atonit_Mktplace__Seller__c where OwnerId = : UserInfo.getUserId() order by CreatedDate desc limit 1];            
            if(!seller.isEmpty()){
                status = seller[0].Atonit_Mktplace__Status__c;  
            }                              
        }
        
        return status;
    }
    
    @AuraEnabled
    public static Map<String, String> getFieldsHelpText(){ 
        
        List <String> objList = new List <String>{'Atonit_Mktplace__Seller__c','Account','Contact'};
        Map<String, String> inlineHelpText = new Map<String, String>(); 
        
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fields = new Map<String, Schema.SObjectField>();       
        for(String f : objList){             
            Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(f);
            Schema.DescribeSObjectResult a_desc = SObjectTypeObj.getDescribe(); 
            Map<String, Schema.SObjectField> a_fields = a_desc.fields.getMap();
            for(Schema.sObjectField fld:a_fields.values()){ 
                if(fld != null && fld.getDescribe().getInlineHelpText() != null){                    
                    inlineHelpText.put(f + '_' + String.valueOf(fld),fld.getDescribe().getInlineHelpText());
                }
                
            }        
            
        }
        return inlineHelpText;
    }
   
    
    @AuraEnabled
    public static Map<String, String> saveDraft(Boolean includePassword, String accountId, String Country, String CompanyType, String Name, String State, String City, String Phone, String Email, String Password, String ConfirmPassword, Boolean TermsConditions) {
        Map<String, String> resp = new Map<String, String>(); 
        try {                   
            
            if(accountId == null || String.isEmpty(accountId)){
            
                if (Email != null || !String.isEmpty(Email)) {
                    List<User> user =  [Select Id from User where Email = :Email];
                    if(!user.isEmpty()){            
                        resp.put('error', 'Email already registered');
                        return resp;
                    }
                }     
                
                List<Atonit_Mktplace__Seller__c> slg =  [Select Id from Atonit_Mktplace__Seller__c where Atonit_Mktplace__Display_Name__c = :Name];
                if(!slg.isEmpty()){            
                    resp.put('error', 'Display Name already registered');
                    return resp;
                }
                
                String firstname = '';                              
                
                User u = new User();
                u.Username = Email;
                u.put('Email',Email);
                u.LastName  = Name;     
                u.Atonit_Mktplace__Seller_Status__c = 'prospect';
                
                if (includePassword) {    
                    if (!isValidPassword(Password, ConfirmPassword)) {
                        resp.put('error',Label.site.passwords_dont_match);
                        return resp;
                    }
                    validatePassword(u, Password, ConfirmPassword);
                }                
                      
                Account newAccount = new Account();
                newAccount.Name = Name;  
                newAccount.Phone = Phone;
                insert newAccount;
                accountId = newAccount.Id;                     

                String networkId = Network.getNetworkId();
                
                // If using site to host the community the user should not hit s1 after logging in from mobile.
                if(networkId != null && siteAsContainerEnabled(Network.getLoginUrl(networkId))) {
                    u.put('UserPreferencesHideS1BrowserUI',true);
                }
                
                String nickname = ((firstname.length() > 0) ? firstname.substring(0,1) : '' ) + Name.substring(0,1);
                nickname += String.valueOf(Crypto.getRandomInteger()).substring(1,7);
                u.put('CommunityNickname', nickname);                                                     

                //createExternalUser
                String userId = Site.createPortalUser(u, accountId, Password);
                
                // create a fake userId for test.
                if (Test.isRunningTest()) {
                    User userTest =  [Select Id from User where id =: UserInfo.getUserId() order by CreatedDate asc];
                    userId = userTest.Id;           
                }

                if (userId != null) {                   
                    Atonit_Mktplace__Seller__c seller = new Atonit_Mktplace__Seller__c();
                    seller.Atonit_Mktplace__Country__c = Country;
                    seller.Atonit_Mktplace__Company_Type__c = CompanyType;
                    seller.Atonit_Mktplace__State__c = State;
                    seller.Atonit_Mktplace__City__c = City;
                    seller.Atonit_Mktplace__Account__c = accountId;            
                    seller.OwnerId = userId;
                    seller.Atonit_Mktplace__Terms_And_Conditions__c = TermsConditions;
                    seller.Atonit_Mktplace__Status__c = 'Pending'; 
                    insert seller;                    
                    
                    resp.put('accountId',accountId);
                    resp.put('sellerId',seller.Id);
                    resp.put('userId',userId);   
                    return resp;
                }
                
                resp.put('error','Error');    
                return resp;
                
            }else{
                Atonit_Mktplace__Seller__c seller =  [Select Id, OwnerId from Atonit_Mktplace__Seller__c where Atonit_Mktplace__Account__c = :accountId limit 1];            
                seller.Atonit_Mktplace__Country__c = Country;
                seller.Atonit_Mktplace__Company_Type__c = CompanyType;
                seller.Atonit_Mktplace__Display_Name__c = Name;
                seller.Atonit_Mktplace__State__c = State;
                seller.Atonit_Mktplace__City__c = City;                
                update seller;
                
                Account account =  [Select Id from Account where Id = :accountId limit 1];
                account.Name = Name;  
                account.Phone = Phone;
                update account;
                
                User user =  [Select Id from User where Id = :seller.OwnerId];                
                updateUser(Email, user.Id);               
                
                resp.put('accountId',accountId);
                resp.put('sellerId',seller.Id);
                resp.put('userId',user.Id);   
                return resp;               
            }

        }catch (Exception ex) {
            resp.put('error',ex.getMessage());
            return resp;            
        }       
    }
    
    @future
    public static void updateUser(String Email, String userId){
        User user =  [Select Id from User where Id =: userId];
        user.put('Email',Email);
        update user;
    }
    
    @AuraEnabled
    public static String updateSellerApi(String sellerId){
        
        try {  
            Atonit_Mktplace__Seller__c seller =  [Select Id, Atonit_Mktplace__Slug__c, OwnerId from Atonit_Mktplace__Seller__c where Id =: sellerId]; 
           
            User user =  [Select Id from User where Id =: seller.OwnerId];
           
            user.Atonit_Mktplace__Api_ExternalId_Prefix__c = seller.Atonit_Mktplace__Slug__c;
            update user;                
                                    
            return null;
            
        }catch (Exception ex) {
            return ex.getMessage();                
        }  
    }
    
    @AuraEnabled
    public static String saveContacts(Id accountId, String contactList) {
        try {   
            contactList = contactList.stripHtmlTags();

            if(contactList != ''){
                List<LineItem> contactListData = (List<LineItem>) JSON.deserialize(contactList, List<LineItem>.class);  
                       
                List<Contact> contactsToUpsert = new List<Contact>();
                List<Contact> contact =  [Select id from Contact where AccountId = :accountId order by CreatedDate asc];
                Map<String,Contact> contacts = new  Map<String,Contact>();
                for (Contact contactIds : contact) {
                    contacts.put(contactIds.Id, contactIds);
                }
                
                Integer ct = 0;
                for (LineItem cData : contactListData) {
                    Contact newContact = new Contact();
                                         
                    if(contacts.containsKey(cData.Id) == true) {
                        Contact ContactList2 = contacts.get(cData.Id);
                        newContact.Id = ContactList2.Id;
                    }                                                                                                       
                                    
                    if(ct == 0){
                        newContact.Id = contact[0].Id;
                    }
                    newContact.AccountId = accountId; 
                    newContact.LastName = cData.LastName;
                    newContact.Atonit_Mktplace__Area__c = cData.Area;  
                    newContact.Atonit_Mktplace__Post__c = cData.Post;    
                    newContact.MobilePhone = cData.MobilePhone;
                    newContact.Email = cData.Email;
                    contactsToUpsert.add(newContact);
                    ct++;
                }
                SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPSERTABLE, contactsToUpsert);
                upsert securityDecision.getRecords();
            }                                
            
            return null;
            
        }catch (Exception ex) {
            return ex.getMessage();            
        }       
    }
    
    public class LineItem {
        public String Id;
        public String LastName;
        public String Area;
        public String Post;        
        public String MobilePhone;
        public String Email;
    }
    
    @AuraEnabled
    public static String updateSeller(String sellerId, String Email, String regConfirmUrl) {
        try {
            
            User User =  [Select id from User where Email = :Email limit 1];
            Atonit_Mktplace__Seller__c seller =  [Select Id, OwnerId, Atonit_Mktplace__Marketplace_Id__c from Atonit_Mktplace__Seller__c where Id = :sellerId limit 1];            
            seller.Atonit_Mktplace__Status__c = 'Pending';                   
            update seller;                                 
                
            ApexPages.PageReference confirmRef = new PageReference(regConfirmUrl);
            if(!Test.isRunningTest()) {
                aura.redirect(confirmRef);
            }
            return null;

        }catch (Exception ex) {
            return ex.getMessage();            
        }       
    }
   
}