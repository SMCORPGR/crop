public with sharing class AgentforceSimpleRotationCreator {

    @InvocableMethod(
        label='Create Rotation Plan from Agent JSON'
        description='Creates a Rotation Plan and Season records from a simple JSON string input - Agentforce compatible'
    )
    public static List<SimpleRotationResponse> createRotationPlanFromJson(List<SimpleRotationRequest> requests) {
        List<SimpleRotationResponse> responses = new List<SimpleRotationResponse>();

        for (SimpleRotationRequest req : requests) {
            try {
                SimpleRotationResponse response = processSimpleRequest(req);
                responses.add(response);
            } catch (Exception e) {
                // Create error response
                SimpleRotationResponse errorResponse = new SimpleRotationResponse();
                errorResponse.success = false;
                errorResponse.errorMessage = 'Error processing request: ' + e.getMessage();
                errorResponse.rotationPlanId = '';
                errorResponse.numberOfSeasonsCreated = 0;
                responses.add(errorResponse);
            }
        }

        return responses;
    }

    private static SimpleRotationResponse processSimpleRequest(SimpleRotationRequest req) {
        SimpleRotationResponse response = new SimpleRotationResponse();
        
        // Validate input
        if (String.isBlank(req.jsonData)) {
            throw new IllegalArgumentException('JSON data is required');
        }

        // Parse JSON
        RotationPlanData planData = parseJsonData(req.jsonData);
        
        // Validate required fields
        if (String.isBlank(planData.rotationPlanName) || String.isBlank(planData.fieldName)) {
            throw new IllegalArgumentException('Rotation Plan Name and Field Name are required');
        }

        // Look up Field by Name
        Id fieldId = getFieldIdByName(planData.fieldName);
        if (fieldId == null) {
            throw new IllegalArgumentException('Field not found: ' + planData.fieldName);
        }

        // Create Rotation Plan
        digitalm__DM_Rotation_Plan__c rotationPlan = createRotationPlan(planData, fieldId);
        
        // Create Season records
        List<digitalm__DM_Season__c> seasons = createSeasons(planData.seasons, rotationPlan.Id);

        // Prepare successful response
        response.success = true;
        response.rotationPlanId = rotationPlan.Id;
        response.numberOfSeasonsCreated = seasons.size();
        response.rotationPlanName = rotationPlan.Name;
        response.errorMessage = '';

        return response;
    }

    private static digitalm__DM_Rotation_Plan__c createRotationPlan(RotationPlanData planData, Id fieldId) {
        // Check CRUD permissions
        if (!Schema.sObjectType.digitalm__DM_Rotation_Plan__c.isCreateable()) {
            throw new SecurityException('Insufficient permissions to create Rotation Plan records');
        }

        digitalm__DM_Rotation_Plan__c rotationPlan = new digitalm__DM_Rotation_Plan__c();
        rotationPlan.Name = planData.rotationPlanName;
        rotationPlan.digitalm__DM_Start_Date__c = planData.startDate;
        rotationPlan.digitalm__DM_End_Date__c = planData.endDate;
        rotationPlan.digitalm__DM_Field__c = fieldId;
        rotationPlan.digitalm__DM_Status__c = String.isNotBlank(planData.status) ? planData.status : 'Draft';
        
        insert rotationPlan;
        return rotationPlan;
    }

    private static List<digitalm__DM_Season__c> createSeasons(List<SeasonData> seasonDataList, Id rotationPlanId) {
        if (seasonDataList == null || seasonDataList.isEmpty()) {
            return new List<digitalm__DM_Season__c>();
        }

        // Check CRUD permissions
        if (!Schema.sObjectType.digitalm__DM_Season__c.isCreateable()) {
            throw new SecurityException('Insufficient permissions to create Season records');
        }

        List<digitalm__DM_Season__c> seasons = new List<digitalm__DM_Season__c>();
        
        for (SeasonData seasonData : seasonDataList) {
            digitalm__DM_Season__c season = new digitalm__DM_Season__c();
            season.Name = seasonData.seasonName;
            season.digitalm__DM_Start_Date__c = seasonData.startDate;
            season.digitalm__DM_End_Date__c = seasonData.endDate;
            season.digitalm__DM_Crop__c = seasonData.crop;
            season.digitalm__DM_Crop_Type__c = normalizeCropType(seasonData.cropType);
            season.digitalm__DM_Purpose__c = seasonData.purpose;
            season.digitalm__DM_Season__c = normalizeSeason(seasonData.season);
            season.digitalm__DM_Year__c = normalizeYear(seasonData.year);
            season.digitalm__DM_Zone__c = String.isNotBlank(seasonData.zone) ? seasonData.zone : 'In-Bed';
            season.digitalm__DM_Rotation_Plan__c = rotationPlanId;
            seasons.add(season);
        }
        
        if (!seasons.isEmpty()) {
            insert seasons;
        }

        return seasons;
    }

    private static Id getFieldIdByName(String fieldName) {
        // Check CRUD permissions
        if (!Schema.sObjectType.digitalm__DM_Field__c.isAccessible()) {
            throw new SecurityException('Insufficient permissions to access Field records');
        }
        
        List<digitalm__DM_Field__c> fields = [
            SELECT Id 
            FROM digitalm__DM_Field__c 
            WHERE Name = :fieldName 
            LIMIT 1
        ];
        return fields.isEmpty() ? null : fields[0].Id;
    }

    private static RotationPlanData parseJsonData(String jsonString) {
        try {
            // Clean JSON string
            String cleanJson = cleanJsonString(jsonString);
            
            // Deserialize JSON
            RotationPlanData planData = (RotationPlanData) JSON.deserialize(cleanJson, RotationPlanData.class);
            
            if (planData == null) {
                throw new IllegalArgumentException('JSON deserialization resulted in null object');
            }
            
            // Ensure seasons list is not null
            if (planData.seasons == null) {
                planData.seasons = new List<SeasonData>();
            }
            
            return planData;
        } catch (JSONException e) {
            throw new IllegalArgumentException('Invalid JSON format: ' + e.getMessage());
        } catch (Exception e) {
            throw new IllegalArgumentException('Error parsing JSON: ' + e.getMessage());
        }
    }

    private static String cleanJsonString(String jsonString) {
        if (String.isBlank(jsonString)) {
            throw new IllegalArgumentException('JSON string cannot be empty');
        }
        
        String cleaned = jsonString.trim();
        
        // Remove markdown code block markers if present
        if (cleaned.startsWith('```json')) {
            cleaned = cleaned.substring(7);
        }
        if (cleaned.startsWith('```')) {
            cleaned = cleaned.substring(3);
        }
        if (cleaned.endsWith('```')) {
            cleaned = cleaned.substring(0, cleaned.length() - 3);
        }
        
        return cleaned.trim();
    }

    private static String normalizeCropType(String cropType) {
        if (String.isBlank(cropType)) {
            return 'Cash Crop'; // Default value
        }
        
        Map<String, String> cropTypeMap = new Map<String, String>{
            'cash crop' => 'Cash Crop',
            'cover crop' => 'Cover Crop',
            'cover crop incorporation' => 'Cover Crop Incorporation',
            'fallow' => 'Fallow'
        };
        
        String normalized = cropTypeMap.get(cropType.toLowerCase());
        return normalized != null ? normalized : cropType;
    }

    private static String normalizeSeason(String season) {
        if (String.isBlank(season)) {
            return season;
        }
        
        Map<String, String> seasonMap = new Map<String, String>{
            'spring' => 'Spring',
            'summer' => 'Summer',
            'fall' => 'Fall',
            'winter' => 'Winter'
        };
        
        String normalized = seasonMap.get(season.toLowerCase());
        return normalized != null ? normalized : season;
    }

    private static String normalizeYear(String year) {
        if (String.isBlank(year)) {
            return 'Year 1'; // Default value
        }
        
        // If it's already in "Year X" format, return as is
        if (year.toLowerCase().startsWith('year ')) {
            return year;
        }
        
        // Try to convert numeric year to "Year X" format
        try {
            Integer yearNum = Integer.valueOf(year);
            if (yearNum >= 1 && yearNum <= 10) {
                return 'Year ' + yearNum;
            }
        } catch (Exception e) {
            System.debug('Year conversion failed for value: ' + year + ', error: ' + e.getMessage());
        }
        
        // Default mapping for calendar years
        Map<String, String> yearMap = new Map<String, String>{
            '2025' => 'Year 1',
            '2026' => 'Year 2',
            '2027' => 'Year 3',
            '2028' => 'Year 4',
            '2029' => 'Year 5'
        };
        
        String normalized = yearMap.get(year);
        return normalized != null ? normalized : 'Year 1';
    }

    // ----------- Input/Output Classes -----------
    public class SimpleRotationRequest {
        @InvocableVariable(label='JSON Data' description='Complete rotation plan data as JSON string' required=true)
        public String jsonData;
    }

    public class SimpleRotationResponse {
        @InvocableVariable(label='Success' description='Whether the operation was successful')
        public Boolean success;

        @InvocableVariable(label='Rotation Plan ID' description='ID of the created rotation plan')
        public String rotationPlanId;

        @InvocableVariable(label='Rotation Plan Name' description='Name of the created rotation plan')
        public String rotationPlanName;

        @InvocableVariable(label='Number of Seasons Created' description='Number of season records created')
        public Integer numberOfSeasonsCreated;

        @InvocableVariable(label='Error Message' description='Error message if operation failed')
        public String errorMessage;
    }

    // ----------- JSON Deserialization Classes -----------
    public class RotationPlanData {
        public String rotationPlanName;
        public String fieldName;
        public Date startDate;
        public Date endDate;
        public String status;
        public List<SeasonData> seasons;
    }

    public class SeasonData {
        public String seasonName;
        public Date startDate;
        public Date endDate;
        public String crop;
        public String cropType;
        public String purpose;
        public String season;
        public String year;
        public String zone;
    }
}
