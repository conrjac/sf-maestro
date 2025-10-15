public class TriggerDispatcher {
    // Cache CMDT per (object, event) for the whole transaction.
    private static Map<String, List<Trigger_Handler__mdt>> cache = new Map<String, List<Trigger_Handler__mdt>>();
    // Prevent accidental recursion per handler+op.
    private static Set<String> executed = new Set<String>();

    public static void dispatch(String sobjectName) {
        System.TriggerOperation op = Trigger.operationType;
        String eventKey = eventKeyOf(op);
        String cacheKey = sobjectName + ':' + eventKey;

        List<Trigger_Handler__mdt> rows = cache.get(cacheKey);
        if (rows == null) {
            rows = [
                SELECT SObject_Type__c, Event__c, Handler_Class__c, Is_Enabled__c, Sequence__c, Condition_Class__c
                FROM Trigger_Handler__mdt
                WHERE SObject_Type__c = :sobjectName
                  AND Event__c   = :eventKey
                  AND Is_Enabled__c = true
                ORDER BY Sequence__c ASC
            ];
            cache.put(cacheKey, rows);
        }
        if (rows.isEmpty()) return;

        // Build context once
        List<SObject> newList = (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) ? Trigger.new : null;
        Map<Id,SObject> oldMap = (Trigger.isUpdate || Trigger.isDelete) ? Trigger.oldMap : null;
        List<SObject> oldList = (Trigger.isDelete) ? Trigger.old : null;

        for (Trigger_Handler__mdt row : rows) {
            String guardKey = row.Handler_Class__c + ':' + cacheKey;
            if (executed.contains(guardKey)) continue;

            BaseTriggerHandler handler = (BaseTriggerHandler) Type.forName(row.Handler_Class__c).newInstance();

            // Optional condition class check
            if (row.Condition_Class__c != null && row.Condition_Class__c.trim().length() > 0) {
                IHandlerCondition cond = (IHandlerCondition) Type.forName(row.Condition_Class__c).newInstance();
                if (!cond.shouldRun(newList, oldMap)) continue;
            }

            // Execute the matching method
            if (op == System.TriggerOperation.BEFORE_INSERT)       handler.beforeInsert(newList);
            else if (op == System.TriggerOperation.BEFORE_UPDATE) {handler.beforeUpdate(newList, oldMap);}
            else if (op == System.TriggerOperation.BEFORE_DELETE)  handler.beforeDelete(oldList);
            else if (op == System.TriggerOperation.AFTER_INSERT)   handler.afterInsert(newList);
            else if (op == System.TriggerOperation.AFTER_UPDATE)  {handler.afterUpdate(newList, oldMap);}
            else if (op == System.TriggerOperation.AFTER_DELETE)   handler.afterDelete(oldList);
            else if (op == System.TriggerOperation.AFTER_UNDELETE) handler.afterUndelete(newList);

            executed.add(guardKey);
        }
    }

    private static String eventKeyOf(System.TriggerOperation op) {
        switch on op {
            when BEFORE_INSERT  { return 'beforeInsert'; }
            when BEFORE_UPDATE  { return 'beforeUpdate'; }
            when BEFORE_DELETE  { return 'beforeDelete'; }
            when AFTER_INSERT   { return 'afterInsert'; }
            when AFTER_UPDATE   { return 'afterUpdate'; }
            when AFTER_DELETE   { return 'afterDelete'; }
            when AFTER_UNDELETE { return 'afterUndelete'; }
            when else           { return String.valueOf(op); }
        }
    }
}