public with sharing class ProductDataFetcher {
    public class InputRequest {
        @InvocableVariable(label='Dummy Input')
        public String dummyInput; // Required for InvocableMethod input structure
    }

    public class ProductNameWrapper {
        @InvocableVariable(label='Product Name')
        public String productName;

        public ProductNameWrapper(String name) {
            this.productName = name;
        }
    }

    @InvocableMethod(label='Get Active Product Names')
    public static List<ProductNameWrapper> getAllProductNames(List<InputRequest> requests) {
        List<ProductNameWrapper> names = new List<ProductNameWrapper>();
        for (Product2 p : [SELECT Name FROM Product2 WHERE IsActive = true]) {
            names.add(new ProductNameWrapper(p.Name.trim()));
        }
        return names;
    }
}