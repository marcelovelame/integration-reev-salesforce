trigger Seller on Atonit_Mktplace__Seller__c(before insert, before update, after insert, after update) {   
    SellerSelfRegister_Triggers.prepare() 
        .afterInsert()
       .bind(new SellerUpdateOwnerId())                 
        .afterUpdate()
       .bind(new SellerUpdateOwnerId())
        .execute();
}