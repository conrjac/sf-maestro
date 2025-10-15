public interface IHandlerCondition {
    Boolean shouldRun(List<SObject> newList, Map<Id,SObject> oldMap);
}