# Agentforce Crop Rotation Plan - Working Solution Quick Reference

## 🚨 **CRITICAL: Use the Simplified Solution**

**Problem**: Agentforce cannot handle collections/complex data types in Flow actions.
**Solution**: Use simplified approach with single JSON string parameter.

## ✅ **Working Components**

### **Apex Class**
- **File**: `AgentforceSimpleRotationCreator.cls`
- **Method**: `createRotationPlanFromJson`
- **Input**: Single JSON string parameter
- **Output**: Basic data types only (Boolean, String, Integer)

### **Flow**
- **Name**: `DM Simple Agentforce Rotation Plan`
- **Type**: Auto-launched Flow
- **Input**: `varJsonData` (String)
- **Outputs**: `varOutputSuccess`, `varOutputRotationPlanId`, `varOutputMessage`, etc.

### **Test Class**
- **File**: `AgentforceSimpleRotationCreatorTest.cls`
- **Coverage**: 89% with 8 test methods
- **Status**: All tests passing

## 🔧 **Agentforce Action Setup**

### **Action Configuration**
```
Name: Create Crop Rotation Plan
Type: Flow
Flow: DM Simple Agentforce Rotation Plan
Description: Creates rotation plans from agent JSON recommendations (Agentforce compatible)
```

### **Input Parameter**
- **Name**: `varJsonData`
- **Type**: String
- **Description**: Complete rotation plan data as JSON string

### **Output Variables**
- `varOutputSuccess` (Boolean): Success status
- `varOutputRotationPlanId` (String): Created plan ID
- `varOutputRotationPlanName` (String): Plan name
- `varOutputNumberOfSeasons` (Integer): Number of seasons created
- `varOutputMessage` (String): Success/error message

## 📝 **JSON Format**

### **Required Fields**
```json
{
  "rotationPlanName": "Plan Name",
  "fieldName": "West 99 Field"
}
```

### **Complete Example**
```json
{
  "rotationPlanName": "West 99 Field 4-Year Rotation",
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
      "purpose": "Primary cash crop",
      "season": "Spring",
      "year": "Year 1",
      "zone": "In-Bed"
    }
  ]
}
```

## 🧪 **Testing Steps**

### **1. Deploy Components**
```bash
# Deploy Apex classes
sf project deploy start --metadata ApexClass:AgentforceSimpleRotationCreator,ApexClass:AgentforceSimpleRotationCreatorTest

# Deploy Flow
sf project deploy start --source-dir force-app/main/default/flows/DM_Simple_Agentforce_Rotation_Plan.flow-meta.xml

# Run tests
sf apex run test --class-names AgentforceSimpleRotationCreatorTest --result-format human --code-coverage
```

### **2. Create Agentforce Action**
- Setup → Agentforce → Actions → New Action
- Use "DM Simple Agentforce Rotation Plan" Flow
- Assign to your Crop Planning Advisor agent

### **3. Test with Agent**
```
User: "Create a rotation plan for West 99 Field"
Agent: [Provides recommendation]
User: "Yes, create this plan"
Agent: [Calls action with JSON data]
Result: Plan created successfully
```

## ⚠️ **Common Issues & Solutions**

### **Issue**: "I don't have the capability to create plan records"
**Solution**: Ensure you're using the simplified Flow (`DM Simple Agentforce Rotation Plan`), not the original complex one.

### **Issue**: Field not found error
**Solution**: Use exact field names like "West 99 Field" or "East 99 Field" that exist in your org.

### **Issue**: JSON parsing errors
**Solution**: Ensure proper JSON format with double quotes and valid date formats (YYYY-MM-DD).

### **Issue**: Permission errors
**Solution**: Verify user has CRUD access to Rotation_Plan__c and Season__c objects.

## 🎯 **Success Indicators**

✅ **Agent can call the action without errors**
✅ **Rotation Plan record is created in Salesforce**
✅ **Season records are created and linked**
✅ **Agent receives success confirmation with plan details**
✅ **Data normalization works (seasons, crop types, years)**

## 📞 **Support**

If the working solution fails:
1. Verify you're using the simplified components (not the original complex ones)
2. Check that field names exist in your org
3. Validate JSON format
4. Confirm user permissions
5. Review debug logs in Developer Console

---

**Remember**: Only the simplified solution works with Agentforce. The original complex solution will fail due to Agentforce collection limitations.
