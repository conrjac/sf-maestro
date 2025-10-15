public class AccountNameNormaliserHandler extends BaseTriggerHandler {
    public override void beforeUpdate(List<SObject> newList, Map<Id,SObject> oldMap) {
        List<Account> accts = (List<Account>) newList;
        for (Account a : accts) {
            if (a.Name != null) a.Name = a.Name.trim();
        }
    }
}