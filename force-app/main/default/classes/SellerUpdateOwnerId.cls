public without sharing class SellerUpdateOwnerId implements SellerSelfRegister_Triggers.Handler, SellerSelfRegister_Triggers.AfterInsert, SellerSelfRegister_Triggers.AfterUpdate {
    public Boolean criteria(SellerSelfRegister_Triggers.Context ctx) {
        return SellerSelfRegister_Triggers.WHEN_ALWAYS;
    }
    
    public void afterInsert(SellerSelfRegister_Triggers.Context ctx) {
        sellerUpdateStatus(ctx);
    }
    
    public void afterUpdate(SellerSelfRegister_Triggers.Context ctx) {
        sellerUpdateStatus(ctx);
    }
    
    public void sellerUpdateStatus(SellerSelfRegister_Triggers.Context ctx) {
        
        Set<Id> sellerIds = new Set<Id>();       
        Set<id> OwnerIds = new Set<id>();
        Map<id,User> users = new  Map<id,User>();
        List<User> UserToUp = new List<User>();
        String UserIds = '';
        
        for (Atonit_Mktplace__Seller__c record : (List<Atonit_Mktplace__Seller__c>) ctx.props.newList) {
            sellerIds.add(record.Id);
        }

        List<Atonit_Mktplace__Seller__c> seller = [SELECT Id, OwnerId, Atonit_Mktplace__Status__c From Atonit_Mktplace__Seller__c WHERE Id IN :sellerIds WITH SYSTEM_MODE];
                
        for (Atonit_Mktplace__Seller__c se : seller) {
            OwnerIds.add(se.OwnerId);
        }
        
        for (User u : [SELECT Id, Atonit_Mktplace__Seller_Status__c FROM User WHERE Id IN : OwnerIds WITH SYSTEM_MODE]) {
            users.put(u.id,u);
        }                       

        for (Atonit_Mktplace__Seller__c se : seller) {
            User User = users.get(se.OwnerId);
            String Slug = 'prospect'; 
            if(se.Atonit_Mktplace__Status__c == 'Approved'){             
                Slug = se.Atonit_Mktplace__Status__c;   
            }

            if (User.Atonit_Mktplace__Seller_Status__c != Slug) {
                User.Atonit_Mktplace__Seller_Status__c = Slug;                
                UserToUp.add(User);                
            }
            UserIds += User.Id + ',';            
        }                        

        if (!UserToUp.isEmpty() && Schema.SobjectType.User.isUpdateable() 
            && Schema.SobjectType.User.fields.Atonit_Mktplace__Seller_Status__c.isUpdateable()){
            update userToUp;
        }     
        
        updateUserPermission(UserIds.removeEnd(','));
        
    }
    
    @future    
    public static void updateUserPermission(String userIds){

        List<String> UserList = userIds.split(',');
        Set<Id> UserToUp = new Set<Id>();
        Set<Id> UserToRemove = new Set<Id>();
        List<Schema.PermissionSetAssignment> PerToUp = new List<Schema.PermissionSetAssignment>();
        List<PermissionSetAssignment> PerToRemove = new List<PermissionSetAssignment>();
        
        PermissionSet permissionSetSeller =  [SELECT Id,Label FROM PermissionSet WHERE Name = 'Marketplace_Partner' WITH SYSTEM_MODE LIMIT 1];        
       
        List<PermissionSetAssignment> allAssignmentList = [SELECT id FROM PermissionSetAssignment WITH SYSTEM_MODE];
        Map<Id, PermissionSetAssignment> mapAllAssignmentList = new Map<Id, PermissionSetAssignment>();
        for (PermissionSetAssignment per : allAssignmentList) {
            mapAllAssignmentList.put(per.Id, per);
        }

        for (User u : [SELECT Id, Atonit_Mktplace__Seller_Status__c, Profile.UserLicense.Name FROM User WHERE Id IN : UserList]) {
            if(Pattern.compile('(?i)\\bCommunity\\b').matcher(u.Profile.UserLicense.Name).find() ){         
                List<PermissionSetAssignment> assignmentList = [SELECT id, PermissionSetId, AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId =: permissionSetSeller.Id AND AssigneeId = : u.id WITH SYSTEM_MODE];
                if (assignmentList.isEmpty() && u.Atonit_Mktplace__Seller_Status__c == 'Approved' ) {
                    UserToUp.add(u.id);
                }
                if (!assignmentList.isEmpty() && u.Atonit_Mktplace__Seller_Status__c != 'Approved' ) {
                    UserToRemove.add(assignmentList[0].id);
                }
            }
        }                        
                      
        if (!UserToUp.isEmpty()) {
            for (Id per : UserToUp) {
                Schema.PermissionSetAssignment assignment = new Schema.PermissionSetAssignment();
                assignment.PermissionSetId = permissionSetSeller.Id;
                assignment.AssigneeId = per; 
                PerToUp.add(assignment);
            }
            
            if (!PerToUp.isEmpty() && Schema.sObjectType.PermissionSetAssignment.isCreateable()
            && Schema.sObjectType.PermissionSetAssignment.fields.PermissionSetId.isCreateable()
            && Schema.sObjectType.PermissionSetAssignment.fields.AssigneeId.isCreateable()) {
                insert PerToUp;
            }             
        }

        if (!UserToRemove.isEmpty()) {
            for (Id per : UserToRemove) {
              PermissionSetAssignment assignment = mapAllAssignmentList.get(per);
              if(assignment != null){
                 PerToRemove.add(assignment);
              }             
            }                       
        } 

        if(!PerToRemove.isEmpty()){
            delete PerToRemove;
        }                                       
    }
 
}