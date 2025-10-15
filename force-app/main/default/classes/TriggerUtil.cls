public class TriggerUtil {
    public static Boolean changed(SObject newRec, SObject oldRec, String fieldApi) {
        if (oldRec == null) return true;
        return newRec.get(fieldApi) != oldRec.get(fieldApi);
    }
}