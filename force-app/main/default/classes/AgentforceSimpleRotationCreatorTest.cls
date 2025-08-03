@isTest
public class AgentforceSimpleRotationCreatorTest {

    @TestSetup
    static void setupTestData() {
        // Create test Farm record first (required for Parcel)
        digitalm__DM_Farm__c testFarm = new digitalm__DM_Farm__c();
        testFarm.Name = 'Test Farm';
        insert testFarm;
        
        // Create test Parcel record (required for Field)
        digitalm__DM_Parcel1__c testParcel = new digitalm__DM_Parcel1__c();
        testParcel.Name = 'Test Parcel';
        testParcel.digitalm__DM_Farm__c = testFarm.Id;
        insert testParcel;
        
        // Create test Field record
        digitalm__DM_Field__c testField = new digitalm__DM_Field__c();
        testField.Name = 'West 99 Field';
        testField.digitalm__DM_Parcel__c = testParcel.Id;
        insert testField;
    }

    @isTest
    static void testCreateRotationPlanFromSimpleJson() {
        // Prepare test JSON - simplified structure
        String testJson = '{"rotationPlanName":"Guru Test Plan","fieldName":"West 99 Field","startDate":"2025-03-01","endDate":"2029-02-28","status":"Draft","seasons":[{"seasonName":"Spring Year 1","startDate":"2025-03-01","endDate":"2025-05-31","crop":"Lettuce","cropType":"Cash Crop","purpose":"Primary cash crop","season":"Spring","year":"Year 1","zone":"In-Bed"},{"seasonName":"Summer Year 1","startDate":"2025-06-01","endDate":"2025-08-31","crop":"Clover","cropType":"Cover Crop","purpose":"Nitrogen fixation","season":"Summer","year":"Year 1","zone":"In-Bed"}]}';
        
        // Prepare request
        AgentforceSimpleRotationCreator.SimpleRotationRequest request = new AgentforceSimpleRotationCreator.SimpleRotationRequest();
        request.jsonData = testJson;
        
        Test.startTest();
        List<AgentforceSimpleRotationCreator.SimpleRotationResponse> responses = 
            AgentforceSimpleRotationCreator.createRotationPlanFromJson(new List<AgentforceSimpleRotationCreator.SimpleRotationRequest>{request});
        Test.stopTest();
        
        // Verify response
        System.assertEquals(1, responses.size(), 'Should return one response');
        AgentforceSimpleRotationCreator.SimpleRotationResponse response = responses[0];
        if (!response.success) {
            System.debug('Error message: ' + response.errorMessage);
        }
        System.assertEquals(true, response.success, 'Should be successful: ' + response.errorMessage);
        System.assertNotEquals(null, response.rotationPlanId, 'Should return rotation plan ID');
        System.assertEquals(2, response.numberOfSeasonsCreated, 'Should create two seasons');
        System.assertEquals('Guru Test Plan', response.rotationPlanName, 'Should have correct plan name');
        
        // Verify database records
        List<digitalm__DM_Rotation_Plan__c> plans = [SELECT Id, Name FROM digitalm__DM_Rotation_Plan__c];
        System.assertEquals(1, plans.size(), 'Should create one rotation plan');
        System.assertEquals('Guru Test Plan', plans[0].Name, 'Should have correct name');
        
        List<digitalm__DM_Season__c> seasons = [SELECT Id, Name FROM digitalm__DM_Season__c];
        System.assertEquals(2, seasons.size(), 'Should create two seasons');
    }

    @isTest
    static void testMinimalJsonStructure() {
        // Test with minimal required fields only
        String testJson = '{"rotationPlanName":"Minimal Test Plan","fieldName":"West 99 Field","seasons":[]}';
        
        AgentforceSimpleRotationCreator.SimpleRotationRequest request = new AgentforceSimpleRotationCreator.SimpleRotationRequest();
        request.jsonData = testJson;
        
        Test.startTest();
        List<AgentforceSimpleRotationCreator.SimpleRotationResponse> responses = 
            AgentforceSimpleRotationCreator.createRotationPlanFromJson(new List<AgentforceSimpleRotationCreator.SimpleRotationRequest>{request});
        Test.stopTest();
        
        // Verify response
        System.assertEquals(1, responses.size(), 'Should return one response');
        AgentforceSimpleRotationCreator.SimpleRotationResponse response = responses[0];
        System.assertEquals(true, response.success, 'Should be successful: ' + response.errorMessage);
        System.assertEquals(0, response.numberOfSeasonsCreated, 'Should create zero seasons');
    }

    @isTest
    static void testInvalidFieldName() {
        // Test with invalid field name
        String testJson = '{"rotationPlanName":"Test Plan","fieldName":"Invalid Field","seasons":[]}';
        
        AgentforceSimpleRotationCreator.SimpleRotationRequest request = new AgentforceSimpleRotationCreator.SimpleRotationRequest();
        request.jsonData = testJson;
        
        Test.startTest();
        List<AgentforceSimpleRotationCreator.SimpleRotationResponse> responses = 
            AgentforceSimpleRotationCreator.createRotationPlanFromJson(new List<AgentforceSimpleRotationCreator.SimpleRotationRequest>{request});
        Test.stopTest();
        
        // Verify error response
        System.assertEquals(1, responses.size(), 'Should return one response');
        AgentforceSimpleRotationCreator.SimpleRotationResponse response = responses[0];
        System.assertEquals(false, response.success, 'Should not be successful');
        System.assert(response.errorMessage.contains('Field not found'), 'Should contain field not found error');
    }

    @isTest
    static void testInvalidJson() {
        // Test with invalid JSON
        AgentforceSimpleRotationCreator.SimpleRotationRequest request = new AgentforceSimpleRotationCreator.SimpleRotationRequest();
        request.jsonData = '{"invalid": json}';
        
        Test.startTest();
        List<AgentforceSimpleRotationCreator.SimpleRotationResponse> responses = 
            AgentforceSimpleRotationCreator.createRotationPlanFromJson(new List<AgentforceSimpleRotationCreator.SimpleRotationRequest>{request});
        Test.stopTest();
        
        // Verify error response
        System.assertEquals(1, responses.size(), 'Should return one response');
        AgentforceSimpleRotationCreator.SimpleRotationResponse response = responses[0];
        System.assertEquals(false, response.success, 'Should not be successful');
        System.assert(response.errorMessage.contains('JSON'), 'Should contain JSON error message');
    }

    @isTest
    static void testEmptyJsonData() {
        // Test with empty JSON data
        AgentforceSimpleRotationCreator.SimpleRotationRequest request = new AgentforceSimpleRotationCreator.SimpleRotationRequest();
        request.jsonData = '';
        
        Test.startTest();
        List<AgentforceSimpleRotationCreator.SimpleRotationResponse> responses = 
            AgentforceSimpleRotationCreator.createRotationPlanFromJson(new List<AgentforceSimpleRotationCreator.SimpleRotationRequest>{request});
        Test.stopTest();
        
        // Verify error response
        System.assertEquals(1, responses.size(), 'Should return one response');
        AgentforceSimpleRotationCreator.SimpleRotationResponse response = responses[0];
        System.assertEquals(false, response.success, 'Should not be successful');
        System.assert(response.errorMessage.contains('JSON data is required'), 'Should contain required data error');
    }

    @isTest
    static void testJsonWithMarkdownFormatting() {
        // Test JSON with markdown code blocks
        String testJson = '```json\n{"rotationPlanName":"Markdown Test","fieldName":"West 99 Field","seasons":[]}\n```';
        
        AgentforceSimpleRotationCreator.SimpleRotationRequest request = new AgentforceSimpleRotationCreator.SimpleRotationRequest();
        request.jsonData = testJson;
        
        Test.startTest();
        List<AgentforceSimpleRotationCreator.SimpleRotationResponse> responses = 
            AgentforceSimpleRotationCreator.createRotationPlanFromJson(new List<AgentforceSimpleRotationCreator.SimpleRotationRequest>{request});
        Test.stopTest();
        
        // Verify successful parsing despite markdown formatting
        System.assertEquals(1, responses.size(), 'Should return one response');
        AgentforceSimpleRotationCreator.SimpleRotationResponse response = responses[0];
        System.assertEquals(true, response.success, 'Should successfully parse markdown-formatted JSON: ' + response.errorMessage);
        System.assertEquals('Markdown Test', response.rotationPlanName, 'Should have correct plan name');
    }

    @isTest
    static void testDataNormalization() {
        // Test data normalization features
        String testJson = '{"rotationPlanName":"Normalization Test","fieldName":"West 99 Field","seasons":[{"seasonName":"spring test","season":"SPRING","cropType":"cash crop","year":"2025","zone":""}]}';
        
        AgentforceSimpleRotationCreator.SimpleRotationRequest request = new AgentforceSimpleRotationCreator.SimpleRotationRequest();
        request.jsonData = testJson;
        
        Test.startTest();
        List<AgentforceSimpleRotationCreator.SimpleRotationResponse> responses = 
            AgentforceSimpleRotationCreator.createRotationPlanFromJson(new List<AgentforceSimpleRotationCreator.SimpleRotationRequest>{request});
        Test.stopTest();
        
        // Verify normalization worked
        System.assertEquals(1, responses.size(), 'Should return one response');
        AgentforceSimpleRotationCreator.SimpleRotationResponse response = responses[0];
        System.assertEquals(true, response.success, 'Should be successful: ' + response.errorMessage);
        
        // Check that season was created with normalized values
        List<digitalm__DM_Season__c> seasons = [SELECT digitalm__DM_Season__c, digitalm__DM_Crop_Type__c, digitalm__DM_Zone__c, digitalm__DM_Year__c FROM digitalm__DM_Season__c];
        System.assertEquals(1, seasons.size(), 'Should create one season');
        System.assertEquals('Spring', seasons[0].digitalm__DM_Season__c, 'Should normalize season to proper case');
        System.assertEquals('Cash Crop', seasons[0].digitalm__DM_Crop_Type__c, 'Should normalize crop type to proper case');
        System.assertEquals('In-Bed', seasons[0].digitalm__DM_Zone__c, 'Should default zone to In-Bed');
        System.assertEquals('Year 1', seasons[0].digitalm__DM_Year__c, 'Should normalize year to Year 1');
    }

    @isTest
    static void testComplexRotationPlan() {
        // Test with a more complex rotation plan similar to agent output
        String testJson = '{"rotationPlanName":"West 99 Field 4-Year Rotation","fieldName":"West 99 Field","startDate":"2025-03-01","endDate":"2029-02-28","status":"Draft","seasons":[{"seasonName":"Spring Year 1","startDate":"2025-03-01","endDate":"2025-05-31","crop":"Lettuce","cropType":"Cash Crop","purpose":"Primary cash crop","season":"Spring","year":"Year 1"},{"seasonName":"Summer Year 1","startDate":"2025-06-01","endDate":"2025-08-31","crop":"Sweet Corn","cropType":"Cash Crop","purpose":"Summer revenue crop","season":"Summer","year":"Year 1"},{"seasonName":"Fall Year 1","startDate":"2025-09-01","endDate":"2025-11-30","crop":"Broccoli","cropType":"Cash Crop","purpose":"Fall harvest crop","season":"Fall","year":"Year 1"},{"seasonName":"Winter Year 1","startDate":"2025-12-01","endDate":"2026-02-28","crop":"Winter Peas","cropType":"Cover Crop","purpose":"Nitrogen fixation","season":"Winter","year":"Year 1"}]}';
        
        AgentforceSimpleRotationCreator.SimpleRotationRequest request = new AgentforceSimpleRotationCreator.SimpleRotationRequest();
        request.jsonData = testJson;
        
        Test.startTest();
        List<AgentforceSimpleRotationCreator.SimpleRotationResponse> responses = 
            AgentforceSimpleRotationCreator.createRotationPlanFromJson(new List<AgentforceSimpleRotationCreator.SimpleRotationRequest>{request});
        Test.stopTest();
        
        // Verify response
        System.assertEquals(1, responses.size(), 'Should return one response');
        AgentforceSimpleRotationCreator.SimpleRotationResponse response = responses[0];
        System.assertEquals(true, response.success, 'Should be successful: ' + response.errorMessage);
        System.assertEquals(4, response.numberOfSeasonsCreated, 'Should create four seasons');
        
        // Verify all seasons were created correctly
        List<digitalm__DM_Season__c> seasons = [SELECT Name, digitalm__DM_Crop__c, digitalm__DM_Season__c FROM digitalm__DM_Season__c ORDER BY digitalm__DM_Start_Date__c];
        System.assertEquals(4, seasons.size(), 'Should create four seasons');
        System.assertEquals('Lettuce', seasons[0].digitalm__DM_Crop__c, 'First season should be Lettuce');
        System.assertEquals('Sweet Corn', seasons[1].digitalm__DM_Crop__c, 'Second season should be Sweet Corn');
        System.assertEquals('Broccoli', seasons[2].digitalm__DM_Crop__c, 'Third season should be Broccoli');
        System.assertEquals('Winter Peas', seasons[3].digitalm__DM_Crop__c, 'Fourth season should be Winter Peas');
    }
}
