public with sharing class SmartRotationPlanCreator {

    @InvocableMethod(
        label='Create Smart Rotation Plan'
        description='Creates a complete rotation plan from minimal inputs - field name, start date, and primary crop'
    )
    public static List<SmartRotationResponse> createSmartRotationPlan(List<SmartRotationRequest> requests) {
        List<SmartRotationResponse> responses = new List<SmartRotationResponse>();

        for (SmartRotationRequest req : requests) {
            try {
                SmartRotationResponse response = processSmartRequest(req);
                responses.add(response);
            } catch (Exception e) {
                SmartRotationResponse errorResponse = new SmartRotationResponse();
                errorResponse.success = false;
                errorResponse.errorMessage = 'Error creating rotation plan: ' + e.getMessage();
                errorResponse.rotationPlanId = '';
                errorResponse.numberOfSeasonsCreated = 0;
                responses.add(errorResponse);
            }
        }

        return responses;
    }

    private static SmartRotationResponse processSmartRequest(SmartRotationRequest req) {
        SmartRotationResponse response = new SmartRotationResponse();
        
        // Validate required inputs
        if (String.isBlank(req.fieldName)) {
            throw new IllegalArgumentException('Field name is required');
        }
        if (req.startDate == null) {
            throw new IllegalArgumentException('Start date is required');
        }
        if (String.isBlank(req.primaryCashCrop)) {
            throw new IllegalArgumentException('Primary cash crop is required');
        }

        // Look up Field by Name and get field details for suitability validation
        FieldDetails fieldDetails = getFieldDetailsByName(req.fieldName);
        if (fieldDetails == null) {
            throw new IllegalArgumentException('Field not found: ' + req.fieldName);
        }

        // Validate crop suitability for the field BEFORE creating any records
        validateCropSuitabilityForField(req.primaryCashCrop, fieldDetails);

        // Generate intelligent rotation plan name
        String planName = generatePlanName(req.fieldName, req.primaryCashCrop, req.startDate);

        // Calculate end date (4-year rotation)
        Date endDate = req.startDate.addYears(4).addDays(-1);

        // Create Rotation Plan
        digitalm__DM_Rotation_Plan__c rotationPlan = createRotationPlan(planName, fieldDetails.fieldId, req.startDate, endDate);
        
        // Generate intelligent seasons based on primary crop and best practices
        List<digitalm__DM_Season__c> seasons = generateIntelligentSeasons(
            rotationPlan.Id, 
            req.primaryCashCrop, 
            req.startDate
        );

        // Prepare successful response
        response.success = true;
        response.rotationPlanId = rotationPlan.Id;
        response.rotationPlanName = rotationPlan.Name;
        response.numberOfSeasonsCreated = seasons.size();
        response.errorMessage = '';

        return response;
    }

    private static digitalm__DM_Rotation_Plan__c createRotationPlan(String planName, Id fieldId, Date startDate, Date endDate) {
        // Check CRUD permissions
        if (!Schema.sObjectType.digitalm__DM_Rotation_Plan__c.isCreateable()) {
            throw new SecurityException('Insufficient permissions to create Rotation Plan records');
        }

        digitalm__DM_Rotation_Plan__c rotationPlan = new digitalm__DM_Rotation_Plan__c();
        rotationPlan.Name = planName;
        rotationPlan.digitalm__DM_Start_Date__c = startDate;
        rotationPlan.digitalm__DM_End_Date__c = endDate;
        rotationPlan.digitalm__DM_Field__c = fieldId;
        rotationPlan.digitalm__DM_Status__c = 'Draft';
        
        insert rotationPlan;
        return rotationPlan;
    }

    private static List<digitalm__DM_Season__c> generateIntelligentSeasons(Id rotationPlanId, String primaryCashCrop, Date startDate) {
        // Check CRUD permissions
        if (!Schema.sObjectType.digitalm__DM_Season__c.isCreateable()) {
            throw new SecurityException('Insufficient permissions to create Season records');
        }

        List<digitalm__DM_Season__c> seasons = new List<digitalm__DM_Season__c>();
        
        // Generate 4-year rotation with intelligent crop selection
        for (Integer year = 1; year <= 4; year++) {
            Date yearStart = startDate.addYears(year - 1);
            
            // Spring season - Primary cash crop in year 1, rotate others
            seasons.add(createSeason(
                rotationPlanId,
                'Spring Year ' + year,
                getSpringStartDate(yearStart),
                getSpringEndDate(yearStart),
                getSpringCrop(primaryCashCrop, year),
                'Cash Crop',
                'Primary growing season for cash crop',
                'Spring',
                'Year ' + year
            ));
            
            // Summer season - Cover crop for soil health
            seasons.add(createSeason(
                rotationPlanId,
                'Summer Year ' + year,
                getSummerStartDate(yearStart),
                getSummerEndDate(yearStart),
                getSummerCoverCrop(year),
                'Cover Crop',
                'Nitrogen fixation and soil improvement',
                'Summer',
                'Year ' + year
            ));
            
            // Fall season - Cover crop for erosion control
            seasons.add(createSeason(
                rotationPlanId,
                'Fall Year ' + year,
                getFallStartDate(yearStart),
                getFallEndDate(yearStart),
                getFallCoverCrop(year),
                'Cover Crop',
                'Erosion control and organic matter',
                'Fall',
                'Year ' + year
            ));
            
            // Winter season - Fallow or winter cover
            seasons.add(createSeason(
                rotationPlanId,
                'Winter Year ' + year,
                getWinterStartDate(yearStart),
                getWinterEndDate(yearStart),
                getWinterCrop(year),
                getWinterCropType(year),
                'Field rest and soil protection',
                'Winter',
                'Year ' + year
            ));
        }
        
        if (!seasons.isEmpty()) {
            insert seasons;
        }

        return seasons;
    }

    private static digitalm__DM_Season__c createSeason(Id rotationPlanId, String seasonName, Date startDate, Date endDate, 
                                                      String crop, String cropType, String purpose, String season, String year) {
        digitalm__DM_Season__c seasonRecord = new digitalm__DM_Season__c();
        seasonRecord.Name = seasonName;
        seasonRecord.digitalm__DM_Start_Date__c = startDate;
        seasonRecord.digitalm__DM_End_Date__c = endDate;
        seasonRecord.digitalm__DM_Crop__c = crop;
        seasonRecord.digitalm__DM_Crop_Type__c = cropType;
        seasonRecord.digitalm__DM_Purpose__c = purpose;
        seasonRecord.digitalm__DM_Season__c = season;
        seasonRecord.digitalm__DM_Year__c = year;
        seasonRecord.digitalm__DM_Zone__c = 'In-Bed';
        seasonRecord.digitalm__DM_Rotation_Plan__c = rotationPlanId;
        return seasonRecord;
    }

    // Intelligent crop selection methods
    private static String getSpringCrop(String primaryCrop, Integer year) {
        Map<Integer, Map<String, String>> rotationMap = new Map<Integer, Map<String, String>>{
            1 => new Map<String, String>{
                'Tomatoes' => 'Tomatoes',
                'Peppers' => 'Peppers',
                'Lettuce' => 'Lettuce',
                'Corn' => 'Corn',
                'Beans' => 'Beans'
            },
            2 => new Map<String, String>{
                'Tomatoes' => 'Peppers',
                'Peppers' => 'Lettuce',
                'Lettuce' => 'Beans',
                'Corn' => 'Tomatoes',
                'Beans' => 'Corn'
            },
            3 => new Map<String, String>{
                'Tomatoes' => 'Lettuce',
                'Peppers' => 'Beans',
                'Lettuce' => 'Corn',
                'Corn' => 'Peppers',
                'Beans' => 'Lettuce'
            },
            4 => new Map<String, String>{
                'Tomatoes' => 'Beans',
                'Peppers' => 'Corn',
                'Lettuce' => 'Tomatoes',
                'Corn' => 'Lettuce',
                'Beans' => 'Peppers'
            }
        };
        
        String crop = rotationMap.get(year)?.get(primaryCrop);
        return crop != null ? crop : primaryCrop;
    }

    private static String getSummerCoverCrop(Integer year) {
        List<String> coverCrops = new List<String>{'Crimson Clover', 'Buckwheat', 'Sorghum-Sudan', 'Cowpeas'};
        return coverCrops[Math.mod(year - 1, coverCrops.size())];
    }

    private static String getFallCoverCrop(Integer year) {
        List<String> fallCrops = new List<String>{'Winter Rye', 'Oats', 'Triticale', 'Barley'};
        return fallCrops[Math.mod(year - 1, fallCrops.size())];
    }

    private static String getWinterCrop(Integer year) {
        List<String> winterOptions = new List<String>{'Winter Peas', 'Hairy Vetch', 'Winter Rye', 'Fallow'};
        return winterOptions[Math.mod(year - 1, winterOptions.size())];
    }

    private static String getWinterCropType(Integer year) {
        return Math.mod(year, 4) == 0 ? 'Fallow' : 'Cover Crop';
    }

    // Date calculation methods
    private static Date getSpringStartDate(Date yearStart) {
        return Date.newInstance(yearStart.year(), 3, 1); // March 1
    }

    private static Date getSpringEndDate(Date yearStart) {
        return Date.newInstance(yearStart.year(), 5, 31); // May 31
    }

    private static Date getSummerStartDate(Date yearStart) {
        return Date.newInstance(yearStart.year(), 6, 1); // June 1
    }

    private static Date getSummerEndDate(Date yearStart) {
        return Date.newInstance(yearStart.year(), 8, 31); // August 31
    }

    private static Date getFallStartDate(Date yearStart) {
        return Date.newInstance(yearStart.year(), 9, 1); // September 1
    }

    private static Date getFallEndDate(Date yearStart) {
        return Date.newInstance(yearStart.year(), 11, 30); // November 30
    }

    private static Date getWinterStartDate(Date yearStart) {
        return Date.newInstance(yearStart.year(), 12, 1); // December 1
    }

    private static Date getWinterEndDate(Date yearStart) {
        return Date.newInstance(yearStart.year() + 1, 2, 28); // February 28 next year
    }

    private static FieldDetails getFieldDetailsByName(String fieldName) {
        // Check CRUD permissions
        if (!Schema.sObjectType.digitalm__DM_Field__c.isAccessible()) {
            throw new SecurityException('Insufficient permissions to access Field records');
        }

        List<digitalm__DM_Field__c> fields = [
            SELECT Id, Name, digitalm__DM_Soil_Type__c, digitalm__DM_GIS_Coordinates__c,
                   digitalm__DM_Water_Source__c, digitalm__DM_Land_Use__c, digitalm__DM_Total_Area__c
            FROM digitalm__DM_Field__c
            WHERE Name = :fieldName
            LIMIT 1
        ];

        if (fields.isEmpty()) {
            return null;
        }

        digitalm__DM_Field__c field = fields[0];
        FieldDetails details = new FieldDetails();
        details.fieldId = field.Id;
        details.fieldName = field.Name;
        details.soilType = field.digitalm__DM_Soil_Type__c;
        details.gisCoordinates = field.digitalm__DM_GIS_Coordinates__c;
        details.waterSource = field.digitalm__DM_Water_Source__c;
        details.landUse = field.digitalm__DM_Land_Use__c;
        details.totalArea = field.digitalm__DM_Total_Area__c;

        return details;
    }

    private static void validateCropSuitabilityForField(String primaryCrop, FieldDetails fieldDetails) {
        List<String> suitabilityIssues = new List<String>();

        // Validate soil type suitability
        if (String.isNotBlank(fieldDetails.soilType)) {
            if (!isCropSuitableForSoilType(primaryCrop, fieldDetails.soilType)) {
                suitabilityIssues.add(primaryCrop + ' is not well-suited for ' + fieldDetails.soilType + ' soil');
            }
        }

        // Validate water requirements
        if (String.isNotBlank(fieldDetails.waterSource)) {
            if (!isCropSuitableForWaterSource(primaryCrop, fieldDetails.waterSource)) {
                suitabilityIssues.add(primaryCrop + ' requires different water conditions than available (' + fieldDetails.waterSource + ')');
            }
        }

        // Validate land use compatibility
        if (String.isNotBlank(fieldDetails.landUse)) {
            if (!isCropSuitableForLandUse(primaryCrop, fieldDetails.landUse)) {
                suitabilityIssues.add(primaryCrop + ' is not compatible with ' + fieldDetails.landUse + ' land use');
            }
        }

        // Validate climate zone if GIS coordinates are available
        if (fieldDetails.gisCoordinates != null) {
            if (!isCropSuitableForClimate(primaryCrop, fieldDetails.gisCoordinates)) {
                suitabilityIssues.add(primaryCrop + ' may not be suitable for this climate zone');
            }
        }

        // If there are suitability issues, throw an exception
        if (!suitabilityIssues.isEmpty()) {
            String errorMessage = 'Crop suitability validation failed for ' + fieldDetails.fieldName + ': ' + String.join(suitabilityIssues, '; ');
            throw new IllegalArgumentException(errorMessage);
        }
    }

    private static String generatePlanName(String fieldName, String primaryCrop, Date startDate) {
        return fieldName + ' ' + primaryCrop + ' Rotation Plan (' + startDate.year() + ')';
    }

    // Crop suitability validation methods
    private static Boolean isCropSuitableForSoilType(String crop, String soilType) {
        // Define crop-soil compatibility matrix
        Map<String, Set<String>> cropSoilCompatibility = new Map<String, Set<String>>{
            'Tomatoes' => new Set<String>{'Loamy', 'Sandy', 'Silty'},
            'Peppers' => new Set<String>{'Loamy', 'Sandy', 'Silty'},
            'Lettuce' => new Set<String>{'Loamy', 'Silty'},
            'Corn' => new Set<String>{'Loamy', 'Clay', 'Silty'},
            'Beans' => new Set<String>{'Loamy', 'Sandy', 'Clay'},
            'Carrots' => new Set<String>{'Sandy', 'Loamy'},
            'Broccoli' => new Set<String>{'Loamy', 'Clay', 'Silty'},
            'Spinach' => new Set<String>{'Loamy', 'Silty'},
            'Kale' => new Set<String>{'Loamy', 'Clay', 'Silty'},
            'Beets' => new Set<String>{'Loamy', 'Sandy', 'Silty'}
        };

        Set<String> suitableSoils = cropSoilCompatibility.get(crop);
        return suitableSoils != null ? suitableSoils.contains(soilType) : true; // Default to true for unknown crops
    }

    private static Boolean isCropSuitableForWaterSource(String crop, String waterSource) {
        // Define crop water requirements
        Map<String, Set<String>> cropWaterCompatibility = new Map<String, Set<String>>{
            'Tomatoes' => new Set<String>{'Well', 'River', 'Municipal'},
            'Peppers' => new Set<String>{'Well', 'River', 'Municipal'},
            'Lettuce' => new Set<String>{'Well', 'Municipal'}, // Needs clean water
            'Corn' => new Set<String>{'Well', 'River', 'Municipal'},
            'Beans' => new Set<String>{'Well', 'River', 'Municipal'},
            'Carrots' => new Set<String>{'Well', 'Municipal'}, // Needs clean water
            'Broccoli' => new Set<String>{'Well', 'Municipal'},
            'Spinach' => new Set<String>{'Well', 'Municipal'},
            'Kale' => new Set<String>{'Well', 'Municipal'},
            'Beets' => new Set<String>{'Well', 'River', 'Municipal'}
        };

        Set<String> suitableWaterSources = cropWaterCompatibility.get(crop);
        return suitableWaterSources != null ? suitableWaterSources.contains(waterSource) : true;
    }

    private static Boolean isCropSuitableForLandUse(String crop, String landUse) {
        // Most crops are compatible with all land use types, but some have restrictions
        Map<String, Set<String>> cropLandUseCompatibility = new Map<String, Set<String>>{
            'Tomatoes' => new Set<String>{'Certified Organic', 'Transitional', 'Conventional'},
            'Peppers' => new Set<String>{'Certified Organic', 'Transitional', 'Conventional'},
            'Lettuce' => new Set<String>{'Certified Organic', 'Transitional', 'Conventional'},
            'Corn' => new Set<String>{'Certified Organic', 'Transitional', 'Conventional'},
            'Beans' => new Set<String>{'Certified Organic', 'Transitional', 'Conventional'},
            'Carrots' => new Set<String>{'Certified Organic', 'Transitional', 'Conventional'},
            'Broccoli' => new Set<String>{'Certified Organic', 'Transitional', 'Conventional'},
            'Spinach' => new Set<String>{'Certified Organic', 'Transitional', 'Conventional'},
            'Kale' => new Set<String>{'Certified Organic', 'Transitional', 'Conventional'},
            'Beets' => new Set<String>{'Certified Organic', 'Transitional', 'Conventional'}
        };

        Set<String> suitableLandUses = cropLandUseCompatibility.get(crop);
        return suitableLandUses != null ? suitableLandUses.contains(landUse) : true;
    }

    private static Boolean isCropSuitableForClimate(String crop, Location gisCoordinates) {
        // Basic climate zone validation based on latitude
        // This is a simplified version - in production you might use more sophisticated climate data
        if (gisCoordinates == null) {
            return true; // Can't validate without coordinates
        }

        Double latitude = gisCoordinates.getLatitude();
        if (latitude == null) {
            return true;
        }

        // Define crop climate preferences (latitude ranges for optimal growing)
        Map<String, List<Double>> cropClimateRanges = new Map<String, List<Double>>{
            'Tomatoes' => new List<Double>{25.0, 45.0}, // Warm climate crops
            'Peppers' => new List<Double>{25.0, 45.0},
            'Lettuce' => new List<Double>{30.0, 50.0}, // Cool season crops
            'Corn' => new List<Double>{30.0, 50.0},
            'Beans' => new List<Double>{25.0, 50.0}, // Adaptable
            'Carrots' => new List<Double>{35.0, 55.0}, // Cool season
            'Broccoli' => new List<Double>{35.0, 55.0},
            'Spinach' => new List<Double>{35.0, 55.0},
            'Kale' => new List<Double>{35.0, 55.0},
            'Beets' => new List<Double>{30.0, 50.0}
        };

        List<Double> climateRange = cropClimateRanges.get(crop);
        if (climateRange == null || climateRange.size() != 2) {
            return true; // Default to suitable for unknown crops
        }

        Double minLatitude = climateRange[0];
        Double maxLatitude = climateRange[1];

        return Math.abs(latitude) >= minLatitude && Math.abs(latitude) <= maxLatitude;
    }

    // ----------- Input/Output Classes -----------
    public class SmartRotationRequest {
        @InvocableVariable(label='Field Name' description='Name of the field for rotation plan' required=true)
        public String fieldName;

        @InvocableVariable(label='Start Date' description='Start date for the rotation plan' required=true)
        public Date startDate;

        @InvocableVariable(label='Primary Cash Crop' description='Primary cash crop for the rotation' required=true)
        public String primaryCashCrop;
    }

    public class SmartRotationResponse {
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

    // Helper class to hold field details for suitability validation
    public class FieldDetails {
        public Id fieldId;
        public String fieldName;
        public String soilType;
        public Location gisCoordinates;
        public String waterSource;
        public String landUse;
        public Decimal totalArea;
    }
}
