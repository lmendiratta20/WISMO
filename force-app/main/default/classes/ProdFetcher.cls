public class ProdFetcher {
    public class InputRequest {
        @InvocableVariable(label='Trigger') 
        public Boolean triggerCall;  // just to trigger execution
    }
    
    public class ProductNameWrapper {
        @InvocableVariable(label='Product Name')
        public String productName;
        
        public ProductNameWrapper(String name) {
            this.productName = name;
        }
    }
    
    @InvocableMethod(label='Fetch Active Product Names')
    public static List<ProductNameWrapper> getAllProductNames(List<InputRequest> requests) {
        List<ProductNameWrapper> names = new List<ProductNameWrapper>();
        for (Product2 p : [SELECT Name FROM Product2 WHERE IsActive = true]) {
            names.add(new ProductNameWrapper(p.Name.trim()));
        }
        return names;
    }
}