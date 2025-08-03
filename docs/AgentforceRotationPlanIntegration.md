# Agentforce Crop Rotation Plan Integration

This document describes how to integrate Agentforce agents with Salesforce Flow to create crop rotation plans from agent recommendations.

## Overview

The integration consists of:
1. **AgentforceRotationPlanCreator** - Apex class with @InvocableVariable annotations
2. **DM Agentforce Create Rotation Plan** - Flow that processes agent recommendations
3. **JSON parsing utilities** - Handle structured data from agents

## Architecture

```
Agentforce Agent → JSON Recommendation → Flow → Apex Class → Salesforce Records
```

### Data Flow
1. Agent generates crop rotation recommendation
2. Agent passes JSON or structured data to Flow
3. Flow calls Apex class with @InvocableMethod
4. Apex class creates Rotation_Plan__c and Season__c records

## JSON Structure

### Complete JSON Format

```json
{
  "rotationPlanName": "West 99 Field 4-Year Rotation Plan",
  "fieldName": "West 99 Field",
  "startDate": "2025-03-01",
  "endDate": "2029-02-28",
  "status": "Draft",
  "seasons": [
    {
      "seasonName": "Spring 2025",
      "startDate": "2025-03-01",
      "endDate": "2025-05-31",
      "crop": "Tomatoes",
      "cropType": "Cash Crop",
      "purpose": "Primary cash crop for spring season",
      "season": "Spring",
      "year": "Year 1",
      "zone": "In-Bed"
    },
    {
      "seasonName": "Summer 2025",
      "startDate": "2025-06-01",
      "endDate": "2025-08-31",
      "crop": "Crimson Clover",
      "cropType": "Cover Crop",
      "purpose": "Nitrogen fixation and soil improvement",
      "season": "Summer",
      "year": "Year 1",
      "zone": "In-Bed"
    }
  ]
}
```

### Field Descriptions

#### Rotation Plan Fields
- **rotationPlanName** (required): Name of the rotation plan
- **fieldName** (required): Name of the existing Field record
- **startDate**: Start date of the rotation plan (YYYY-MM-DD format)
- **endDate**: End date of the rotation plan (YYYY-MM-DD format)
- **status**: Status of the plan (Draft, In Progress, Complete)

#### Season Fields
- **seasonName**: Display name for the season (e.g., "Spring 2025")
- **startDate**: Season start date (YYYY-MM-DD format)
- **endDate**: Season end date (YYYY-MM-DD format)
- **crop**: Name of the crop to be planted
- **cropType**: Type of crop (Cash Crop, Cover Crop, Cover Crop Incorporation, Fallow)
- **purpose**: Purpose or description of the crop/season
- **season**: Season name (Spring, Summer, Fall, Winter)
- **year**: Year as string (Year 1, Year 2, etc. or numeric values that will be converted)
- **zone**: Zone within field (In-Bed, Inter-row, Perimeter, Pollinator, Under Canopy/Vine)

## Usage Examples

### 1. JSON Input (Recommended)

```apex
// Flow Input Variables
varJsonRecommendation = '{"rotationPlanName":"Test Plan","fieldName":"West 99 Field",...}';
```

### 2. Direct Input (Alternative)

```apex
// Flow Input Variables
varRotationPlanName = "West 99 Field 4-Year Plan";
varFieldName = "West 99 Field";
varStartDate = Date.newInstance(2025, 3, 1);
varEndDate = Date.newInstance(2029, 2, 28);
varStatus = "Draft";
// varSeasons = List of AgentSeasonData objects
```

## Flow Integration

### Input Variables
- `varJsonRecommendation` (String) - Complete JSON recommendation
- `varRotationPlanName` (String) - Plan name (if not using JSON)
- `varFieldName` (String) - Field name (if not using JSON)
- `varStartDate` (Date) - Start date (if not using JSON)
- `varEndDate` (Date) - End date (if not using JSON)
- `varStatus` (String) - Status (if not using JSON)
- `varSeasons` (List<AgentSeasonData>) - Seasons (if not using JSON)

### Output Variables
- `varOutputSuccess` (Boolean) - Success indicator
- `varOutputRotationPlanId` (String) - Created plan ID
- `varOutputMessage` (String) - Success/error message

## Error Handling

The integration includes comprehensive error handling:

### JSON Parsing Errors
- Invalid JSON format
- Missing required fields
- Malformed date formats

### Data Validation Errors
- Field not found
- Invalid picklist values
- Missing required data

### Security Errors
- Insufficient CRUD permissions
- Field-level security violations

## Agent Prompt Guidelines

When configuring Agentforce agents, include these guidelines:

### JSON Output Format
```
Always format your crop rotation recommendations as valid JSON with the following structure:
{
  "rotationPlanName": "descriptive name",
  "fieldName": "exact field name from Salesforce",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD", 
  "status": "Draft",
  "seasons": [...]
}
```

### Field Name Matching
- Use exact Field names from Salesforce (e.g., "West 99 Field", "East 99 Field")
- Field names are case-sensitive

### Date Formatting
- Use ISO date format: YYYY-MM-DD
- Ensure dates are logical (start < end)

### Crop Types
- Use exact picklist values: "Cash Crop", "Cover Crop", "Cover Crop Incorporation", "Fallow"

### Seasons
- Use exact values: "Spring", "Summer", "Fall", "Winter"

## Testing

### Test JSON Payload
```json
{
  "rotationPlanName": "Test Rotation Plan",
  "fieldName": "West 99 Field",
  "startDate": "2025-01-01",
  "endDate": "2026-12-31",
  "status": "Draft",
  "seasons": [
    {
      "seasonName": "Spring 2025",
      "startDate": "2025-03-01",
      "endDate": "2025-05-31",
      "crop": "Test Crop",
      "cropType": "Cash Crop",
      "purpose": "Testing purposes",
      "season": "Spring",
      "year": "2025",
      "zone": "In-Bed"
    }
  ]
}
```

## Agentforce Action Configuration

### Creating the Action
1. Go to Setup → Agentforce → Actions
2. Create new Action with these settings:
   - **Name**: Create Crop Rotation Plan
   - **Type**: Flow
   - **Flow**: DM Agentforce Create Rotation Plan
   - **Description**: Creates rotation plans from agent recommendations

### Action Instructions
```
Use this action to create crop rotation plans in Salesforce when users accept your recommendations.

Input the complete rotation plan as JSON in the jsonRecommendation parameter.

Always include:
- rotationPlanName: Descriptive name for the plan
- fieldName: Exact field name from Salesforce
- startDate and endDate: In YYYY-MM-DD format
- seasons: Array of season objects with crop details

Example usage:
When user says "Create this rotation plan for West 99 Field", call this action with the JSON recommendation.
```

## Troubleshooting

### Common Issues
1. **Field not found**: Verify exact field name spelling
2. **Permission errors**: Ensure user has CRUD access to objects
3. **Date format errors**: Use YYYY-MM-DD format
4. **Invalid picklist values**: Use exact values from documentation

### Debug Steps
1. Check Flow debug logs
2. Verify JSON format with online validator
3. Test with minimal JSON payload
4. Check user permissions on objects and fields
