public without sharing class OnboardingAddonUserTriggerHandler {
    
    public static void setAddonPermission(){
        Set<Id> usersIds = new Set<Id>();
        
        for(User user : (List<User>) trigger.new){
            if(user.ContactId != null && user.AccountId != null){
                usersIds.add(user.Id);
            }
        }  
        
        if(!usersIds.isEmpty()){
            addPermission(usersIds);  
        }
    }
    
    @future
    private static void addPermission(Set<Id> usersIds){
        List<PermissionSetAssignment> permissionsAssignments = new List<PermissionSetAssignment>();
        
        Id permissionSetId = [SELECT Id 
                              FROM PermissionSet 
                              WHERE Name = 'Commerce_marketplace_Onboarding_addon'
                              WITH SYSTEM_MODE
                              LIMIT 1].Id;
        
        List<User> users = [SELECT id FROM User WHERE Id IN : usersIds];
        
        for(User user : users){
            PermissionSetAssignment assignmentPermission = new PermissionSetAssignment(
                PermissionSetId = permissionSetId,
                AssigneeId = user.Id
            );
            permissionsAssignments.add(assignmentPermission);
        }
        
        insert permissionsAssignments;
        
    }
    
}