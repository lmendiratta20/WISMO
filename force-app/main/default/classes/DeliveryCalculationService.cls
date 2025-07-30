public class DeliveryCalculationService {
    
    public class CalculationResult {
        @InvocableVariable public String productName;
        @InvocableVariable public Decimal totalDeliveryTime;
        @InvocableVariable public String timeUnit;
        @InvocableVariable public Decimal machineCanDeliver;
    }
    
    public class InputRequest {
        @InvocableVariable(required=true) public String productName;
        @InvocableVariable(required=true) public Integer quantity;
        @InvocableVariable(required=true) public Decimal timeDuration;
    }
    
    @InvocableMethod(label='Calculate Delivery Time')
    public static List<CalculationResult> calculateDeliveryTime(List<InputRequest> requests) {
        if (requests.isEmpty()) return new List<CalculationResult>();
        
        InputRequest request = requests[0];
        system.debug('request=== : '+request);
        //request.productName = '%'+request.productName+'%';
        
        // Query product with related data
        List<Product2> products = [
            SELECT Id, Name,
                   (SELECT Monthly_Delivery_Capacity_Units__c, Assembly_Time_Days__c FROM Product_Inventory__r LIMIT 1),
                   (SELECT Backlog_Quantity_Units__c FROM Product_Backlog__r LIMIT 1),
                   (SELECT Monthly_Capacity_Units__c FROM Supplier_Product_Capacity__r LIMIT 1)
            FROM Product2 
            WHERE Name =: request.productName
            LIMIT 1
        ];
        
               
        Product2 product = products[0];
        
        // Get data from related objects
        Decimal inventoryMonthlyCapacity = 0;
        Decimal assemblyTimeDays = 0;
        if (!product.Product_Inventory__r.isEmpty()) {
            inventoryMonthlyCapacity = product.Product_Inventory__r[0].Monthly_Delivery_Capacity_Units__c ?? 0; //5
            assemblyTimeDays = product.Product_Inventory__r[0].Assembly_Time_Days__c ?? 0; //30
        }
        
        Decimal backlogQuantity = 0;
        if (!product.Product_Backlog__r.isEmpty()) {
            backlogQuantity = product.Product_Backlog__r[0].Backlog_Quantity_Units__c ?? 0; //10
        }
        
        Decimal supplierMonthlyCapacity = 0;
        if (!product.Supplier_Product_Capacity__r.isEmpty()) {
            supplierMonthlyCapacity = product.Supplier_Product_Capacity__r[0].Monthly_Capacity_Units__c ?? 0; //5
        }
        
        // Perform calculation
        Decimal finalOutput = calculateTotalDeliveryTime(request.quantity, backlogQuantity,inventoryMonthlyCapacity,supplierMonthlyCapacity,assemblyTimeDays,request.timeDuration);
        
        system.debug('finalOutput == '+finalOutput);
        
        CalculationResult result = new CalculationResult();
        result.productName = request.productName;
        if(request.quantity != 0){
            result.totalDeliveryTime = finalOutput;
        }else{
            result.machineCanDeliver = finalOutput;
        }
        result.timeUnit = 'months';
        
        
        return new List<CalculationResult>{result};
    }
    
    private static Decimal calculateTotalDeliveryTime(Integer requestedQuantity, Decimal backlogQuantity, Decimal inventoryMonthlyCapacity,Decimal supplierMonthlyCapacity, Decimal assemblyTimeDays,Decimal timeDuration) {
        Decimal totalTime = 0;
        Decimal unitsCanDeliver = 0;
        Decimal backlogClearTime = 0;
        Decimal dayRemaningAfterBacklogClear = 0;
        Decimal smallerCapacity = 0;
        Decimal daysToSupplySingleUnit = 0;
        Decimal daysToAssembleSingleUnit = 0;
        Decimal totalMachineCanDeliver = 0;
        
        // Step 1: Time to clear backlog
        if (backlogQuantity > 0 && inventoryMonthlyCapacity > 0) {
            if(requestedQuantity != 0) totalTime += backlogQuantity / inventoryMonthlyCapacity; // 10/5 = 2
            backlogClearTime = (backlogQuantity / inventoryMonthlyCapacity)*30;
            
            system.debug(timeDuration +' time Duration  ====== '+backlogClearTime);
            if(timeDuration > backlogClearTime){
                dayRemaningAfterBacklogClear = timeDuration - backlogClearTime;
            }
            system.debug(' dayRemaningAfterBacklogClear ====== '+dayRemaningAfterBacklogClear);
        }
        
        // Calculate Delivery Time
        if(requestedQuantity != 0 && timeDuration == 0){
            // Step 2: Time for requested quantity based on supplier capacity
            if (supplierMonthlyCapacity > 0 && inventoryMonthlyCapacity > 0) {
                totalTime += requestedQuantity / supplierMonthlyCapacity; // 20/5 = 4
            }
            
            // Step 3: Add assembly time
            if (assemblyTimeDays > 0 && inventoryMonthlyCapacity > 0) {
                totalTime += ((assemblyTimeDays/30) / inventoryMonthlyCapacity) * requestedQuantity;  //(30/5)*20
            }
        }
        
        // Calculate Number of machine can be deliver
        if(requestedQuantity == 0 && timeDuration != 0 && dayRemaningAfterBacklogClear != 0){
            if (supplierMonthlyCapacity > 0 && inventoryMonthlyCapacity > 0) {
                system.debug(supplierMonthlyCapacity+ ' inventoryMonthlyCapacity ====== '+inventoryMonthlyCapacity);
                
                if(supplierMonthlyCapacity != inventoryMonthlyCapacity){
                    smallerCapacity = Math.min(supplierMonthlyCapacity, inventoryMonthlyCapacity);
                }else{
                    smallerCapacity = inventoryMonthlyCapacity;
                }
                
                system.debug(supplierMonthlyCapacity+ ' inventoryMonthlyCapacity ====== '+inventoryMonthlyCapacity);
                
                daysToSupplySingleUnit  =  30/smallerCapacity;
                system.debug(' daysToSupplySingleUnit ====== '+daysToSupplySingleUnit);
                
            }
            
            // Step 3: Add assembly time
            if (assemblyTimeDays > 0 && inventoryMonthlyCapacity > 0) {
                daysToAssembleSingleUnit = (assemblyTimeDays/inventoryMonthlyCapacity);
                system.debug(' daysToAssembleSingleUnit ====== '+daysToAssembleSingleUnit);
                Decimal totalTimeForSingleUnit = daysToSupplySingleUnit + daysToAssembleSingleUnit;
                system.debug(' totalTimeForSingleUnit '+totalTimeForSingleUnit);
                
                totalMachineCanDeliver = (dayRemaningAfterBacklogClear/totalTimeForSingleUnit).round(System.RoundingMode.DOWN);
                system.debug(' total Machine milegi tere ko bhidu ======'+totalMachineCanDeliver);
            }
        }
        
        Decimal finalResult = 0;
        
        
        if(totalTime != 0){
            finalResult= totalTime;
        }else if(totalMachineCanDeliver != 0){
            finalResult = totalMachineCanDeliver;
        }
        
        system.debug(totalTime+' ==totalTime : '+totalMachineCanDeliver+'   finalResult===== '+finalResult);
        return finalResult;
    }
   
}