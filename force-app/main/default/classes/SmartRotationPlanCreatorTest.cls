@isTest
public class SmartRotationPlanCreatorTest {

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
        
        // Create test Field record with suitability properties
        digitalm__DM_Field__c testField = new digitalm__DM_Field__c();
        testField.Name = 'West 99 Field';
        testField.digitalm__DM_Parcel__c = testParcel.Id;
        testField.digitalm__DM_Soil_Type__c = 'Loamy'; // Good for most crops
        testField.digitalm__DM_Water_Source__c = 'Well';
        testField.digitalm__DM_Land_Use__c = 'Certified Organic';
        testField.digitalm__DM_Total_Area__c = 10.5;
        insert testField;

        // Create test Field with unsuitable conditions
        digitalm__DM_Field__c unsuitableField = new digitalm__DM_Field__c();
        unsuitableField.Name = 'Unsuitable Field';
        unsuitableField.digitalm__DM_Parcel__c = testParcel.Id;
        unsuitableField.digitalm__DM_Soil_Type__c = 'Clay'; // Not suitable for lettuce
        unsuitableField.digitalm__DM_Water_Source__c = 'River';
        unsuitableField.digitalm__DM_Land_Use__c = 'Conventional';
        unsuitableField.digitalm__DM_Total_Area__c = 5.0;
        insert unsuitableField;
    }

    @isTest
    static void testCreateSmartRotationPlan_Tomatoes() {
        // Test with Tomatoes as primary crop
        SmartRotationPlanCreator.SmartRotationRequest request = new SmartRotationPlanCreator.SmartRotationRequest();
        request.fieldName = 'West 99 Field';
        request.startDate = Date.newInstance(2025, 3, 1);
        request.primaryCashCrop = 'Tomatoes';
        
        Test.startTest();
        List<SmartRotationPlanCreator.SmartRotationResponse> responses = 
            SmartRotationPlanCreator.createSmartRotationPlan(new List<SmartRotationPlanCreator.SmartRotationRequest>{request});
        Test.stopTest();
        
        // Verify response
        System.assertEquals(1, responses.size(), 'Should return one response');
        SmartRotationPlanCreator.SmartRotationResponse response = responses[0];
        System.assertEquals(true, response.success, 'Should be successful: ' + response.errorMessage);
        System.assertNotEquals(null, response.rotationPlanId, 'Should return rotation plan ID');
        System.assertEquals(16, response.numberOfSeasonsCreated, 'Should create 16 seasons (4 years x 4 seasons)');
        System.assert(response.rotationPlanName.contains('Tomatoes'), 'Plan name should contain primary crop');
        
        // Verify database records
        List<digitalm__DM_Rotation_Plan__c> plans = [SELECT Id, Name, digitalm__DM_Start_Date__c, digitalm__DM_End_Date__c FROM digitalm__DM_Rotation_Plan__c];
        System.assertEquals(1, plans.size(), 'Should create one rotation plan');
        System.assertEquals(Date.newInstance(2025, 3, 1), plans[0].digitalm__DM_Start_Date__c, 'Should have correct start date');
        System.assertEquals(Date.newInstance(2029, 2, 28), plans[0].digitalm__DM_End_Date__c, 'Should have correct end date (4 years)');
        
        // Verify seasons were created with proper rotation
        List<digitalm__DM_Season__c> seasons = [SELECT digitalm__DM_Crop__c, digitalm__DM_Season__c, digitalm__DM_Year__c, digitalm__DM_Crop_Type__c FROM digitalm__DM_Season__c ORDER BY digitalm__DM_Start_Date__c];
        System.assertEquals(16, seasons.size(), 'Should create 16 seasons');
        
        // Check first spring season has primary crop
        System.assertEquals('Tomatoes', seasons[0].digitalm__DM_Crop__c, 'First spring season should have primary crop');
        System.assertEquals('Cash Crop', seasons[0].digitalm__DM_Crop_Type__c, 'First season should be cash crop');
        System.assertEquals('Spring', seasons[0].digitalm__DM_Season__c, 'First season should be spring');
        System.assertEquals('Year 1', seasons[0].digitalm__DM_Year__c, 'First season should be Year 1');
    }

    @isTest
    static void testCreateSmartRotationPlan_Corn() {
        // Test with Corn as primary crop
        SmartRotationPlanCreator.SmartRotationRequest request = new SmartRotationPlanCreator.SmartRotationRequest();
        request.fieldName = 'West 99 Field';
        request.startDate = Date.newInstance(2025, 4, 1);
        request.primaryCashCrop = 'Corn';
        
        Test.startTest();
        List<SmartRotationPlanCreator.SmartRotationResponse> responses = 
            SmartRotationPlanCreator.createSmartRotationPlan(new List<SmartRotationPlanCreator.SmartRotationRequest>{request});
        Test.stopTest();
        
        // Verify response
        SmartRotationPlanCreator.SmartRotationResponse response = responses[0];
        System.assertEquals(true, response.success, 'Should be successful: ' + response.errorMessage);
        System.assert(response.rotationPlanName.contains('Corn'), 'Plan name should contain Corn');
        
        // Verify crop rotation logic
        List<digitalm__DM_Season__c> springSeasons = [SELECT digitalm__DM_Crop__c, digitalm__DM_Year__c FROM digitalm__DM_Season__c WHERE digitalm__DM_Season__c = 'Spring' ORDER BY digitalm__DM_Start_Date__c];
        System.assertEquals(4, springSeasons.size(), 'Should have 4 spring seasons');
        System.assertEquals('Corn', springSeasons[0].digitalm__DM_Crop__c, 'Year 1 should have Corn');
        System.assertNotEquals('Corn', springSeasons[1].digitalm__DM_Crop__c, 'Year 2 should have different crop for rotation');
    }

    @isTest
    static void testInvalidFieldName() {
        // Test with invalid field name
        SmartRotationPlanCreator.SmartRotationRequest request = new SmartRotationPlanCreator.SmartRotationRequest();
        request.fieldName = 'Invalid Field';
        request.startDate = Date.newInstance(2025, 3, 1);
        request.primaryCashCrop = 'Tomatoes';
        
        Test.startTest();
        List<SmartRotationPlanCreator.SmartRotationResponse> responses = 
            SmartRotationPlanCreator.createSmartRotationPlan(new List<SmartRotationPlanCreator.SmartRotationRequest>{request});
        Test.stopTest();
        
        // Verify error response
        SmartRotationPlanCreator.SmartRotationResponse response = responses[0];
        System.assertEquals(false, response.success, 'Should not be successful');
        System.assert(response.errorMessage.contains('Field not found'), 'Should contain field not found error');
        System.assertEquals(0, response.numberOfSeasonsCreated, 'Should not create any seasons');
    }

    @isTest
    static void testMissingRequiredFields() {
        // Test with missing field name
        SmartRotationPlanCreator.SmartRotationRequest request = new SmartRotationPlanCreator.SmartRotationRequest();
        request.fieldName = '';
        request.startDate = Date.newInstance(2025, 3, 1);
        request.primaryCashCrop = 'Tomatoes';
        
        Test.startTest();
        List<SmartRotationPlanCreator.SmartRotationResponse> responses = 
            SmartRotationPlanCreator.createSmartRotationPlan(new List<SmartRotationPlanCreator.SmartRotationRequest>{request});
        Test.stopTest();
        
        // Verify error response
        SmartRotationPlanCreator.SmartRotationResponse response = responses[0];
        System.assertEquals(false, response.success, 'Should not be successful');
        System.assert(response.errorMessage.contains('Field name is required'), 'Should contain required field error');
    }

    @isTest
    static void testMissingStartDate() {
        // Test with missing start date
        SmartRotationPlanCreator.SmartRotationRequest request = new SmartRotationPlanCreator.SmartRotationRequest();
        request.fieldName = 'West 99 Field';
        request.startDate = null;
        request.primaryCashCrop = 'Tomatoes';
        
        Test.startTest();
        List<SmartRotationPlanCreator.SmartRotationResponse> responses = 
            SmartRotationPlanCreator.createSmartRotationPlan(new List<SmartRotationPlanCreator.SmartRotationRequest>{request});
        Test.stopTest();
        
        // Verify error response
        SmartRotationPlanCreator.SmartRotationResponse response = responses[0];
        System.assertEquals(false, response.success, 'Should not be successful');
        System.assert(response.errorMessage.contains('Start date is required'), 'Should contain start date error');
    }

    @isTest
    static void testMissingPrimaryCrop() {
        // Test with missing primary crop
        SmartRotationPlanCreator.SmartRotationRequest request = new SmartRotationPlanCreator.SmartRotationRequest();
        request.fieldName = 'West 99 Field';
        request.startDate = Date.newInstance(2025, 3, 1);
        request.primaryCashCrop = '';
        
        Test.startTest();
        List<SmartRotationPlanCreator.SmartRotationResponse> responses = 
            SmartRotationPlanCreator.createSmartRotationPlan(new List<SmartRotationPlanCreator.SmartRotationRequest>{request});
        Test.stopTest();
        
        // Verify error response
        SmartRotationPlanCreator.SmartRotationResponse response = responses[0];
        System.assertEquals(false, response.success, 'Should not be successful');
        System.assert(response.errorMessage.contains('Primary cash crop is required'), 'Should contain primary crop error');
    }

    @isTest
    static void testSeasonDateCalculations() {
        // Test that season dates are calculated correctly
        SmartRotationPlanCreator.SmartRotationRequest request = new SmartRotationPlanCreator.SmartRotationRequest();
        request.fieldName = 'West 99 Field';
        request.startDate = Date.newInstance(2025, 3, 1);
        request.primaryCashCrop = 'Lettuce';
        
        Test.startTest();
        List<SmartRotationPlanCreator.SmartRotationResponse> responses = 
            SmartRotationPlanCreator.createSmartRotationPlan(new List<SmartRotationPlanCreator.SmartRotationRequest>{request});
        Test.stopTest();
        
        // Verify season date calculations
        List<digitalm__DM_Season__c> year1Seasons = [SELECT digitalm__DM_Season__c, digitalm__DM_Start_Date__c, digitalm__DM_End_Date__c 
                                                    FROM digitalm__DM_Season__c 
                                                    WHERE digitalm__DM_Year__c = 'Year 1' 
                                                    ORDER BY digitalm__DM_Start_Date__c];
        
        System.assertEquals(4, year1Seasons.size(), 'Should have 4 seasons in Year 1');
        
        // Check Spring dates
        System.assertEquals(Date.newInstance(2025, 3, 1), year1Seasons[0].digitalm__DM_Start_Date__c, 'Spring should start March 1');
        System.assertEquals(Date.newInstance(2025, 5, 31), year1Seasons[0].digitalm__DM_End_Date__c, 'Spring should end May 31');
        
        // Check Summer dates
        System.assertEquals(Date.newInstance(2025, 6, 1), year1Seasons[1].digitalm__DM_Start_Date__c, 'Summer should start June 1');
        System.assertEquals(Date.newInstance(2025, 8, 31), year1Seasons[1].digitalm__DM_End_Date__c, 'Summer should end August 31');
        
        // Check Fall dates
        System.assertEquals(Date.newInstance(2025, 9, 1), year1Seasons[2].digitalm__DM_Start_Date__c, 'Fall should start September 1');
        System.assertEquals(Date.newInstance(2025, 11, 30), year1Seasons[2].digitalm__DM_End_Date__c, 'Fall should end November 30');
        
        // Check Winter dates
        System.assertEquals(Date.newInstance(2025, 12, 1), year1Seasons[3].digitalm__DM_Start_Date__c, 'Winter should start December 1');
        System.assertEquals(Date.newInstance(2026, 2, 28), year1Seasons[3].digitalm__DM_End_Date__c, 'Winter should end February 28 next year');
    }

    @isTest
    static void testCoverCropRotation() {
        // Test that cover crops rotate properly
        SmartRotationPlanCreator.SmartRotationRequest request = new SmartRotationPlanCreator.SmartRotationRequest();
        request.fieldName = 'West 99 Field';
        request.startDate = Date.newInstance(2025, 3, 1);
        request.primaryCashCrop = 'Beans';
        
        Test.startTest();
        List<SmartRotationPlanCreator.SmartRotationResponse> responses = 
            SmartRotationPlanCreator.createSmartRotationPlan(new List<SmartRotationPlanCreator.SmartRotationRequest>{request});
        Test.stopTest();
        
        // Verify cover crop rotation
        List<digitalm__DM_Season__c> summerSeasons = [SELECT digitalm__DM_Crop__c, digitalm__DM_Year__c, digitalm__DM_Crop_Type__c 
                                                     FROM digitalm__DM_Season__c 
                                                     WHERE digitalm__DM_Season__c = 'Summer' 
                                                     ORDER BY digitalm__DM_Start_Date__c];
        
        System.assertEquals(4, summerSeasons.size(), 'Should have 4 summer seasons');
        
        // All summer seasons should be cover crops
        for (digitalm__DM_Season__c season : summerSeasons) {
            System.assertEquals('Cover Crop', season.digitalm__DM_Crop_Type__c, 'Summer seasons should be cover crops');
            System.assertNotEquals(null, season.digitalm__DM_Crop__c, 'Cover crop should have a crop name');
        }
        
        // Cover crops should rotate (not all the same)
        Set<String> coverCrops = new Set<String>();
        for (digitalm__DM_Season__c season : summerSeasons) {
            coverCrops.add(season.digitalm__DM_Crop__c);
        }
        System.assert(coverCrops.size() > 1, 'Should have variety in cover crops');
    }

    @isTest
    static void testCropSuitabilityValidation_Success() {
        // Test that suitable crops pass validation
        SmartRotationPlanCreator.SmartRotationRequest request = new SmartRotationPlanCreator.SmartRotationRequest();
        request.fieldName = 'West 99 Field'; // Has Loamy soil, suitable for tomatoes
        request.startDate = Date.newInstance(2025, 3, 1);
        request.primaryCashCrop = 'Tomatoes'; // Suitable for Loamy soil

        Test.startTest();
        List<SmartRotationPlanCreator.SmartRotationResponse> responses =
            SmartRotationPlanCreator.createSmartRotationPlan(new List<SmartRotationPlanCreator.SmartRotationRequest>{request});
        Test.stopTest();

        // Should succeed because Tomatoes are suitable for Loamy soil
        SmartRotationPlanCreator.SmartRotationResponse response = responses[0];
        System.assertEquals(true, response.success, 'Should be successful for suitable crop: ' + response.errorMessage);
    }

    @isTest
    static void testCropSuitabilityValidation_Failure() {
        // Test that unsuitable crops fail validation
        SmartRotationPlanCreator.SmartRotationRequest request = new SmartRotationPlanCreator.SmartRotationRequest();
        request.fieldName = 'Unsuitable Field'; // Has Clay soil and River water
        request.startDate = Date.newInstance(2025, 3, 1);
        request.primaryCashCrop = 'Lettuce'; // Not suitable for Clay soil or River water

        Test.startTest();
        List<SmartRotationPlanCreator.SmartRotationResponse> responses =
            SmartRotationPlanCreator.createSmartRotationPlan(new List<SmartRotationPlanCreator.SmartRotationRequest>{request});
        Test.stopTest();

        // Should fail because Lettuce is not suitable for Clay soil or River water
        SmartRotationPlanCreator.SmartRotationResponse response = responses[0];
        System.assertEquals(false, response.success, 'Should fail for unsuitable crop');
        System.assert(response.errorMessage.contains('suitability validation failed'), 'Should contain suitability error message');
        System.assert(response.errorMessage.contains('Lettuce'), 'Should mention the crop in error');
        System.assertEquals(0, response.numberOfSeasonsCreated, 'Should not create any seasons when validation fails');
    }

    @isTest
    static void testFieldDetailsRetrieval() {
        // Test that field details are properly retrieved
        SmartRotationPlanCreator.SmartRotationRequest request = new SmartRotationPlanCreator.SmartRotationRequest();
        request.fieldName = 'West 99 Field';
        request.startDate = Date.newInstance(2025, 3, 1);
        request.primaryCashCrop = 'Corn'; // Suitable for Loamy soil

        Test.startTest();
        List<SmartRotationPlanCreator.SmartRotationResponse> responses =
            SmartRotationPlanCreator.createSmartRotationPlan(new List<SmartRotationPlanCreator.SmartRotationRequest>{request});
        Test.stopTest();

        // Should succeed and create plan
        SmartRotationPlanCreator.SmartRotationResponse response = responses[0];
        System.assertEquals(true, response.success, 'Should be successful: ' + response.errorMessage);

        // Verify that the field properties were considered (plan created successfully)
        System.assertNotEquals(null, response.rotationPlanId, 'Should create rotation plan');
        System.assertEquals(16, response.numberOfSeasonsCreated, 'Should create all seasons');
    }
}
