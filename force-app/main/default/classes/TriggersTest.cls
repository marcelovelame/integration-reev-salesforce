/**
 * BSD 3-Clause License
 *
 * Copyright (c) 2020, Jianfeng Jin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

@IsTest
public with sharing class TriggersTest implements SellerSelfRegister_Triggers.Handler, SellerSelfRegister_Triggers.BeforeInsert {
    public static String getFakeId(
        Schema.SObjectType objectType,
        Integer index
    ) {
        return objectType.getDescribe().getKeyPrefix() +
            '000zzzz' + // start from a large Id to avoid confliction during unit test.
            String.valueOf(index).leftPad(5, '0');
    }

    static List<Account> createAccounts() {
        return new List<Account>{
            new Account(
                Id = getFakeId(Account.SObjectType, 1),
                Name = 'Account 1',
                Description = 'Account 1',
                BillingCity = 'New York'
            ),
            new Account(
                Id = getFakeId(Account.SObjectType, 2),
                Name = 'Account 2',
                Description = 'Account 2',
                BillingCity = 'New York'
            ),
            new Account(
                Id = getFakeId(Account.SObjectType, 3),
                Name = 'Account 3',
                Description = 'Account 3',
                BillingCity = 'New York'
            )
        };
    }

    @IsTest
    static void testSkips_getHandlerName_ByType() {
        SellerSelfRegister_Triggers.Skips skips = new SellerSelfRegister_Triggers.Skips();
        skips.add(String.class);
        System.assertEquals(true, skips.contains(String.class));

        skips.remove(String.class);
        System.assertEquals(0, skips.skippedHandlers.size());

        skips.add(TriggersTest.TriggersTest.class);
        System.assertEquals(true, skips.contains(TriggersTest.class));

        skips.clear();
        System.assertEquals(0, skips.skippedHandlers.size());

        skips.add(TriggersTest.class);
        System.assertEquals(true, skips.contains(new TriggersTest()));
    }

    @IsTest
    static void testBinding_BaseLine() {
        SellerSelfRegister_Triggers.prepare()
            .beforeInsert()
            .bind(new MainHandler())
            .beforeUpdate()
            .bind(new MainHandler())
            .beforeDelete()
            .bind(new MainHandler())
            .execute();

        SellerSelfRegister_Triggers.prepare()
            .afterInsert()
            .bind(new MainHandler())
            .afterUpdate()
            .bind(new MainHandler())
            .afterDelete()
            .bind(new MainHandler())
            .afterUndelete()
            .bind(new MainHandler())
            .execute();

        System.Assert(true, 'Not executed');
    }

    @IsTest
    static void testBinding_Stop_BeforeInsert() {
        SellerSelfRegister_Triggers.Manager triggerManager = SellerSelfRegister_Triggers.prepare(
            TriggerOperation.BEFORE_INSERT,
            null,
            null
        );
        triggerManager.beforeInsert()
            .bind(new FirstHandler())
            .bind(new MainHandler())
            .bind(new MainHandler())
            .bind(new StopHandler())
            .bind(new MainHandler())
            .bind(new LastHandler())
            .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_Stop_AfterInsert() {
        SellerSelfRegister_Triggers.Manager triggerManager = SellerSelfRegister_Triggers.prepare(
            TriggerOperation.AFTER_INSERT,
            null,
            null
        );
        triggerManager.afterInsert()
            .bind(new FirstHandler())
            .bind(new MainHandler())
            .bind(new MainHandler())
            .bind(new StopHandler())
            .bind(new MainHandler())
            .bind(new LastHandler())
            .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_Inactive_BeforeInsert() {
        SellerSelfRegister_Triggers.Manager triggerManager = SellerSelfRegister_Triggers.prepare(
            TriggerOperation.BEFORE_INSERT,
            null,
            null
        );
        triggerManager.beforeInsert()
            .bind(new FirstHandler())
            .bind(new MainHandler())
            .bind(new InactiveHandler())
            .bind(new MainHandler())
            .bind(new LastHandler())
            .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_Skip_Remove() {
        SellerSelfRegister_Triggers.Manager triggerManager = SellerSelfRegister_Triggers.prepare(
            TriggerOperation.BEFORE_INSERT,
            null,
            null
        );
        triggerManager.beforeInsert()
            .bind(new FirstHandler())
            .bind(new MainHandler())
            .bind(new AddSkippedHandler())
            .bind(new TriggersTest())
            .bind(new RemoveSkippedHandler())
            .bind(new TriggersTest())
            .bind(new LastHandler())
            .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_Skip_Clear() {
        SellerSelfRegister_Triggers.Manager triggerManager = SellerSelfRegister_Triggers.prepare(
            TriggerOperation.BEFORE_INSERT,
            null,
            null
        );
        triggerManager
            .beforeInsert()
            .bind(new FirstHandler())
            .bind(new MainHandler())
            .bind(new AddSkippedHandler())
            .bind(new TriggersTest())
            .bind(new ClearSkippedHandler())
            .bind(new TriggersTest())
            .bind(new LastHandler())
            .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    // #region Test State
    @IsTest
    static void testBinding_State_BeforeInsert() {
        SellerSelfRegister_Triggers.Manager triggerManager = SellerSelfRegister_Triggers.prepare(
            TriggerOperation.BEFORE_INSERT,
            new List<SObject>{},
            new List<SObject>()
        );
        triggerManager
            .beforeInsert()
            .bind(new FirstHandler())
            .bind(new MainHandler())
            .bind(new MainHandler())
            .bind(new LastHandler())
            .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_AfterInsert() {
        SellerSelfRegister_Triggers.Manager triggerManager = SellerSelfRegister_Triggers.prepare(
            TriggerOperation.AFTER_INSERT,
            null,
            null
        );
        triggerManager
            .afterInsert()
            .bind(new FirstHandler())
            .bind(new MainHandler())
            .bind(new MainHandler())
            .bind(new LastHandler())
            .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_BeforeUpdate() {
        SellerSelfRegister_Triggers.Manager triggerManager = SellerSelfRegister_Triggers.prepare(
            TriggerOperation.BEFORE_UPDATE,
            new List<SObject>(),
            new List<SObject>()
        );
        triggerManager
            .beforeUpdate()
            .bind(new FirstHandler())
            .bind(new MainHandler())
            .bind(new MainHandler())
            .bind(new LastHandler())
            .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_AfterUpdate() {
        SellerSelfRegister_Triggers.Manager triggerManager = SellerSelfRegister_Triggers.prepare(
            TriggerOperation.AFTER_UPDATE,
            new List<SObject>(),
            new List<SObject>()
        );
        triggerManager
            .afterUpdate()
            .bind(new FirstHandler())
            .bind(new MainHandler())
            .bind(new MainHandler())
            .bind(new LastHandler())
            .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_BeforeDelete() {
        SellerSelfRegister_Triggers.Manager triggerManager = SellerSelfRegister_Triggers.prepare(
            TriggerOperation.BEFORE_DELETE,
            null,
            null
        );
        triggerManager
            .beforeDelete()
            .bind(new FirstHandler())
            .bind(new MainHandler())
            .bind(new MainHandler())
            .bind(new LastHandler())
            .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_AfterDelete() {
        SellerSelfRegister_Triggers.Manager triggerManager = SellerSelfRegister_Triggers.prepare(
            TriggerOperation.AFTER_DELETE,
            null,
            null
        );
        triggerManager
            .afterDelete()
            .bind(new FirstHandler())
            .bind(new MainHandler())
            .bind(new MainHandler())
            .bind(new LastHandler())
            .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_AfterUndelete() {
        SellerSelfRegister_Triggers.Manager triggerManager = SellerSelfRegister_Triggers.prepare(
            TriggerOperation.AFTER_UNDELETE,
            null,
            null
        );
        triggerManager
            .afterUndelete()
            .bind(new FirstHandler())
            .bind(new MainHandler())
            .bind(new MainHandler())
            .bind(new LastHandler())
            .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_Mock() {
        List<SObject> oldList = new List<SObject>{
            new Account(
                Id = TriggersTest.getFakeId(Account.SObjectType, 1),
                Name = 'Old Name 1'
            ),
            new Account(
                Id = TriggersTest.getFakeId(Account.SObjectType, 2),
                Name = 'Old Name 2'
            ),
            new Account(
                Id = TriggersTest.getFakeId(Account.SObjectType, 3),
                Name = 'Old Name 3'
            )
        };

        List<SObject> newList = new List<SObject>{
            new Account(
                Id = TriggersTest.getFakeId(Account.SObjectType, 1),
                Name = 'New Name 1'
            ),
            new Account(
                Id = TriggersTest.getFakeId(Account.SObjectType, 2),
                Name = 'New Name 2'
            ),
            new Account(
                Id = TriggersTest.getFakeId(Account.SObjectType, 3),
                Name = 'New Name 3'
            )
        };
            
        SellerSelfRegister_Triggers.prepare(TriggerOperation.BEFORE_INSERT, oldList, newList)
            .afterUpdate()
            .bind(new AccountNameChangedHandler())
            .execute();

        SellerSelfRegister_Triggers.prepare(TriggerOperation.AFTER_INSERT, oldList, newList)
            .afterUpdate()
            .bind(new AccountNameChangedHandler())
            .execute();

        SellerSelfRegister_Triggers.prepare(TriggerOperation.BEFORE_UPDATE, oldList, newList)
            .afterUpdate()
            .bind(new AccountNameChangedHandler())
            .execute();

        SellerSelfRegister_Triggers.prepare(TriggerOperation.AFTER_UPDATE, oldList, newList)
            .afterUpdate()
            .bind(new AccountNameChangedHandler())
            .execute();

        SellerSelfRegister_Triggers.prepare(TriggerOperation.BEFORE_DELETE, oldList, newList)
            .afterUpdate()
            .bind(new AccountNameChangedHandler())
            .execute();

        SellerSelfRegister_Triggers.prepare(TriggerOperation.AFTER_DELETE, oldList, newList)
            .afterUpdate()
            .bind(new AccountNameChangedHandler())
            .execute();

        SellerSelfRegister_Triggers.prepare(TriggerOperation.AFTER_UNDELETE, oldList, newList)
            .afterUpdate()
            .bind(new AccountNameChangedHandler())
            .execute();

        System.Assert(true, 'Account not found');
    }
    // #endregion

    // #region Test Helper
    @IsTest
    static void testProps_IsChanged_Negative() {
        SellerSelfRegister_Triggers.Props props = new SellerSelfRegister_Triggers.Props();
        props.isInsert = true;
        props.isUpdate = false;
        props.isDelete = false;
        props.isUndelete = false;

        List<Account> accounts = createAccounts();
        props.newList = accounts;
        props.newMap = new Map<Id, Account>(accounts);

        Boolean isChanged = props.isChanged(accounts[0].Id, Account.Name);

        System.assertEquals(false, isChanged);
    }

    @IsTest
    static void testProps_GetValues_Undelete() {
        SellerSelfRegister_Triggers.Props props = new SellerSelfRegister_Triggers.Props();
        props.isInsert = false;
        props.isUpdate = false;
        props.isDelete = false;
        props.isUndelete = true;
        props.newList = new List<Account>{
            new Account(Name = 'Account 1'),
            new Account(Name = 'Account 2'),
            new Account(Name = 'Account 3')
        };

        List<Object> names = props.getValues(Account.Name);
        System.assertEquals(3, names.size());
        System.assertEquals('Account 1', (String) names[0]);
        System.assertEquals('Account 2', (String) names[1]);
        System.assertEquals('Account 3', (String) names[2]);
    }

    @IsTest
    static void testProps_GetValues_Delete() {
        SellerSelfRegister_Triggers.Props props = new SellerSelfRegister_Triggers.Props();
        props.isInsert = false;
        props.isUpdate = false;
        props.isDelete = true;
        props.isUndelete = false;
        props.oldList = new List<Account>{
            new Account(Name = 'Account 1'),
            new Account(Name = 'Account 2'),
            new Account(Name = 'Account 3')
        };

        List<Object> names = props.getValues(Account.Name);
        System.assertEquals(3, names.size());
        System.assertEquals('Account 1', (String) names[0]);
        System.assertEquals('Account 2', (String) names[1]);
        System.assertEquals('Account 3', (String) names[2]);
    }

    @IsTest
    static void testProps_FilterChanged_NoChange() {
        SellerSelfRegister_Triggers.Props props = new SellerSelfRegister_Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;

        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        props.newList = accounts;
        props.newMap = new Map<Id, Account>(accounts);

        List<Id> changedIds = props.filterChanged(Account.Name);
        Boolean isChanged = props.isChanged(Account.Name);

        System.assertEquals(0, changedIds.size());
        System.assertEquals(false, isChanged);
    }

    @IsTest
    static void testProps_FilterChanged() {
        SellerSelfRegister_Triggers.Props props = new SellerSelfRegister_Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        List<Id> changedIds = props.filterChanged(Account.Name);
        Boolean isChanged = props.isChanged(Account.Name);

        System.assertEquals(1, changedIds.size());
        System.assertEquals(true, isChanged);
    }

    @IsTest
    static void testProps_FilterChangedAny_X2_NoChange() {
        SellerSelfRegister_Triggers.Props props = new SellerSelfRegister_Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;

        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        props.newList = accounts;
        props.newMap = new Map<Id, Account>(accounts);

        List<Id> changedIds = props.filterChangedAny(
            Account.Name,
            Account.Description
        );
        Boolean isChanged = props.isChangedAny(
            Account.Name,
            Account.Description
        );

        System.assertEquals(0, changedIds.size());
        System.assertEquals(false, isChanged);
    }

    @IsTest
    static void testProps_FilterChangedAny_X2() {
        SellerSelfRegister_Triggers.Props props = new SellerSelfRegister_Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        List<Id> changedIds = props.filterChangedAny(
            Account.Name,
            Account.Description
        );
        Boolean isChanged = props.isChangedAny(
            Account.Name,
            Account.Description
        );

        System.assertEquals(2, changedIds.size());
        System.assertEquals(true, isChanged);
    }

    @IsTest
    static void testProps_FilterChangedAny_X3() {
        SellerSelfRegister_Triggers.Props props = new SellerSelfRegister_Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[0].BillingCity = 'Account 4';
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        List<Id> changedIds = props.filterChangedAny(
            Account.Name,
            Account.Description,
            Account.BillingCity
        );
        Boolean isChanged = props.isChangedAny(
            Account.Name,
            Account.Description,
            Account.BillingCity
        );

        System.assertEquals(3, changedIds.size());
        System.assertEquals(true, isChanged);
    }

    @IsTest
    static void testProps_FilterChangedAll_X2_NoChange() {
        SellerSelfRegister_Triggers.Props props = new SellerSelfRegister_Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;

        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        props.newList = accounts;
        props.newMap = new Map<Id, Account>(accounts);

        List<Id> changedIds = props.filterChangedAll(
            Account.Name,
            Account.Description
        );
        Boolean isChanged = props.isChangedAll(
            Account.Name,
            Account.Description
        );

        System.assertEquals(0, changedIds.size());
        System.assertEquals(false, isChanged);
    }

    @IsTest
    static void testProps_FilterChangedAll_X2() {
        SellerSelfRegister_Triggers.Props props = new SellerSelfRegister_Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[0].Name = 'Account 6';
        newAccounts[0].Description = 'Account 6';
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        List<Id> changedIds = props.filterChangedAll(
            Account.Name,
            Account.Description
        );
        Boolean isChanged = props.isChangedAll(
            Account.Name,
            Account.Description
        );

        System.assertEquals(1, changedIds.size());
        System.assertEquals(true, isChanged);
    }

    @IsTest
    static void testProps_sObjectType() {
        SellerSelfRegister_Triggers.Props props = new SellerSelfRegister_Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[0].Name = 'Account 6';
        newAccounts[0].Description = 'Account 6';
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        System.assertEquals(null, props.sObjectType);
        props.setSObjectType();
        System.assertEquals(Account.SObjectType, props.sObjectType);
    }

    @IsTest
    static void testProps_FilterChangedAll_X3() {
        SellerSelfRegister_Triggers.Props props = new SellerSelfRegister_Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[0].Name = 'Account 6';
        newAccounts[0].Description = 'Account 6';
        newAccounts[0].BillingCity = 'Dalian';
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[1].Description = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        newAccounts[2].BillingCity = 'Dalian';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        List<Id> changedIds = props.filterChangedAll(
            Account.Name,
            Account.Description,
            Account.BillingCity
        );
        Boolean isChanged = props.isChangedAll(
            Account.Name,
            Account.Description,
            Account.BillingCity
        );

        System.assertEquals(1, changedIds.size());
        System.assertEquals(true, isChanged);
    }
    // #endregion

    // #region Test Handler Impls
    // TriggersTest is treated as a handler to be skipped, because inner class cannot be reflected
    // from an instance back to type properly.
    public Boolean criteria(SellerSelfRegister_Triggers.Context context) {
        return SellerSelfRegister_Triggers.WHEN_ALWAYS;
    }

    public void beforeInsert(SellerSelfRegister_Triggers.Context context) {
        context.state.put(
            'counter',
            (Integer) context.state.get('counter') + 1
        );
        context.next();
        context.state.put(
            'counter',
            (Integer) context.state.get('counter') + 1
        );
    }

    public class FirstHandler implements SellerSelfRegister_Triggers.Handler, SellerSelfRegister_Triggers.BeforeInsert, SellerSelfRegister_Triggers.AfterInsert, SellerSelfRegister_Triggers.BeforeUpdate, SellerSelfRegister_Triggers.AfterUpdate, SellerSelfRegister_Triggers.BeforeDelete, SellerSelfRegister_Triggers.AfterDelete, SellerSelfRegister_Triggers.AfterUndelete {
        public Boolean criteria(SellerSelfRegister_Triggers.Context context) {
            context.next(); // negative case, shouldn't do this
            return SellerSelfRegister_Triggers.WHEN_ALWAYS;
        }

        private void then(SellerSelfRegister_Triggers.Context context) {
            if (context.state.get('counter') == null) {
                context.state.put('counter', 0);
            }
            System.assertEquals(0, context.state.get('counter'));
            context.next();
            System.assertEquals(4, context.state.get('counter'));
        }

        public void beforeInsert(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void afterInsert(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void beforeUpdate(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void afterUpdate(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void beforeDelete(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void afterDelete(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void afterUndelete(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }
    }

    public class MainHandler implements SellerSelfRegister_Triggers.Handler, SellerSelfRegister_Triggers.BeforeInsert, SellerSelfRegister_Triggers.AfterInsert, SellerSelfRegister_Triggers.BeforeUpdate, SellerSelfRegister_Triggers.AfterUpdate, SellerSelfRegister_Triggers.BeforeDelete, SellerSelfRegister_Triggers.AfterDelete, SellerSelfRegister_Triggers.AfterUndelete {
        public Boolean criteria(SellerSelfRegister_Triggers.Context context) {
            context.next(); // shouldn't work in when method
            return SellerSelfRegister_Triggers.WHEN_ALWAYS;
        }

        private void then(SellerSelfRegister_Triggers.Context context) {
            context.state.put(
                'counter',
                (Integer) context.state.get('counter') + 1
            );
            context.next();
            context.state.put(
                'counter',
                (Integer) context.state.get('counter') + 1
            );
        }

        public void beforeInsert(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void afterInsert(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void beforeUpdate(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void afterUpdate(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void beforeDelete(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void afterDelete(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void afterUndelete(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }
    }

    public class StopHandler implements SellerSelfRegister_Triggers.Handler, SellerSelfRegister_Triggers.BeforeInsert, SellerSelfRegister_Triggers.AfterInsert {
        public Boolean criteria(SellerSelfRegister_Triggers.Context context) {
            context.next(); // shouldn't work in when method
            return SellerSelfRegister_Triggers.WHEN_ALWAYS;
        }

        private void then(SellerSelfRegister_Triggers.Context context) {
            context.stop();
        }

        public void beforeInsert(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void afterInsert(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }
    }

    public class InactiveHandler implements SellerSelfRegister_Triggers.Handler, SellerSelfRegister_Triggers.BeforeInsert {
        public Boolean criteria(SellerSelfRegister_Triggers.Context context) {
            context.next(); // negative test, shouldn't work in when method
            context.next();
            context.next();
            return !SellerSelfRegister_Triggers.WHEN_ALWAYS;
        }

        private void then(SellerSelfRegister_Triggers.Context context) {
            context.state.put(
                'counter',
                (Integer) context.state.get('counter') + 1
            );
            context.next();
            context.state.put(
                'counter',
                (Integer) context.state.get('counter') + 1
            );
        }

        public void beforeInsert(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }
    }

    public class AddSkippedHandler implements SellerSelfRegister_Triggers.Handler, SellerSelfRegister_Triggers.BeforeInsert {
        public Boolean criteria(SellerSelfRegister_Triggers.Context context) {
            return SellerSelfRegister_Triggers.WHEN_ALWAYS;
        }

        private void then(SellerSelfRegister_Triggers.Context context) {
            context.skips.add(TriggersTest.class);
            context.next();
        }

        public void beforeInsert(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }
    }

    public class RemoveSkippedHandler implements SellerSelfRegister_Triggers.Handler, SellerSelfRegister_Triggers.BeforeInsert {
        public Boolean criteria(SellerSelfRegister_Triggers.Context context) {
            return SellerSelfRegister_Triggers.WHEN_ALWAYS;
        }

        private void then(SellerSelfRegister_Triggers.Context context) {
            if (context.skips.contains(TriggersTest.class)) {
                context.skips.remove(TriggersTest.class);
            }
            context.next();
        }

        public void beforeInsert(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }
    }

    public class ClearSkippedHandler implements SellerSelfRegister_Triggers.Handler, SellerSelfRegister_Triggers.BeforeInsert {
        public Boolean criteria(SellerSelfRegister_Triggers.Context context) {
            return SellerSelfRegister_Triggers.WHEN_ALWAYS;
        }

        private void then(SellerSelfRegister_Triggers.Context context) {
            context.skips.clear();
            context.next();
        }

        public void beforeInsert(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }
    }

    public class LastHandler implements SellerSelfRegister_Triggers.Handler, SellerSelfRegister_Triggers.BeforeInsert, SellerSelfRegister_Triggers.AfterInsert, SellerSelfRegister_Triggers.BeforeUpdate, SellerSelfRegister_Triggers.AfterUpdate, SellerSelfRegister_Triggers.BeforeDelete, SellerSelfRegister_Triggers.AfterDelete, SellerSelfRegister_Triggers.AfterUndelete {
        public Boolean criteria(SellerSelfRegister_Triggers.Context context) {
            context.next(); // shouldn't work in when method
            return SellerSelfRegister_Triggers.WHEN_ALWAYS;
        }

        private void then(SellerSelfRegister_Triggers.Context context) {
            System.assertEquals(2, context.state.get('counter'));
            context.next();
            System.assertEquals(2, context.state.get('counter'));
        }

        public void beforeInsert(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void afterInsert(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void beforeUpdate(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void afterUpdate(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void beforeDelete(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void afterDelete(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }

        public void afterUndelete(SellerSelfRegister_Triggers.Context context) {
            then(context);
        }
    }

    public class AccountNameChangedHandler implements SellerSelfRegister_Triggers.Handler, SellerSelfRegister_Triggers.BeforeInsert, SellerSelfRegister_Triggers.AfterInsert, SellerSelfRegister_Triggers.BeforeUpdate, SellerSelfRegister_Triggers.AfterUpdate, SellerSelfRegister_Triggers.BeforeDelete, SellerSelfRegister_Triggers.AfterDelete, SellerSelfRegister_Triggers.AfterUndelete {
        public Boolean criteria(SellerSelfRegister_Triggers.Context context) {
            return SellerSelfRegister_Triggers.WHEN_ALWAYS;
        }

        public void beforeInsert(SellerSelfRegister_Triggers.Context context) {
            System.assertEquals(null, context.props.oldList);
            System.assertEquals(null, context.props.oldMap);
            System.assertEquals(3, context.props.newList.size());
            System.assertEquals(3, context.props.newMap.size());
        }

        public void afterInsert(SellerSelfRegister_Triggers.Context context) {
            System.assertEquals(null, context.props.oldList);
            System.assertEquals(null, context.props.oldMap);
            System.assertEquals(3, context.props.newList.size());
            System.assertEquals(3, context.props.newMap.size());
        }

        public void beforeUpdate(SellerSelfRegister_Triggers.Context context) {
            System.assertEquals(3, context.props.oldList.size());
            System.assertEquals(3, context.props.oldMap.size());
            System.assertEquals(3, context.props.newList.size());
            System.assertEquals(3, context.props.newMap.size());

            System.assertEquals(
                3,
                context.props.filterChanged(Account.Name).size()
            );
            System.assertEquals(true, context.props.isChanged(Account.Name));
        }

        public void afterUpdate(SellerSelfRegister_Triggers.Context context) {
            System.assertEquals(3, context.props.oldList.size());
            System.assertEquals(3, context.props.oldMap.size());
            System.assertEquals(3, context.props.newList.size());
            System.assertEquals(3, context.props.newMap.size());

            System.assertEquals(
                3,
                context.props.filterChanged(Account.Name).size()
            );
            System.assertEquals(true, context.props.isChanged(Account.Name));
        }

        public void beforeDelete(SellerSelfRegister_Triggers.Context context) {
            System.assertEquals(3, context.props.oldList.size());
            System.assertEquals(3, context.props.oldMap.size());
            System.assertEquals(null, context.props.newList);
            System.assertEquals(null, context.props.newMap);
        }

        public void afterDelete(SellerSelfRegister_Triggers.Context context) {
            System.assertEquals(3, context.props.oldList.size());
            System.assertEquals(3, context.props.oldMap.size());
            System.assertEquals(null, context.props.newList);
            System.assertEquals(null, context.props.newMap);
        }

        public void afterUndelete(SellerSelfRegister_Triggers.Context context) {
            System.assertEquals(null, context.props.oldList);
            System.assertEquals(null, context.props.oldMap);
            System.assertEquals(3, context.props.newList.size());
            System.assertEquals(3, context.props.newMap.size());
        }
    }
    // #endregion
}