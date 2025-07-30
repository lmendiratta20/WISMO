public class PromptUtils {
    //Method Takes prompt name and input parameters and invokes the prompt
    public static String invokePrompt(String promptTemplateDeveloperName, Map<String, ConnectApi.WrappedValue> inputParams){

        // Prepare input for generating prompt template
        ConnectApi.EinsteinPromptTemplateGenerationsInput promptGenerationsInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
    
        // Set hyper parameters
        promptGenerationsInput.inputParams = inputParams;
        promptGenerationsInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        promptGenerationsInput.additionalConfig.numGenerations = 1;
        promptGenerationsInput.additionalConfig.enablePiiMasking = true;
        promptGenerationsInput.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';

        // Set if it's a preview or not
        promptGenerationsInput.isPreview = false;

        // Call the service to generate messages for the prompt template
        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(promptTemplateDeveloperName, promptGenerationsInput);

        // Consume response
        ConnectApi.EinsteinLLMGenerationItemOutput response = generationsOutput.generations[0];    
        return response.text;
    }
}