public class testAccountController {
    public List<Account> accountList {get;set;}
    
    public testAccountController() {
        accountList = [SELECT Name, Id, Type FROM Account];
    }
}