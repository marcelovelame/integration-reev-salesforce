({
    
    qsToEventMap2: {
        'expid'  : 'e.c:setExpId'
    },

    setBrandingCookie: function (component, event, helpler) {        
        var expId = component.get("v.expid");
        if (expId) {
            var action = component.get("c.setExperienceId");
            action.setParams({expId:expId});
            action.setCallback(this, function(a){ });
            $A.enqueueAction(action);
        }
    },
    
    checkLoggedUser: function (component, event, helper) {  
        var action = component.get("c.getLoggedUser"); 
        action.setCallback(this, function(a){
            var rtnValue = a.getReturnValue();            
            component.set("v.loggedUserSt",rtnValue);            
            if(rtnValue == 'Draft' || rtnValue == 'Not Approved' ){
                helper.getUserData(component, event, helper, rtnValue); 
            }                                   
        });
        $A.enqueueAction(action);   
    },
    
    getHelpText: function (component, event, helpler) {               
        var action = component.get("c.getFieldsHelpText");
        action.setCallback(this, function(a){
            var rtnValue = a.getReturnValue(); 
            component.set("v.fieldsHelpText",rtnValue);             
         });
        $A.enqueueAction(action);
    },
    
    getUserData: function (component, event, helper, st) { 
        var action = component.get("c.getUserData");         
        action.setCallback(this, function(a){           
            var rtnValue = a.getReturnValue(); 
            
            if(rtnValue.length){
                component.set('v.accountId',rtnValue[0].Id);
                component.set('v.sellerId',rtnValue[1].Id);  
                 
                component.find("Country").set('v.value', rtnValue[1].Atonit_Mktplace__Country__c );
                component.find("CompanyType").set('v.value', rtnValue[1].Atonit_Mktplace__Company_Type__c );
                component.find("Name").set('v.value', rtnValue[1].Atonit_Mktplace__Display_Name__c);
                component.find("State").set('v.value', rtnValue[1].Atonit_Mktplace__State__c);
                component.find("City").set('v.value', rtnValue[1].Atonit_Mktplace__City__c);                
                component.find("Name").set('v.value', rtnValue[0].Name);             
                component.find("Phone").set('v.value', rtnValue[0].Phone);
                component.find("Email").set('v.value', rtnValue[2].Email);                                                       
                component.find("TermsConditions").set('v.checked',rtnValue[1].Atonit_Mktplace__Terms_And_Conditions__c);
                
                if(rtnValue[1].Logo_URL__c){
                    var LogoURL = component.find("Logo_URL");
                    var LogoURLEmpty = document.getElementById("Logo_URLEmpty");
                    var LogoURLLinkCont = document.getElementById("Logo_URLLinkCont");
                    document.getElementById("Logo_URLLink").setAttribute('href',rtnValue[1].Logo_URL__c);
                    document.getElementById("Logo_URLLink").innerHTML = rtnValue[1].Logo_URL__c.split(/[\\/]/).pop();
                    component.find("Logo_URL").set("v.value",rtnValue[1].Logo_URL__c);
                    $A.util.addClass(LogoURL, 'hide');
                    $A.util.addClass(LogoURLEmpty, 'hide');
                    $A.util.removeClass(LogoURLLinkCont, 'hide');
                }
                                          
            }
            if(st == 'Draft' || st == 'Not Approved'){
                helper.getUserContactData(component, helper);   
                helper.reprovedMessage(component); 
            }
            
        });
        $A.enqueueAction(action);  
    },
    
    reprovedMessage: function (component) {
        var action = component.get("c.getReprovedMessage"); 
        action.setCallback(this, function(a){
            var rtnValue = a.getReturnValue(); 
            if(rtnValue){
                component.set('v.reprovedMessage',rtnValue);
            }
        });
        $A.enqueueAction(action); 
    },
    
    getUserContactData: function (component, helper) {
        var action = component.get("c.getUserContactData"); 
        var accountId = component.get("v.accountId");
        action.setParams({accountId: accountId});
        action.setCallback(this, function(a){
            var rtnValue = a.getReturnValue(); 
            if(rtnValue.length){
                helper.fillUserContactData(component, rtnValue,'new');                                                     
            }            
        });
        $A.enqueueAction(action); 
    },   
    
    verifyStep: function (component, event, helper) {        
        component.set("v.errorMessage",'');
        component.set("v.showError",false);
        var formId = event.getSource().getLocalId().split('-')[1]; 
        var st = component.get("v.loggedUserSt");
        
        // Form Step 1
        var Country = component.find("Country").get("v.value");
        var CompanyType = component.find("CompanyType").get("v.value");              
        var State = component.find("State").get("v.value");
        var City = component.find("City").get("v.value");
        var LogoURL = component.find("Logo_URL").get("v.files");
        var LogoURLVal = component.find("Logo_URL").get("v.value");        
        var Name = component.find("Name").get("v.value");  
        var Phone = component.find("Phone").get("v.value");        
        var Email = component.find("Email").get("v.value");
        var Password = '';
        var ConfirmPassword = '';
        if(st == 'notlogged'){
            Password = component.find("password").get("v.value");
        	ConfirmPassword = component.find("confirmPassword").get("v.value");
        }        
        var TermsConditions = component.find("TermsConditions").get("v.checked");

        // Form Step 2
        var contacts = document.getElementsByClassName("bl-contacts");
        var contactList = '';
        if(contacts.length){
            contactList += '[';
            for (var i = 0; i < contacts.length; i++) {
                var element = contacts[i];
                var blId = element.id.split('-')[1];                
                var email = document.getElementById("email-"+blId).getAttribute('data-email');

                var area = '';
                if(document.getElementById("area-"+blId)){
                    area = document.getElementById("area-"+blId).getAttribute('data-area');
                }
                
                var post = '';
                if(document.getElementById("post-"+blId)){  
                    post = document.getElementById("post-"+blId).getAttribute('data-post');
                }
                
                var lastnamec = document.getElementById("lastname-"+blId).getAttribute('data-lastname');

                var mobile = '';
                if(document.getElementById("mobile-"+blId)){
                    mobile = document.getElementById("mobile-"+blId).getAttribute('data-mobile');
                }

                contactList += '{"Id":"'+blId+'","Area":"'+area+'","Post":"'+post+'","LastName":"'+lastnamec+'","MobilePhone":"'+mobile+'","Email":"'+email+'"},';
                       
            }
            contactList = contactList.substr(0, contactList.length - 1) +']';

        }      
        
        var validRegexEmail = "^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$";
        var loadStep1 = document.getElementById("loadingSpinnerContainer1");
        var loadStep2 = document.getElementById("loadingSpinnerContainer2");
        var statusInit = component.get("v.loggedUserSt");
       
        switch (formId) {
            case '1':  
                var msgError = '';  
                
                if(!Country){ 
                    msgError = $A.get('$Label.Atonit_Mktplace__Field_is_required').replace('{0}', 'Country');
                }else if(!CompanyType){
                    msgError = $A.get('$Label.Atonit_Mktplace__Field_is_required').replace('{0}', 'Company type');
                }else if(!State){
                    msgError = $A.get('$Label.Atonit_Mktplace.Field_is_required').replace('{0}', 'State');
                }else if(State.length > 80){
                    msgError = $A.get('$Label.Atonit_Mktplace.Maximum_of_characters').replace('{0}', 'State').replace('{1}', '80');
                }else if(!City){
                    msgError = $A.get('$Label.Atonit_Mktplace.Field_is_required').replace('{0}', 'City');
                }else if(City.length > 80){
                    msgError = $A.get('$Label.Atonit_Mktplace.Maximum_of_characters').replace('{0}', 'City').replace('{1}', '80');
                }else if(!Phone){
                    msgError = $A.get('$Label.Atonit_Mktplace.Field_is_required').replace('{0}', 'Phone');
                }else if(Phone.length > 15){
                    msgError = $A.get('$Label.Atonit_Mktplace.Maximum_of_characters').replace('{0}', 'Phone').replace('{1}', '15');
                }else if(!Name){
                    msgError = $A.get('$Label.Atonit_Mktplace.Field_is_required').replace('{0}', 'Display name');
                }else if(Name.length > 80){
                    msgError = $A.get('$Label.Atonit_Mktplace.Maximum_of_characters').replace('{0}', 'Display name').replace('{1}', '80');
                }else if(!Email){
                    msgError = $A.get('$Label.Atonit_Mktplace.Field_is_required').replace('{0}', 'Email');
                }else if(Email.length > 80){
                    msgError = $A.get('$Label.Atonit_Mktplace.Maximum_of_characters').replace('{0}', 'Email').replace('{1}', '80');
                }else if (!Email.match(validRegexEmail)) {
                    msgError = $A.get('$Label.Atonit_Mktplace.Email_is_invalid');
                }else if(!Password && statusInit == 'notlogged'){
                    msgError = $A.get('$Label.Atonit_Mktplace.Field_is_required').replace('{0}', 'Password');
                }else if(!ConfirmPassword && statusInit == 'notlogged'){
                    msgError = $A.get('$Label.Atonit_Mktplace.Field_is_required').replace('{0}', 'Confirm password');
                }else if(Password != ConfirmPassword && statusInit == 'notlogged'){
                    msgError = $A.get('$Label.site.passwords_dont_match');
                }else if(TermsConditions == false){
                    msgError = $A.get('$Label.Atonit_Mktplace.Accept_the_Terms_and_Conditions');
                }           

                if(msgError){
                    component.set("v.errorMessage",msgError);
                    component.set("v.showError",true);
                }else{                    
                    $A.util.removeClass(loadStep1, 'hide');
                    var saveDraft = component.get("c.saveDraft");    
                    var includePassword = true;
                    var accountId = component.get("v.accountId");  
                    saveDraft.setParams({includePassword:includePassword, accountId:accountId, Country:Country, CompanyType:CompanyType, Name:Name, State:State, City:City, Phone:Phone, Email:Email, Password:Password, ConfirmPassword:ConfirmPassword, TermsConditions:TermsConditions});
                    saveDraft.setCallback(this, function(a){
                        $A.util.addClass(loadStep1, 'hide');
                        var rtnValue = a.getReturnValue();  
                        var state = a.getState();          
                                                
                        if(rtnValue.error){
                            component.set("v.errorMessage",rtnValue.error);
                            component.set("v.showError",true);
                        }                                           
          
                        if (state === "ERROR") {
                            var errors = a.getError();  
                            if (errors) {
                                if (errors[0] && errors[0].message) {
                                    component.set("v.errorMessage", errors[0].message);
                                    component.set("v.showError", true);                                                
                                }
                            } 
                        }
                        
                        if(rtnValue.accountId){                        
                            component.set('v.accountId',rtnValue.accountId);   
                            component.set('v.sellerId',rtnValue.sellerId);  
                            
                            var updateSeller = component.get("c.updateSellerApi");                                              
                            updateSeller.setParams({sellerId:rtnValue.sellerId});
                            updateSeller.setCallback(this, function(a){
                                var rtnValue = a.getReturnValue();                                  
                                if(rtnValue != null){                        
                                    component.set("v.errorMessage",rtnValue);
                                    component.set("v.showError",true);
                                }else{
                                    helper.changeStepForward(formId, (parseInt(formId) +1) );
                                    
                                }                                                                         
                            });
                            $A.enqueueAction(updateSeller);                            
                        }                                        
                        
                    });
                    $A.enqueueAction(saveDraft);
                }                
                
                break;           
            case '2':                            
                                                       
                $A.util.removeClass(loadStep2, 'hide');
                var saveContacts = component.get("c.saveContacts");    
                var accountId = component.get("v.accountId");                     
                saveContacts.setParams({accountId:accountId, contactList:contactList});
                saveContacts.setCallback(this, function(a){
                    var rtnValue = a.getReturnValue();  
                    
                    if(rtnValue == null){                        
                        var saveSeller = component.get("c.updateSeller");    
                        var sellerId = component.get('v.sellerId'); 
                        var regConfirmUrl = component.get('v.regConfirmUrl'); 
                        saveSeller.setParams({sellerId:sellerId, Email:Email, regConfirmUrl:regConfirmUrl });
                        saveSeller.setCallback(this, function(a){
                            var rtnValue = a.getReturnValue();                          
                            if(rtnValue != null){                           
                                component.set("v.errorMessage",rtnValue);
                                component.set("v.showError",true);
                            }                                         
                            $A.util.addClass(loadStep2, 'hide');
                        });
                        $A.enqueueAction(saveSeller);
                    }else{
                        component.set("v.errorMessage",rtnValue);
                        component.set("v.showError",true);
                    }                                         
                    
                });
                $A.enqueueAction(saveContacts);                                                    
                
                break;                      
            default:
                helper.changeStepForward(formId, (parseInt(formId) +1) );
        }
                
    },
    
    changeStepForward: function (prev, next) {       
        var prevStep = document.getElementById('form-' + prev );
        $A.util.addClass(prevStep, 'hide');
        var nextStep = document.getElementById('form-' + next );
        $A.util.removeClass(nextStep, 'hide');
        var navStep = document.getElementById('nav-form-' + next );
        $A.util.addClass(navStep, 'active');
        
    },

    changeStepbackwards: function (component, event, helper) {     
        component.set("v.errorMessage",'');
        component.set("v.showError",false);  
        var formId = event.getSource().getLocalId().split('-')[1];      
        var prevStep = document.getElementById('form-' + formId );
        $A.util.addClass(prevStep, 'hide');
        var nextStep = document.getElementById('form-' + (parseInt(formId) -1) );
        $A.util.removeClass(nextStep, 'hide');
        var navStep = document.getElementById('nav-form-' + formId );
        $A.util.removeClass(navStep, 'active');
    },
    
    saveContact: function (component, event, helper) { 
        
        var Area = component.find("Area").get("v.value");
        var Post = component.find("Post").get("v.value");
        var LastName = component.find("LastName").get("v.value");
        var MobilePhone = component.find("MobilePhone").get("v.value");
        var EmailContact = component.find("EmailContact").get("v.value");
        
        var validRegexEmail = "^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$";
        var msgError = '';

        if(Post.length > 80){
            msgError = $A.get('$Label.Atonit_Mktplace.Maximum_of_characters').replace('{0}', 'Post').replace('{1}', '80');
        }else if(!LastName){
            msgError = $A.get('$Label.Atonit_Mktplace.Field_is_required').replace('{0}', 'Name');
        }else if(LastName.length > 80){
            msgError = $A.get('$Label.Atonit_Mktplace.Maximum_of_characters').replace('{0}', 'Name').replace('{1}', '80');
        }else if(MobilePhone.length > 15){
            msgError = $A.get('$Label.Atonit_Mktplace.Maximum_of_characters').replace('{0}', 'Mobile').replace('{1}', '15');
        }else if(!EmailContact){
            msgError = $A.get('$Label.Atonit_Mktplace.Field_is_required').replace('{0}', 'Email');
        }else if(!EmailContact.length > 80){
            msgError = $A.get('$Label.Atonit_Mktplace.Maximum_of_characters').replace('{0}', 'Email').replace('{1}', '80');
        }else if (!EmailContact.match(validRegexEmail)) {
            msgError = $A.get('$Label.Atonit_Mktplace.Email_is_invalid');
        }else{
            msgError ='';
        }
        
        if(msgError){
            component.set("v.errorMessageModal",msgError);
            component.set("v.showError",true);
        }else{
            component.set("v.errorMessageModal",'');
            component.set("v.showError",false);
            component.find("Area").set('v.value','');
            component.find("Post").set('v.value','');
            component.find("LastName").set('v.value','');
            component.find("MobilePhone").set('v.value','');
            component.find("EmailContact").set('v.value','');
            
            var org = 'new';
            var id = '';
            if(!component.find("IdContact").get("v.value")){
                id = document.getElementsByClassName('bl-contacts').length +1; 
            }else{
                id = component.find("IdContact").get("v.value");
            }            

            if(document.getElementById('ct-'+id)){
                org = 'update';
            }
            
            var dataVal = ['{"Id":"'+id+'","Atonit_Mktplace__Area__c":"'+Area+'","Atonit_Mktplace__Post__c":"'+Post+'","LastName":"'+LastName+'","MobilePhone":"'+MobilePhone+'","Email":"'+EmailContact+'"}'];
            dataVal[0] = JSON.parse(dataVal[0]);
            
            helper.fillUserContactData(component, dataVal,org);              
                     
        }
    },
    
    fillUserContactData: function (component,rtnValue,org){

        if(rtnValue != null){
            var st = component.get("v.loggedUserSt");
            for(var i = 0; i < rtnValue.length; i++){   
                var bl = '';    
                var post = '';
                var area = '';
                var mobile = '';
                if(rtnValue[i].Atonit_Mktplace__Post__c){post = rtnValue[i].Atonit_Mktplace__Post__c;}
                if(rtnValue[i].Atonit_Mktplace__Area__c){area = rtnValue[i].Atonit_Mktplace__Area__c;}
                if(rtnValue[i].MobilePhone){mobile = rtnValue[i].MobilePhone;}
                bl += '    <img class="user" src="/sfsites/c/file-asset/Atonit_Mktplace__user?v=1" />';
                bl += '    <div class="dados-contact">';
                bl += '        <div id="lastname-'+rtnValue[i].Id+'" class="cn" data-lastname="'+rtnValue[i].LastName+'">'+rtnValue[i].LastName+'</div>';
                bl += '        <div id="email-'+rtnValue[i].Id+'" data-email="'+rtnValue[i].Email+'">'+rtnValue[i].Email+'</div>';
                bl += '        <div id="post-'+rtnValue[i].Id+'" class="cc" data-post="'+post+'"></div>';
                bl += '        <div id="area-'+rtnValue[i].Id+'" class="ca" data-area="'+area+'"></div>';                
                bl += '        <div id="mobile-'+rtnValue[i].Id+'" data-mobile="'+mobile+'"></div>';
                
                bl += '    </div>';
                bl += '    <div class="actions-contact">';                
                bl += '        <img id="edt-'+rtnValue[i].Id+'" class="edit-contact" src="/sfsites/c/file-asset/Atonit_Mktplace__edit?v=1" />';
                if(st == 'notlogged'){
                    bl += '        <img id="del-'+rtnValue[i].Id+'" class="delete-contact" src="/sfsites/c/file-asset/Atonit_Mktplace__delete?v=1" />';   
                }                
                bl += '    </div>';
            
                if(org == 'update'){
                    document.getElementById('ct-'+rtnValue[i].Id).innerHTML = bl;
                }else{                    
                    var html = document.getElementById("contContacts").innerHTML;
                    document.getElementById("contContacts").innerHTML = html + '<div id="ct-'+rtnValue[i].Id+'" class="bl-contacts">'+bl+'</div>';                    
                }

                var removeElements = document.getElementsByClassName("delete-contact");
                for (var k = 0; k < removeElements.length; k++) {
                    var element = removeElements[k];
                    element.onclick = function(event) {
                        var blId = event.currentTarget.id.split('-')[1];
                        document.getElementById("ct-"+blId).remove();
                    }           
                }
                
                var editElements = document.getElementsByClassName("edit-contact");
                for (var k = 0; k < editElements.length; k++) {
                    var element = editElements[k];
                    element.onclick = function(e) {
                        component.set("v.isModalOpen", true);
                        var blId = e.currentTarget.id.split('-')[1];   
                        component.find("IdContact").set("v.value",blId);
                        component.find("Area").set('v.value',document.getElementById("area-"+blId).getAttribute('data-area'));
                        component.find("Post").set('v.value',document.getElementById("post-"+blId).getAttribute('data-post'));                        
                        component.find("LastName").set('v.value',document.getElementById("lastname-"+blId).getAttribute('data-lastname'));
                        component.find("MobilePhone").set('v.value',document.getElementById("mobile-"+blId).getAttribute('data-mobile'));
                        component.find("EmailContact").set('v.value',document.getElementById("email-"+blId).getAttribute('data-email'));
                        
                    }           
                }
                
                component.set("v.isModalOpen", false);
            }
        }
        
    },
    
    validateUploadFile: function (component, event, helper) { 
    	var id = event.getSource().get("v.id");            
        var files = component.find(id).get("v.files");
        var file = files[0];                
		var elementText = document.getElementById(id+'Text');  
        if(file['name']){
            elementText.innerHTML = file['name'].split(/[\\/]/).pop();
        }else{
            elementText.innerHTML = "Attach file";
        }     
        var action = component.get("c.validateFile"); 
        action.setParams({fileName: file["name"], fieldName: id+'__c', fileSize: file["size"]});
        action.setCallback(this, function(a){            
            var state = a.getState();
            var rtnValue = a.getReturnValue(); 
            if (state === "ERROR") {
                var errors = a.getError();  
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.errorMessage", errors[0].message);
                        component.set("v.showError", true);                                                
                    }
                } 
            } else if(rtnValue == null){
                component.set("v.errorMessage", "");
                component.set("v.showError", false); 
            } else{
                component.set("v.errorMessage", rtnValue);
                component.set("v.showError", true);   
            }                                
        });
        $A.enqueueAction(action);   
    },
    
    uploadFile: function (component, helper, file, fieldName, Id, formId) {

        if(!file && formId == 2){
            helper.changeStepForward(formId, (parseInt(formId) +1) );
        }
        
        var preSignedAction = component.get("c.createPreSignedUrl");                  
        file = file[0];
        var fieldLabel = fieldName;
        fieldName = fieldName+'__c';
        if (file) {
            preSignedAction.setParams({
                sobjectId: Id,
                fileName: file["name"],
                fieldName: fieldName,
                fileSize: file["size"]
            });
            
            preSignedAction.setCallback(this, function (response) {
                var state = response.getState();
                
                if (state === "SUCCESS") {
                    var preSignedUrl = response.getReturnValue();
                    //upload image to url
                    const xhr = new XMLHttpRequest();
                    xhr.open("PUT", preSignedUrl);
                    xhr.onreadystatechange = $A.getCallback(function (resolve, reject) {
                        if (xhr.readyState === 4) {
                            if (xhr.status === 200) {
                                var updateUriAction = component.get("c.updateUri");
                                updateUriAction.setParams({
                                    sobjectId: Id,
                                    fileName: file["name"],
                                    fieldName: fieldName
                                });
                                updateUriAction.setCallback(this, function (response) {
                                    var state = response.getState();                                    
                                    if (state === "SUCCESS") {                                              
                                        if(formId == '2'){
                                            helper.changeStepForward(formId, (parseInt(formId) +1) );
                                        }else{
                                            var elementText = document.getElementById(fieldLabel+'Text');       
                                            if(file['name']){
                                                elementText.innerHTML = file['name'].split(/[\\/]/).pop();
                                            }else{
                                                elementText.innerHTML = "Attach file";
                                            }
                                        }                                                                          
                                    } else if (state === "ERROR") {
                                        var errors = response.getError();
                                        
                                        if (errors) {
                                            if (errors[0] && errors[0].message) {
                                                component.set("v.errorMessage",errors[0].message);
                                                component.set("v.showError",true);
                                            }
                                        } else {
                                            component.set("v.errorMessage","Unknown Error");
                                            component.set("v.showError",true);
                                        }
                                    }
                                });
                                $A.enqueueAction(updateUriAction);
                            } else {
                                component.set("v.errorMessage","Could Not Upload File");
                                component.set("v.showError",true);
                            }
                        }
                    });
                    xhr.send(file);
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            component.set("v.errorMessage",errors[0].message);
                            component.set("v.showError",true);
                        }
                    } else {
                        component.set("v.errorMessage","Unknown Error");
                        component.set("v.showError",true);
                    }
                    
                }
            });
            $A.enqueueAction(preSignedAction);
        } else {
            component.set("v.errorMessage","Select File");
            component.set("v.showError",true);
        }
    
    },
    
    savePassword: function (component, event, helper) {
        var newPassword = component.find("newPassword").get("v.value");
        var ConfirmarContrasena = component.find("newConfirmPassword").get("v.value");
        var action = component.get("c.changePassword"); 
        action.setParams({password: newPassword, confirmPassword:ConfirmarContrasena});
        action.setCallback(this, function(response){
            var state = response.getState(); 
            var rtnValue = response.getReturnValue(); 
            if (state === "ERROR") {
                var errors = response.getError();                    
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.errorMessageModal",errors[0].message);
                        component.set("v.showError",true);
                    }
                } 
            }else if(rtnValue == null){
                component.set("v.isModalOpenPassword", false);
                component.set("v.showError",false);
            }else{
                component.set("v.errorMessageModal",rtnValue);
                component.set("v.showError",true);
            }
        });
        $A.enqueueAction(action);      
    }
})