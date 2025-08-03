# Agentforce Agent Prompt Examples for Crop Rotation Plan Creation

## 🎯 **Agent Configuration**

### **Agent Instructions to Add**

Add this to your Crop Planning Advisor agent instructions:

```
ROTATION PLAN CREATION CAPABILITY:

When users request to create or implement a rotation plan, use the "Create Crop Rotation Plan" action.

REQUIRED JSON FORMAT:
{
  "rotationPlanName": "descriptive name",
  "fieldName": "exact field name from Salesforce",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD",
  "status": "Draft",
  "seasons": [
    {
      "seasonName": "Season Year X",
      "startDate": "YYYY-MM-DD",
      "endDate": "YYYY-MM-DD",
      "crop": "crop name",
      "cropType": "Cash Crop|Cover Crop|Cover Crop Incorporation|Fallow",
      "purpose": "description",
      "season": "Spring|Summer|Fall|Winter",
      "year": "Year 1|Year 2|Year 3|Year 4|Year 5",
      "zone": "In-Bed|Inter-row|Perimeter|Pollinator|Under Canopy/Vine"
    }
  ]
}

FIELD NAMES: Use exact names like "West 99 Field", "East 99 Field"
DATE FORMAT: Always use YYYY-MM-DD
CROP TYPES: Use exact picklist values
YEARS: Use "Year 1", "Year 2", etc. format

TRIGGER PHRASES:
- "Create this rotation plan"
- "Implement this plan"
- "Set up this rotation"
- "Save this plan to Salesforce"
- "Yes, create the plan"
```

## 💬 **Example Conversations**

### **Scenario 1: Basic 4-Year Rotation Plan**

**User**: "I need a 4-year rotation plan for West 99 Field starting in Spring 2025"

**Agent Response**: 
```
I'll create a comprehensive 4-year rotation plan for West 99 Field. Here's my recommendation:

**Year 1 (2025)**:
- Spring: Tomatoes (Cash Crop) - Primary revenue crop
- Summer: Crimson Clover (Cover Crop) - Nitrogen fixation
- Fall: Winter Rye (Cover Crop) - Soil protection
- Winter: Fallow - Field rest

**Year 2 (2026)**:
- Spring: Peppers (Cash Crop) - Different family rotation
- Summer: Buckwheat (Cover Crop) - Quick soil improvement
- Fall: Crimson Clover (Cover Crop) - Nitrogen addition
- Winter: Fallow - Field preparation

**Year 3 (2027)**:
- Spring: Lettuce (Cash Crop) - Cool season crop
- Summer: Sunflower (Cash Crop) - Deep root benefits
- Fall: Winter Rye (Cover Crop) - Organic matter
- Winter: Fallow - Soil rest

**Year 4 (2028)**:
- Spring: Beans (Cash Crop) - Nitrogen fixing legume
- Summer: Sorghum-Sudan (Cover Crop) - Biomass production
- Fall: Crimson Clover (Cover Crop) - Soil preparation
- Winter: Fallow - Cycle completion

This rotation provides crop diversity, soil health benefits, and sustainable revenue. Would you like me to create this rotation plan in Salesforce?
```

**User**: "Yes, create this rotation plan"

**Agent Action**: Calls "Create Crop Rotation Plan" with JSON:
```json
{
  "rotationPlanName": "West 99 Field 4-Year Sustainable Rotation Plan",
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
      "purpose": "Primary revenue crop with high market value",
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
      "purpose": "Soil protection and organic matter addition",
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
      "purpose": "Field rest and preparation for next season",
      "season": "Winter",
      "year": "Year 1",
      "zone": "In-Bed"
    }
  ]
}
```

### **Scenario 2: Cover Crop Focus Plan**

**User**: "I want to focus on soil health for East 99 Field with lots of cover crops"

**Agent Response**:
```
Excellent choice for soil health improvement! Here's a soil-focused rotation plan for East 99 Field:

**Soil Health Rotation Plan**:
- Spring Year 1: Lettuce (Cash Crop) - Light feeder to start
- Summer Year 1: Crimson Clover (Cover Crop) - Nitrogen fixation
- Fall Year 1: Winter Rye (Cover Crop) - Soil structure
- Winter Year 1: Hairy Vetch (Cover Crop) - Continued nitrogen

This plan maximizes cover crop benefits while maintaining some revenue. The cover crops will improve soil structure, add organic matter, and fix nitrogen naturally.

Should I create this soil health rotation plan in Salesforce?
```

**User**: "Yes, implement this plan"

**Agent Action**: Creates plan with appropriate JSON structure.

### **Scenario 3: Error Handling Example**

**User**: "Create a rotation plan for My Special Field"

**Agent Response**:
```
I'd be happy to create a rotation plan! However, I need to use the exact field name as it appears in Salesforce. 

Could you please confirm the exact field name? The available fields I can work with include:
- West 99 Field
- East 99 Field

Which field would you like me to create the rotation plan for?
```

**User**: "Use West 99 Field"

**Agent**: Proceeds with plan creation using correct field name.

## 🔧 **Advanced Prompt Patterns**

### **Pattern 1: Conditional Plan Creation**

```
Agent: "Based on your soil test results showing low nitrogen, I recommend this nitrogen-building rotation plan. Would you like me to create this plan in Salesforce?"

User: "Yes"

Agent: [Calls action with nitrogen-focused crop selection]
```

### **Pattern 2: Multi-Field Planning**

```
Agent: "I can create rotation plans for multiple fields. Let's start with West 99 Field. After I create this plan, I can help you with East 99 Field as well."

User: "Sounds good"

Agent: [Creates first plan, then offers to create second plan]
```

### **Pattern 3: Plan Modification**

```
User: "Can you modify the plan to include more cash crops?"

Agent: "I'll create a revised plan with additional cash crop seasons. Here's the updated rotation..."

User: "Perfect, create this version"

Agent: [Calls action with modified plan]
```

## 🎨 **Response Templates**

### **Success Response Template**
```
✅ **Rotation Plan Created Successfully!**

I've created your rotation plan in Salesforce:
- **Plan Name**: [Plan Name]
- **Field**: [Field Name]
- **Duration**: [Start Date] to [End Date]
- **Seasons**: [Number] seasons planned
- **Plan ID**: [Rotation Plan ID]

You can view and manage this plan in the Rotation Plans section of Salesforce. The plan includes detailed season information with crops, purposes, and timing.

Is there anything else you'd like me to help you with for your crop planning?
```

### **Error Response Template**
```
❌ **Unable to Create Rotation Plan**

I encountered an issue while creating your rotation plan:
[Error Message]

Let me help you resolve this. Please check:
- Field name is spelled exactly as it appears in Salesforce
- All required information is provided
- You have permission to create rotation plans

Would you like to try again with corrected information?
```

## 🧪 **Testing Prompts**

### **Quick Test Prompts**

1. **Basic Test**: "Create a simple rotation plan for West 99 Field"
2. **Complex Test**: "I need a 4-year rotation with tomatoes, peppers, and cover crops for West 99 Field"
3. **Error Test**: "Create a plan for Invalid Field Name"
4. **Modification Test**: "Create a plan focused on soil health and nitrogen fixation"

### **Edge Case Tests**

1. **Date Handling**: "Create a plan starting next month"
2. **Crop Variety**: "Include both cash crops and cover crops"
3. **Season Timing**: "Plan for year-round coverage"
4. **Purpose Clarity**: "Focus on pest management and soil health"

## 📊 **Success Metrics**

Track these metrics for agent performance:

- **Action Success Rate**: % of successful plan creations
- **User Satisfaction**: Feedback on created plans
- **Error Resolution**: How well agent handles errors
- **Plan Quality**: Appropriateness of recommendations

## 🔍 **Monitoring Queries**

Use these to monitor agent performance:

1. **Action Usage**: How often is the action called?
2. **Success Rate**: What percentage succeed?
3. **Common Errors**: What errors occur most frequently?
4. **User Patterns**: What types of plans are requested most?

---

**Note**: Always ensure your agent instructions include the exact JSON format and field names specific to your Salesforce org configuration.
