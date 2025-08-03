public with sharing class AgentforceRotationPlanCreator {

    @InvocableMethod(
        label='Create Rotation Plan from Agentforce Recommendation'
        description='Creates a Rotation Plan and related Season records from Agentforce agent JSON recommendation.'
    )
    public static List<AgentforceRotationPlanResponse> createRotationPlanFromAgent(List<AgentforceRotationPlanRequest> requests) {
        List<AgentforceRotationPlanResponse> responses = new List<AgentforceRotationPlanResponse>();

        for (AgentforceRotationPlanRequest req : requests) {
            try {
                AgentforceRotationPlanResponse response = processAgentRequest(req);
                responses.add(response);
            } catch (Exception e) {
                // Create error response
                AgentforceRotationPlanResponse errorResponse = new AgentforceRotationPlanResponse();
                errorResponse.success = false;
                errorResponse.errorMessage = 'Error processing request: ' + e.getMessage();
                responses.add(errorResponse);
            }
        }

        return responses;
    }

    private static AgentforceRotationPlanResponse processAgentRequest(AgentforceRotationPlanRequest req) {
        AgentforceRotationPlanResponse response = new AgentforceRotationPlanResponse();
        
        // Parse JSON if provided, otherwise use direct input
        AgentRotationPlanData planData;
        if (String.isNotBlank(req.jsonRecommendation)) {
            planData = parseJsonRecommendation(req.jsonRecommendation);
        } else {
            planData = new AgentRotationPlanData();
            planData.rotationPlanName = req.rotationPlanName;
            planData.fieldName = req.fieldName;
            planData.startDate = req.startDate;
            planData.endDate = req.endDate;
            planData.status = req.status;
            planData.seasons = req.seasons != null ? req.seasons : new List<AgentSeasonData>();
        }

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
        digitalm__DM_Rotation_Plan__c rotationPlan = new digitalm__DM_Rotation_Plan__c();
        rotationPlan.Name = planData.rotationPlanName;
        rotationPlan.digitalm__DM_Start_Date__c = planData.startDate;
        rotationPlan.digitalm__DM_End_Date__c = planData.endDate;
        rotationPlan.digitalm__DM_Field__c = fieldId;
        rotationPlan.digitalm__DM_Status__c = String.isNotBlank(planData.status) ? planData.status : 'Draft';

        // Check CRUD permissions before insert
        if (!Schema.sObjectType.digitalm__DM_Rotation_Plan__c.isCreateable()) {
            throw new SecurityException('Insufficient permissions to create Rotation Plan records');
        }

        insert rotationPlan;

        // Create Season records
        List<digitalm__DM_Season__c> seasons = new List<digitalm__DM_Season__c>();
        for (AgentSeasonData seasonData : planData.seasons) {
            digitalm__DM_Season__c season = new digitalm__DM_Season__c();
            season.Name = seasonData.seasonName;
            season.digitalm__DM_Start_Date__c = seasonData.startDate;
            season.digitalm__DM_End_Date__c = seasonData.endDate;
            season.digitalm__DM_Crop__c = seasonData.crop;
            season.digitalm__DM_Crop_Type__c = seasonData.cropType;
            season.digitalm__DM_Purpose__c = seasonData.purpose;
            season.digitalm__DM_Season__c = seasonData.season;
            season.digitalm__DM_Year__c = seasonData.year;
            season.digitalm__DM_Zone__c = String.isNotBlank(seasonData.zone) ? seasonData.zone : 'In-Bed';
            season.digitalm__DM_Rotation_Plan__c = rotationPlan.Id;
            seasons.add(season);
        }
        
        if (!seasons.isEmpty()) {
            // Check CRUD permissions before insert
            if (!Schema.sObjectType.digitalm__DM_Season__c.isCreateable()) {
                throw new SecurityException('Insufficient permissions to create Season records');
            }
            insert seasons;
        }

        // Prepare successful response
        response.success = true;
        response.rotationPlanId = rotationPlan.Id;
        response.numberOfSeasonsCreated = seasons.size();
        response.rotationPlanName = rotationPlan.Name;

        return response;
    }

    private static Id getFieldIdByName(String fieldName) {
        // Check CRUD permissions before query
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

    private static AgentRotationPlanData parseJsonRecommendation(String jsonString) {
        try {
            // Clean and validate JSON string
            String cleanJson = cleanJsonString(jsonString);

            // First try direct deserialization
            AgentRotationPlanData planData = (AgentRotationPlanData) JSON.deserialize(cleanJson, AgentRotationPlanData.class);

            // Validate required fields
            if (planData == null) {
                throw new IllegalArgumentException('JSON deserialization resulted in null object');
            }

            // Ensure seasons list is not null
            if (planData.seasons == null) {
                planData.seasons = new List<AgentSeasonData>();
            }

            // Validate and clean season data
            for (AgentSeasonData season : planData.seasons) {
                if (season != null) {
                    validateSeasonData(season);
                }
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

        // Remove any potential markdown formatting or extra characters
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

    private static void validateSeasonData(AgentSeasonData season) {
        // Set default values for missing fields
        if (String.isBlank(season.zone)) {
            season.zone = 'In-Bed';
        }

        // Validate and normalize season name
        season.season = normalizeSeasonName(season.season);

        // Validate and normalize crop type
        season.cropType = normalizeCropType(season.cropType);

        // Validate and normalize year
        season.year = normalizeYear(season.year);
    }

    private static String normalizeSeasonName(String seasonName) {
        if (String.isBlank(seasonName)) {
            return seasonName;
        }

        Map<String, String> seasonMap = new Map<String, String>{
            'spring' => 'Spring',
            'summer' => 'Summer',
            'fall' => 'Fall',
            'winter' => 'Winter'
        };

        String normalized = seasonMap.get(seasonName.toLowerCase());
        return normalized != null ? normalized : seasonName;
    }

    private static String normalizeCropType(String cropType) {
        if (String.isBlank(cropType)) {
            return cropType;
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

    private static String normalizeYear(String year) {
        if (String.isBlank(year)) {
            return year;
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
            // Not a valid number, continue with other checks
            System.debug('Year conversion failed for value: ' + year + ', error: ' + e.getMessage());
        }

        // Try to extract year from formats like "2025" -> "Year 1"
        // This is a simple mapping for demo purposes
        Map<String, String> yearMap = new Map<String, String>{
            '2025' => 'Year 1',
            '2026' => 'Year 2',
            '2027' => 'Year 3',
            '2028' => 'Year 4',
            '2029' => 'Year 5'
        };

        String normalized = yearMap.get(year);
        return normalized != null ? normalized : year;
    }

    // ----------- Input Wrapper Classes -----------
    public class AgentforceRotationPlanRequest {
        @InvocableVariable(label='JSON Recommendation' description='JSON string containing the complete rotation plan recommendation from Agentforce')
        public String jsonRecommendation;

        @InvocableVariable(label='Rotation Plan Name' description='Name of the rotation plan (used if JSON not provided)')
        public String rotationPlanName;

        @InvocableVariable(label='Field Name' description='Name of the field (used if JSON not provided)')
        public String fieldName;

        @InvocableVariable(label='Start Date' description='Start date of the rotation plan (used if JSON not provided)')
        public Date startDate;

        @InvocableVariable(label='End Date' description='End date of the rotation plan (used if JSON not provided)')
        public Date endDate;

        @InvocableVariable(label='Status' description='Status of the rotation plan (used if JSON not provided)')
        public String status;

        @InvocableVariable(label='Seasons' description='List of seasons (used if JSON not provided)')
        public List<AgentSeasonData> seasons;
    }

    public class AgentSeasonData {
        @InvocableVariable(label='Season Name' description='Name of the season (e.g., Spring 2025)')
        public String seasonName;

        @InvocableVariable(label='Start Date' description='Start date of the season')
        public Date startDate;

        @InvocableVariable(label='End Date' description='End date of the season')
        public Date endDate;

        @InvocableVariable(label='Crop' description='Name of the crop')
        public String crop;

        @InvocableVariable(label='Crop Type' description='Type of crop (Cash Crop, Cover Crop, etc.)')
        public String cropType;

        @InvocableVariable(label='Purpose' description='Purpose of the crop/season')
        public String purpose;

        @InvocableVariable(label='Season' description='Season name (Spring, Summer, Fall, Winter)')
        public String season;

        @InvocableVariable(label='Year' description='Year of the season')
        public String year;

        @InvocableVariable(label='Zone' description='Zone within the field')
        public String zone;
    }

    // ----------- JSON Deserialization Classes -----------
    public class AgentRotationPlanData {
        public String rotationPlanName;
        public String fieldName;
        public Date startDate;
        public Date endDate;
        public String status;
        public List<AgentSeasonData> seasons;
    }

    // ----------- Output Wrapper -----------
    public class AgentforceRotationPlanResponse {
        @InvocableVariable(label='Success' description='Whether the operation was successful')
        public Boolean success;

        @InvocableVariable(label='Rotation Plan ID' description='ID of the created rotation plan')
        public Id rotationPlanId;

        @InvocableVariable(label='Rotation Plan Name' description='Name of the created rotation plan')
        public String rotationPlanName;

        @InvocableVariable(label='Number of Seasons Created' description='Number of season records created')
        public Integer numberOfSeasonsCreated;

        @InvocableVariable(label='Error Message' description='Error message if operation failed')
        public String errorMessage;
    }
}
