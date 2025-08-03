# Agentforce Crop Rotation Plan - Quick Testing Guide

## 🚀 **Quick Start Testing**

### **Prerequisites**
- Agentforce enabled in your org
- Crop Planning Advisor agent configured
- "Create Crop Rotation Plan" action created and assigned to agent
- Existing Field records (e.g., "West 99 Field", "East 99 Field")

### **Test 1: Basic Agent Interaction**

1. **Open Agent Window**
   - App Launcher → Search "Agent" → Open Crop Planning Advisor

2. **Start Conversation**
   ```
   User: "I need a 4-year rotation plan for West 99 Field starting in Spring 2025"
   ```

3. **Expected Agent Flow**
   - Agent analyzes requirements
   - Provides rotation recommendation with seasons
   - Asks for confirmation

4. **Accept Recommendation**
   ```
   User: "Yes, create this rotation plan"
   ```

5. **Verify Action Execution**
   - Agent should call "Create Crop Rotation Plan" action
   - Should receive success confirmation
   - Check Rotation Plans tab for new record

### **Test 2: Direct JSON Testing**

Use this JSON for manual testing:

```json
{
  "rotationPlanName": "West 99 Field Test Plan",
  "fieldName": "West 99 Field",
  "startDate": "2025-03-01",
  "endDate": "2029-02-28",
  "status": "Draft",
  "seasons": [
    {
      "seasonName": "Spring Year 1",
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
      "seasonName": "Summer Year 1",
      "startDate": "2025-06-01",
      "endDate": "2025-08-31",
      "crop": "Crimson Clover",
      "cropType": "Cover Crop",
      "purpose": "Nitrogen fixation and soil improvement",
      "season": "Summer",
      "year": "Year 1",
      "zone": "In-Bed"
    },
    {
      "seasonName": "Fall Year 1",
      "startDate": "2025-09-01",
      "endDate": "2025-11-30",
      "crop": "Winter Rye",
      "cropType": "Cover Crop",
      "purpose": "Soil protection and organic matter",
      "season": "Fall",
      "year": "Year 1",
      "zone": "In-Bed"
    },
    {
      "seasonName": "Winter Year 1",
      "startDate": "2025-12-01",
      "endDate": "2026-02-28",
      "crop": "Fallow",
      "cropType": "Fallow",
      "purpose": "Field rest and preparation",
      "season": "Winter",
      "year": "Year 1",
      "zone": "In-Bed"
    }
  ]
}
```

### **Test 3: Error Scenarios**

#### **Invalid Field Name**
```json
{
  "rotationPlanName": "Test Plan",
  "fieldName": "NonExistent Field",
  "startDate": "2025-01-01",
  "endDate": "2025-12-31",
  "seasons": []
}
```
**Expected**: Error message "Field not found: NonExistent Field"

#### **Invalid JSON**
```
{invalid json format}
```
**Expected**: Error message about JSON parsing failure

#### **Missing Required Fields**
```json
{
  "fieldName": "West 99 Field",
  "seasons": []
}
```
**Expected**: Error message about missing rotation plan name

### **Test 4: Data Normalization**

Test that the system correctly normalizes data:

```json
{
  "rotationPlanName": "Normalization Test",
  "fieldName": "West 99 Field",
  "startDate": "2025-01-01",
  "endDate": "2025-12-31",
  "seasons": [
    {
      "seasonName": "spring test",
      "season": "SPRING",
      "cropType": "cash crop",
      "year": "2025",
      "zone": ""
    }
  ]
}
```

**Expected Normalization**:
- `season`: "SPRING" → "Spring"
- `cropType`: "cash crop" → "Cash Crop"
- `year`: "2025" → "Year 1"
- `zone`: "" → "In-Bed"

## 🔍 **Verification Steps**

### **1. Check Created Records**
```
Navigation: App Launcher → Rotation Plans
Verify:
- New rotation plan record exists
- Correct field association
- Proper dates and status
```

### **2. Check Season Records**
```
Navigation: Related list on Rotation Plan record
Verify:
- Correct number of seasons created
- Proper season data (crops, types, dates)
- Normalized values applied correctly
```

### **3. Check Agent Logs**
```
Navigation: Setup → Agentforce → Agent Analytics
Look for:
- Action execution success/failure
- Response times
- Error messages if any
```

### **4. Debug Flow Execution**
```
Navigation: Setup → Process Automation → Flows → DM Agentforce Create Rotation Plan
Check:
- Flow interview logs
- Variable values
- Decision outcomes
```

## 🛠️ **Troubleshooting**

### **Common Issues**

1. **"Field not found" Error**
   - Verify exact field name spelling
   - Check field exists in org
   - Ensure proper capitalization

2. **Permission Errors**
   - Verify user has CRUD access to objects
   - Check field-level security
   - Ensure proper sharing rules

3. **Agent Not Calling Action**
   - Verify action is assigned to agent
   - Check agent instructions include action usage
   - Review agent topic configuration

4. **JSON Parsing Errors**
   - Validate JSON format online
   - Check for special characters
   - Ensure proper date formats

### **Debug Commands**

#### **Test Apex Class Directly**
```apex
// Execute in Developer Console
AgentforceRotationPlanCreator.AgentforceRotationPlanRequest req = 
    new AgentforceRotationPlanCreator.AgentforceRotationPlanRequest();
req.jsonRecommendation = 'YOUR_JSON_HERE';
List<AgentforceRotationPlanCreator.AgentforceRotationPlanResponse> responses = 
    AgentforceRotationPlanCreator.createRotationPlanFromAgent(new List<AgentforceRotationPlanCreator.AgentforceRotationPlanRequest>{req});
System.debug(responses[0]);
```

#### **Test Flow Directly**
```
Navigation: Setup → Process Automation → Flows → DM Agentforce Create Rotation Plan
Click: Run
Input: Test JSON data
Review: Debug details
```

## 📊 **Success Indicators**

✅ **Agent responds appropriately to rotation plan requests**
✅ **Action executes without errors**
✅ **Rotation Plan record created with correct data**
✅ **Season records created and properly linked**
✅ **Data normalization applied correctly**
✅ **Error handling works for invalid inputs**

## 🎯 **Performance Expectations**

- **Response Time**: < 3 seconds for typical rotation plan
- **Success Rate**: > 95% for valid inputs
- **Error Handling**: Graceful failure with helpful messages
- **Data Accuracy**: 100% for normalized and validated data

## 📞 **Support**

If you encounter issues:
1. Check the troubleshooting section above
2. Review debug logs in Developer Console
3. Verify all prerequisites are met
4. Test with provided sample JSON first
