public class OnlyWhenLargeBatch implements IHandlerCondition {
    // Example of Handler Condition
    public Boolean shouldRun(List<SObject> newList, Map<Id,SObject> oldMap) {
        return (newList != null && newList.size() >= 50);
    }
}