trigger OnboardingAddonUserTrigger on User (after insert) {
    if(trigger.isAfter && trigger.isInsert){
        OnboardingAddonUserTriggerHandler.setAddonPermission();
    }
}