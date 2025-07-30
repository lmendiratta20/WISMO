/**
* @File Name : pormptTest.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 21, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 21, 2025 |   | Initial Version
**/

public class pormptTest {
	public static String getOrderShipmentStatus(String orderId, String ques) {
        String results;

        String inputOrderId = orderId;
        Boolean isCalledFromRecordPage = orderId.length() < 15 ? FALSE : TRUE ;
        String promptInput = '';
        String routeSearchText = '';

        try {
            // Order
            List<Order> listOfOrders;
            set<String> listOfOrderItemId = new set<String>();
            if(isCalledFromRecordPage){
                listOfOrders = [SELECT Id, Name, Order_ID__c, Status, EffectiveDate, TotalAmount, Account.Name, ShippingCountry
                    FROM Order
                    WHERE ID = :inputOrderId];  
            } else{
                listOfOrders = [SELECT Id, Name, Order_ID__c, Status, EffectiveDate, TotalAmount, Account.Name, ShippingCountry
                    FROM Order
                    WHERE Order_ID__c = :inputOrderId];
            }
            if(listOfOrders != null && !listOfOrders.isEmpty()){
                // Order Items
                order ord = listOfOrders[0];
                List<OrderItem> orderItems = [
                 SELECT Id, Quantity, UnitPrice, Product2.Name, TotalPrice, Source_Country__c
                FROM OrderItem
                WHERE OrderId = :ord.Id
                ];
                for(OrderItem order : orderItems){
                    listOfOrderItemId.add(String.valueOf(order.id));
                }

                Map<Id, shipment__dlm> shipmentMap = new Map<Id, shipment__dlm>();
                for (shipment__dlm shp : [
                    SELECT Id, delay_reason__c, KQ_order_product__c, courier_name__c, current_location__c, 
                    tracking_number__c, DataSource__c, order_product__c, actual_delivery_date__c, dispatched_date__c, 
                    DataSourceObject__c, InternalOrganization__c, status__c, expected_delivery__c 
                    FROM shipment__dlm 
                    WHERE Order_Product__c IN :listOfOrderItemId
                ]) {
                    shipmentMap.put(shp.Order_Product__c, shp);
                }

                // Construct Prompt Input
                promptInput += 'Order Information:\n';
                promptInput += 'Order ID: ' + ord.Order_ID__c + '\n';
                promptInput += 'Status: ' + ord.Status + '\n';
                promptInput += 'Order Date: ' + String.valueOf(ord.EffectiveDate) + '\n';
                promptInput += 'Total Amount: ₹' + String.valueOf(ord.TotalAmount) + '\n';
                promptInput += 'Customer: ' + ord.Account.Name + '\n\n';

                promptInput += 'Order Items:\n';

                for (OrderItem item : orderItems) {
                    shipment__dlm shp = shipmentMap.get(item.Id);

                    promptInput += '- Product: ' + item.Product2.Name + '\n';
                    promptInput += '  Quantity: ' + item.Quantity + ', Total Price: ₹' + item.TotalPrice + '\n';

                    if (shp != null) {
                        promptInput += '  Shipment Status: ' + String.valueOf(shp.Status__c) + '\n';
                        promptInput += '  Courier: ' + String.valueOf(shp.Courier_Name__c) + ', Tracking: ' + String.valueOf(shp.Tracking_Number__c) + '\n';
                        promptInput += '  Current Location: ' + String.valueOf(shp.Current_Location__c) + '\n';
                        promptInput += '  Expected Delivery: ' + String.valueOf(shp.Expected_Delivery__c) + '\n';
                        //promptInput += '  Delay Reason: ' + (shp.Delay_Reason__c != null ? shp.Delay_Reason__c : 'N/A') + '\n\n';
                    } else {
                        promptInput += '  Shipment Info: Not yet available.\n\n';
                    }
                    if(item.Source_Country__c != null && ord.ShippingCountry != null && shp.Current_Location__c != null){
                        Map<String, ConnectApi.WrappedValue> routeInput = new Map<String, ConnectApi.WrappedValue>();
                        ConnectApi.WrappedValue wrapOrigin = new ConnectApi.WrappedValue();
                        wrapOrigin.value = item.Source_Country__c;
                        routeInput.put('Input:originCountry', wrapOrigin);

                        ConnectApi.WrappedValue wrapDest = new ConnectApi.WrappedValue();
                        wrapDest.value = ord.ShippingCountry;
                        routeInput.put('Input:ShippingLocation', wrapDest);

                        ConnectApi.WrappedValue wrapCurrent = new ConnectApi.WrappedValue();
                        wrapCurrent.value = String.valueOf(shp.Current_Location__c);
                        routeInput.put('Input:currentLocation', wrapCurrent);

                        routeSearchText += 'Possible Routes for ' + item.Product2.Name + ':\n';
                        routeSearchText += PromptUtils.invokePrompt('shippingRoutes', routeInput);
                        routeSearchText += ' \n';
                    }
                }

                String result;
                try {
                    system.debug('routeSearchText :'+routeSearchText);
                    system.debug('promptInput :'+promptInput);
                
				ConnectApi.WrappedValue inputWrap = new ConnectApi.WrappedValue();
                inputWrap.value = promptInput;
				ConnectApi.WrappedValue inputQues = new ConnectApi.WrappedValue();
                inputQues.value = ques;
				ConnectApi.WrappedValue inputRoutes = new ConnectApi.WrappedValue();
                inputRoutes.value = routeSearchText;

                Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
                inputParams.put('Input:userQues', inputQues);
                inputParams.put('Input:shippingRoutes', inputRoutes);
                inputParams.put('Input:orderSummary', inputWrap);
                result = PromptUtils.invokePrompt('orderShipmentTracker', inputParams);
                } catch (Exception e) {
                    result = 'Failed to get AI response: ' + e.getMessage();
                }
                results = result;
        
            }
        } 
        catch (Exception eOuter) {
           
            results = 'Error: ' + eOuter.getMessage();
        }

        return results;
    }
}