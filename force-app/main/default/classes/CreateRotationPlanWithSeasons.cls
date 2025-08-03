public with sharing class CreateRotationPlanWithSeasons {

    @InvocableMethod(
        label='Create Rotation Plan with Seasons'
        description='Creates a Rotation Plan and related Season records using Field Name to look up Field Id.'
    )
    public static List<RotationPlanCreationResponse> createRotationPlans(List<RotationPlanCreationRequest> requests) {
        List<RotationPlanCreationResponse> responses = new List<RotationPlanCreationResponse>();

        // Collect unique Field Names to bulk query
        Set<String> fieldNames = new Set<String>();
        for (RotationPlanCreationRequest req : requests) {
            if (req.fieldName != null) {
                fieldNames.add(req.fieldName);
            }
        }

        // Query digitalm__DM_Field__c records by Name
        Map<String, Id> fieldNameToIdMap = new Map<String, Id>();
        for (digitalm__DM_Field__c fieldRec : [
            SELECT Id, Name 
            FROM digitalm__DM_Field__c 
            WHERE Name IN :fieldNames
        ]) {
            fieldNameToIdMap.put(fieldRec.Name, fieldRec.Id);
        }

        for (RotationPlanCreationRequest req : requests) {
            Id fieldId = fieldNameToIdMap.get(req.fieldName);
            
            if (fieldId == null) {
                // Optionally throw error or skip — for now, skip this record
                continue;
            }

            // Create Rotation Plan (Parent)
            digitalm__DM_Rotation_Plan__c rotationPlan = new digitalm__DM_Rotation_Plan__c();
            rotationPlan.Name = req.rotationPlanName;
            rotationPlan.digitalm__DM_Start_Date__c = req.startDate;
            rotationPlan.digitalm__DM_End_Date__c = req.endDate;
            rotationPlan.digitalm__DM_Field__c = fieldId;
            rotationPlan.digitalm__DM_Status__c = req.status;
            insert rotationPlan;
            
            // Create related Seasons (Child)
            List<digitalm__DM_Season__c> seasons = new List<digitalm__DM_Season__c>();
            for (SeasonInput seasonInput : req.seasons) {
                digitalm__DM_Season__c season = new digitalm__DM_Season__c();
                season.Name = seasonInput.seasonName;
                season.digitalm__DM_Start_Date__c = seasonInput.startDate;
                season.digitalm__DM_End_Date__c = seasonInput.endDate;
                season.digitalm__DM_Crop__c = seasonInput.crop;
                season.digitalm__DM_Crop_Type__c = seasonInput.cropType;
                season.digitalm__DM_Purpose__c = seasonInput.purpose;
                season.digitalm__DM_Season__c = seasonInput.season;
                season.digitalm__DM_Year__c = seasonInput.year;
                season.digitalm__DM_Zone__c = seasonInput.zone;
                season.digitalm__DM_Rotation_Plan__c = rotationPlan.Id;
                seasons.add(season);
            }
            insert seasons;
            
            // Prepare response
            RotationPlanCreationResponse response = new RotationPlanCreationResponse();
            response.rotationPlanId = rotationPlan.Id;
            response.numberOfSeasonsCreated = seasons.size();
            responses.add(response);
        }

        return responses;
    }

    // ----------- Input Wrappers -----------
    public class RotationPlanCreationRequest {
        @InvocableVariable(required=true)
        public String rotationPlanName;

        @InvocableVariable
        public Date startDate;

        @InvocableVariable
        public Date endDate;

        @InvocableVariable(required=true)
        public String fieldName;

        @InvocableVariable
        public String status;

        @InvocableVariable
        public List<SeasonInput> seasons;
    }

    public class SeasonInput {
        @InvocableVariable
        public String seasonName;

        @InvocableVariable
        public Date startDate;

        @InvocableVariable
        public Date endDate;

        @InvocableVariable
        public String crop;

        @InvocableVariable
        public String cropType;

        @InvocableVariable
        public String purpose;

        @InvocableVariable
        public String season;

        @InvocableVariable
        public String year;

        @InvocableVariable
        public String zone;
    }

    // ----------- Output Wrapper -----------
    public class RotationPlanCreationResponse {
        @InvocableVariable
        public Id rotationPlanId;

        @InvocableVariable
        public Integer numberOfSeasonsCreated;
    }
}