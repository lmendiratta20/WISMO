public without sharing class OrderController {

    @AuraEnabled(cacheable=true)
    public static List<Order> getOrdersForCurrentUser() {
        updateCache();
        return [
            SELECT Id,
                   OrderNumber,
                   Order_ID__c,
                   Status,
                   EffectiveDate,
                   TotalAmount,
                   ShippingCountry,
                   Account.Name
            FROM Order
            WHERE CreatedById = :UserInfo.getUserId()
            ORDER BY EffectiveDate DESC
            LIMIT 200
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<OrderItem> getOrderItems(Id orderId) {
        if (orderId == null) {
            return new List<OrderItem>();
        }

        return [
            SELECT Id,
                   OrderId,
                   Quantity,
                   UnitPrice,
                   TotalPrice,
                   PricebookEntry.Name,
                   PricebookEntry.Product2.Name,
                   PricebookEntry.Product2.Family
            FROM OrderItem
            WHERE OrderId = :orderId
        ];
    }


     @AuraEnabled
    public static User getCurrentUser() {
        User u = [
            SELECT Id, Name
            FROM User 
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1];
        return u;
    }

    @AuraEnabled
    public static void updateCache(){
        Cache.Org.put('userMail',UserInfo.getUserEmail());
    }
}