public without sharing class OrderShipmentHandler {

    public class InputWrapper {
        @InvocableVariable(required=true)
        public String orderId; 
		
		@InvocableVariable(required=true)
    	public String userQuestion;

    }

    public class OutputWrapper {
        @InvocableVariable
        public String response;
    }

    @InvocableMethod(label='Get Order and Shipment Handler')
    public static List<OutputWrapper> getOrderShipmentData(List<InputWrapper> inputList) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        if (inputList.isEmpty()) return results;

        String inputOrderId = inputList[0].orderId;
        Boolean isCalledFromRecordPage = inputList[0].orderId.length() < 15 ? FALSE : TRUE ;
        String promptInput = '';
        String routeSearchText = '';

        try {
            List<Order> listOfOrders;
            if(isCalledFromRecordPage){
                listOfOrders = [SELECT Id, Name, Order_ID__c, Status, EffectiveDate, TotalAmount, Account.Name, ShippingCountry, ShippingCity
                    FROM Order
                    WHERE ID = :inputOrderId];  
            } else{
                listOfOrders = [SELECT Id, Name, Order_ID__c, Status, EffectiveDate, TotalAmount, Account.Name, ShippingCountry, ShippingCity
                    FROM Order
                    WHERE Order_ID__c = :inputOrderId];
            }
            if(listOfOrders != null && !listOfOrders.isEmpty()){
                order ord = listOfOrders[0];
                List<OrderItem> orderItems = [
                 SELECT Id, Quantity, UnitPrice, Product2.Name, TotalPrice, Source_Country__c
                FROM OrderItem
                WHERE OrderId = :ord.Id
                ];

                Map<Id, Shipment__c> shipmentMap = new Map<Id, Shipment__c>();
                for (Shipment__c shp : [
                SELECT Id, Order_Product__c, Status__c, Courier_Name__c, Tracking_Number__c,
                       Current_Location__c, Expected_Delivery__c, Actual_Delivery_Date__c
                FROM Shipment__c
                WHERE Order_Product__c IN :orderItems
                ]) {
                    shipmentMap.put(shp.Order_Product__c, shp);
                }

				Map<Id, List<Order_History__c>> orderHistoryMap = new Map<Id, List<Order_History__c>>();
                for (Order_History__c ordHistory : [
                	SELECT ArrivalDate__c, Location__c, Despatch_Date__c, OrderItem__c
                	FROM Order_History__c
                	WHERE OrderItem__c IN :orderItems
					order by ArrivalDate__c asc
                ]) {
					if(orderHistoryMap.get(ordHistory.OrderItem__c) == null){
						orderHistoryMap.put(ordHistory.OrderItem__c, new List<Order_History__c>());
					}
                    orderHistoryMap.get(ordHistory.OrderItem__c).add(ordHistory);
                }

                promptInput += 'Order Information:\n';
                promptInput += 'Today`s Date : '+ Date.today() +'\n';
                promptInput += 'Order ID: ' + ord.Order_ID__c + '\n';
                promptInput += 'Status: ' + ord.Status + '\n';
                promptInput += 'Order Date: ' + String.valueOf(ord.EffectiveDate) + '\n';
                promptInput += 'Total Amount: ₹' + String.valueOf(ord.TotalAmount) + '\n';
                promptInput += 'Customer: ' + ord.Account.Name + '\n\n';
                promptInput += 'Delivery Location: ' + ord.ShippingCity +',' + ord.ShippingCountry + '\n\n';

                promptInput += 'Order Items:\n';

                for (OrderItem item : orderItems) {
                    Shipment__c shp = shipmentMap.get(item.Id);

                    promptInput += '  Product: ' + item.Product2.Name + '\n';
                    promptInput += '  Quantity: ' + item.Quantity + ', Total Price: ₹' + item.TotalPrice + '\n';

                    if (shp != null) {
                        promptInput += '  Shipment Status: ' + shp.Status__c + '\n';
                        promptInput += '  Courier: ' + shp.Courier_Name__c + ', Tracking: ' + shp.Tracking_Number__c + '\n';
                        promptInput += '  Current Location: ' + shp.Current_Location__c + '\n';
                        promptInput += '  Expected Delivery Date: ' + String.valueOf(shp.Expected_Delivery__c) + '\n';
                        promptInput += '  Actual Delivery Date: ' + String.valueOf(shp.Actual_Delivery_Date__c) + '\n';
                    } else {
                        promptInput += '  Shipment Info: Not yet available.\n\n';
                    }
					if(orderHistoryMap.get(item.id) != null){
						for(Order_History__c orderHistory : orderHistoryMap.get(item.id)){
							promptInput += '  Location : ' + orderHistory.Location__c + '\n';
							promptInput += '  Arrival Date : ' + orderHistory.ArrivalDate__c + '\n';
							promptInput += '  Despatch Date : ' + orderHistory.Despatch_Date__c + '\n';
							routeSearchText += ' ' + orderHistory.Location__c + '\n';
						}

					}

                }

                String result;
                try {
                
				ConnectApi.WrappedValue inputWrap = new ConnectApi.WrappedValue();
                inputWrap.value = promptInput;
				ConnectApi.WrappedValue inputQues = new ConnectApi.WrappedValue();
                inputQues.value = inputList[0].userQuestion;
				ConnectApi.WrappedValue inputRoutes = new ConnectApi.WrappedValue();
                inputRoutes.value = routeSearchText;

                Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
                inputParams.put('Input:userQuestion', inputQues);
                inputParams.put('Input:shippingRoute', inputRoutes);
                inputParams.put('Input:orderSummary', inputWrap);
                result = PromptUtils.invokePrompt('orderShipmentStatus', inputParams);
                } catch (Exception e) {
                    result = 'Failed to get AI response: ' + e.getMessage();
                }

                OutputWrapper out = new OutputWrapper();
                out.response = result;
                results.add(out);
            } else {
                String orderID = inputOrderId.substringAfter('-');
                List<Order> orders = [
                    SELECT Id, Name, Order_ID__c
                    FROM Order
                    WHERE Order_ID__c LIKE : '%'+orderID+'%']; 

                String response ='Did you mean : \n';
                if(orders != null && !orders.isEmpty()){
                    for(Order order : orders){
                        response += order.Order_ID__c +' \n';
                    }
                } else {
                    response = 'Sorry can you try with different order ID';
                }
                OutputWrapper out = new OutputWrapper();
                out.response = response;
                results.add(out);
            }
            } catch (Exception eOuter) {
                OutputWrapper out = new OutputWrapper();
                out.response = 'Error: ' + eOuter.getMessage();
                results.add(out);
            }

        return results;
    }
}