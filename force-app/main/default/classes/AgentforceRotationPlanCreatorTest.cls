@isTest
public class AgentforceRotationPlanCreatorTest {

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
        testField.Name = 'Test Field';
        testField.digitalm__DM_Parcel__c = testParcel.Id;
        insert testField;
    }

    @isTest
    static void testCreateRotationPlanFromJson() {
        // Prepare test JSON
        String testJson = '{"rotationPlanName":"Test Rotation Plan","fieldName":"Test Field","startDate":"2025-01-01","endDate":"2026-12-31","status":"Draft","seasons":[{"seasonName":"Spring Year 1","startDate":"2025-03-01","endDate":"2025-05-31","crop":"Test Crop","cropType":"Cash Crop","purpose":"Testing","season":"Spring","year":"Year 1","zone":"In-Bed"}]}';

        // Prepare request
        AgentforceRotationPlanCreator.AgentforceRotationPlanRequest request = new AgentforceRotationPlanCreator.AgentforceRotationPlanRequest();
        request.jsonRecommendation = testJson;
        
        Test.startTest();
        List<AgentforceRotationPlanCreator.AgentforceRotationPlanResponse> responses = 
            AgentforceRotationPlanCreator.createRotationPlanFromAgent(new List<AgentforceRotationPlanCreator.AgentforceRotationPlanRequest>{request});
        Test.stopTest();
        
        // Verify response
        System.assertEquals(1, responses.size(), 'Should return one response');
        AgentforceRotationPlanCreator.AgentforceRotationPlanResponse response = responses[0];
        if (!response.success) {
            System.debug('Error message: ' + response.errorMessage);
        }
        System.assertEquals(true, response.success, 'Should be successful: ' + response.errorMessage);
        System.assertNotEquals(null, response.rotationPlanId, 'Should return rotation plan ID');
        System.assertEquals(1, response.numberOfSeasonsCreated, 'Should create one season');
        
        // Verify database records
        List<digitalm__DM_Rotation_Plan__c> plans = [SELECT Id, Name FROM digitalm__DM_Rotation_Plan__c];
        System.assertEquals(1, plans.size(), 'Should create one rotation plan');
        System.assertEquals('Test Rotation Plan', plans[0].Name, 'Should have correct name');
        
        List<digitalm__DM_Season__c> seasons = [SELECT Id, Name FROM digitalm__DM_Season__c];
        System.assertEquals(1, seasons.size(), 'Should create one season');
        System.assertEquals('Spring Year 1', seasons[0].Name, 'Should have correct season name');
    }

    @isTest
    static void testCreateRotationPlanFromDirectInput() {
        // Prepare season data
        AgentforceRotationPlanCreator.AgentSeasonData seasonData = new AgentforceRotationPlanCreator.AgentSeasonData();
        seasonData.seasonName = 'Summer Year 1';
        seasonData.startDate = Date.newInstance(2025, 6, 1);
        seasonData.endDate = Date.newInstance(2025, 8, 31);
        seasonData.crop = 'Test Cover Crop';
        seasonData.cropType = 'Cover Crop';
        seasonData.purpose = 'Soil improvement';
        seasonData.season = 'Summer';
        seasonData.year = 'Year 1';
        seasonData.zone = 'In-Bed';
        
        // Prepare request
        AgentforceRotationPlanCreator.AgentforceRotationPlanRequest request = new AgentforceRotationPlanCreator.AgentforceRotationPlanRequest();
        request.rotationPlanName = 'Direct Input Plan';
        request.fieldName = 'Test Field';
        request.startDate = Date.newInstance(2025, 1, 1);
        request.endDate = Date.newInstance(2025, 12, 31);
        request.status = 'In Progress';
        request.seasons = new List<AgentforceRotationPlanCreator.AgentSeasonData>{seasonData};
        
        Test.startTest();
        List<AgentforceRotationPlanCreator.AgentforceRotationPlanResponse> responses = 
            AgentforceRotationPlanCreator.createRotationPlanFromAgent(new List<AgentforceRotationPlanCreator.AgentforceRotationPlanRequest>{request});
        Test.stopTest();
        
        // Verify response
        System.assertEquals(1, responses.size(), 'Should return one response');
        AgentforceRotationPlanCreator.AgentforceRotationPlanResponse response = responses[0];
        if (!response.success) {
            System.debug('Error message: ' + response.errorMessage);
        }
        System.assertEquals(true, response.success, 'Should be successful: ' + response.errorMessage);
        System.assertEquals('Direct Input Plan', response.rotationPlanName, 'Should have correct plan name');
    }

    @isTest
    static void testInvalidFieldName() {
        // Prepare request with invalid field name
        AgentforceRotationPlanCreator.AgentforceRotationPlanRequest request = new AgentforceRotationPlanCreator.AgentforceRotationPlanRequest();
        request.rotationPlanName = 'Test Plan';
        request.fieldName = 'Nonexistent Field';
        request.startDate = Date.newInstance(2025, 1, 1);
        request.endDate = Date.newInstance(2025, 12, 31);
        request.seasons = new List<AgentforceRotationPlanCreator.AgentSeasonData>();
        
        Test.startTest();
        List<AgentforceRotationPlanCreator.AgentforceRotationPlanResponse> responses = 
            AgentforceRotationPlanCreator.createRotationPlanFromAgent(new List<AgentforceRotationPlanCreator.AgentforceRotationPlanRequest>{request});
        Test.stopTest();
        
        // Verify error response
        System.assertEquals(1, responses.size(), 'Should return one response');
        AgentforceRotationPlanCreator.AgentforceRotationPlanResponse response = responses[0];
        System.assertEquals(false, response.success, 'Should not be successful');
        System.assert(response.errorMessage.contains('Field not found'), 'Should contain field not found error');
    }

    @isTest
    static void testInvalidJson() {
        // Prepare request with invalid JSON
        AgentforceRotationPlanCreator.AgentforceRotationPlanRequest request = new AgentforceRotationPlanCreator.AgentforceRotationPlanRequest();
        request.jsonRecommendation = '{"invalid": json}';
        
        Test.startTest();
        List<AgentforceRotationPlanCreator.AgentforceRotationPlanResponse> responses = 
            AgentforceRotationPlanCreator.createRotationPlanFromAgent(new List<AgentforceRotationPlanCreator.AgentforceRotationPlanRequest>{request});
        Test.stopTest();
        
        // Verify error response
        System.assertEquals(1, responses.size(), 'Should return one response');
        AgentforceRotationPlanCreator.AgentforceRotationPlanResponse response = responses[0];
        System.assertEquals(false, response.success, 'Should not be successful');
        System.assert(response.errorMessage.contains('JSON'), 'Should contain JSON error message');
    }

    @isTest
    static void testJsonWithMarkdownFormatting() {
        // Test JSON with markdown code blocks
        String testJson = '```json\n{"rotationPlanName":"Markdown Test","fieldName":"Test Field","startDate":"2025-01-01","endDate":"2025-12-31","status":"Draft","seasons":[]}\n```';
        
        AgentforceRotationPlanCreator.AgentforceRotationPlanRequest request = new AgentforceRotationPlanCreator.AgentforceRotationPlanRequest();
        request.jsonRecommendation = testJson;
        
        Test.startTest();
        List<AgentforceRotationPlanCreator.AgentforceRotationPlanResponse> responses = 
            AgentforceRotationPlanCreator.createRotationPlanFromAgent(new List<AgentforceRotationPlanCreator.AgentforceRotationPlanRequest>{request});
        Test.stopTest();
        
        // Verify successful parsing despite markdown formatting
        System.assertEquals(1, responses.size(), 'Should return one response');
        AgentforceRotationPlanCreator.AgentforceRotationPlanResponse response = responses[0];
        System.assertEquals(true, response.success, 'Should successfully parse markdown-formatted JSON');
        System.assertEquals('Markdown Test', response.rotationPlanName, 'Should have correct plan name');
    }

    @isTest
    static void testSeasonDataNormalization() {
        // Test season and crop type normalization
        String testJson = '{"rotationPlanName":"Normalization Test","fieldName":"Test Field","startDate":"2025-01-01","endDate":"2025-12-31","status":"Draft","seasons":[{"seasonName":"spring year 1","season":"SPRING","cropType":"cash crop","zone":"","year":"1"}]}';
        
        AgentforceRotationPlanCreator.AgentforceRotationPlanRequest request = new AgentforceRotationPlanCreator.AgentforceRotationPlanRequest();
        request.jsonRecommendation = testJson;
        
        Test.startTest();
        List<AgentforceRotationPlanCreator.AgentforceRotationPlanResponse> responses = 
            AgentforceRotationPlanCreator.createRotationPlanFromAgent(new List<AgentforceRotationPlanCreator.AgentforceRotationPlanRequest>{request});
        Test.stopTest();
        
        // Verify normalization worked
        System.assertEquals(1, responses.size(), 'Should return one response');
        AgentforceRotationPlanCreator.AgentforceRotationPlanResponse response = responses[0];
        System.assertEquals(true, response.success, 'Should be successful');
        
        // Check that season was created with normalized values
        List<digitalm__DM_Season__c> seasons = [SELECT digitalm__DM_Season__c, digitalm__DM_Crop_Type__c, digitalm__DM_Zone__c FROM digitalm__DM_Season__c];
        System.assertEquals(1, seasons.size(), 'Should create one season');
        System.assertEquals('Spring', seasons[0].digitalm__DM_Season__c, 'Should normalize season to proper case');
        System.assertEquals('Cash Crop', seasons[0].digitalm__DM_Crop_Type__c, 'Should normalize crop type to proper case');
        System.assertEquals('In-Bed', seasons[0].digitalm__DM_Zone__c, 'Should default zone to In-Bed');
    }
}
