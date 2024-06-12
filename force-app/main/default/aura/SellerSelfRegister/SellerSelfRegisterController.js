({
	initialize: function(component, event, helper) {
        $A.get("e.siteforce:registerQueryEventMap").setParams({"qsToEvent" : helper.qsToEventMap}).fire();
        $A.get("e.siteforce:registerQueryEventMap").setParams({"qsToEvent" : helper.qsToEventMap2}).fire();  
        helper.checkLoggedUser(component, event, helper);
        helper.getHelpText(component, event, helper);
    },
    
    setExpId: function (component, event, helper) {
        var expId = event.getParam('expid');
        if (expId) {
            component.set("v.expid", expId);
        }
        helper.setBrandingCookie(component, event, helper);
    },
    
    onKeyUp: function(component, event, helpler){
        if (event.getParam('keyCode')===13) {
            helpler.handleSelfRegister(component, event, helpler);
        }
    },
    
    verifyStep: function(component, event, helper){
        helper.verifyStep(component, event, helper);
    },
    
    changeStepbackwards: function(component, event, helper){
        helper.changeStepbackwards(component, event, helper);
    },
    
    openModel: function(component, event, helper) {
        component.set("v.errorMessage",'');
        component.set("v.showError",false);
        component.set("v.isModalOpen", true);
    },    
    
    closeModel: function(component, event, helper) {
        component.set("v.isModalOpen", false);
    },   
    
    submitDetails: function(component, event, helper) {
        component.set("v.isModalOpen", false);
    },
    
    saveContact: function(component, event, helper){
        helper.saveContact(component, event, helper);
    },
    
    validateUploadFile: function(component, event, helper){       
        helper.validateUploadFile(component, event, helper);
    },    
    
    saveDocuments: function(component, event, helper){
        var id = event.getSource().get("v.id");              
        var file = component.find(id).get("v.files");
        helper.saveDocuments(component, event, helper, file, id);
    },
    
    removeFile: function(component, event, helper){
        var id = event.currentTarget.id.split('Remove')[0];
        var input = component.find(id);
        var inputEmpty = document.getElementById(id+"Empty");
        var inputLinkCont = document.getElementById(id+"LinkCont");
        $A.util.removeClass(input, 'hide');
        $A.util.removeClass(inputEmpty, 'hide');
        $A.util.addClass(inputLinkCont, 'hide');
        component.find(id).set("v.value","");
    },
    
    openModelPassword: function(component, event, helper) {
        component.set("v.errorMessage",'');
        component.set("v.showError",false);
        component.set("v.isModalOpenPassword", true);
    },
    
    closeModelPassword: function(component, event, helper) {
        component.set("v.isModalOpenPassword", false);
        component.set("v.showError",false);
    },
    
    savePassword: function(component, event, helper) {
        helper.savePassword(component, event, helper);
    }
})