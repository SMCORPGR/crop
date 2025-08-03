# Agentforce Crop Rotation Plan - Deployment Checklist

## 📋 **Pre-Deployment Requirements**

### **Salesforce Org Setup**
- [ ] Agentforce enabled in org
- [ ] Digital Farming package installed
- [ ] Field records exist (West 99 Field, East 99 Field, etc.)
- [ ] User has System Administrator or equivalent permissions

### **Object Permissions**
- [ ] CRUD access to `digitalm__DM_Rotation_Plan__c`
- [ ] CRUD access to `digitalm__DM_Season__c`
- [ ] Read access to `digitalm__DM_Field__c`
- [ ] Read access to `digitalm__DM_Parcel1__c`
- [ ] Read access to `digitalm__DM_Farm__c`

## 🚀 **Deployment Steps**

### **Step 1: Deploy Apex Classes**
```bash
# Deploy the main classes
sf project deploy start --metadata ApexClass:AgentforceRotationPlanCreator,ApexClass:AgentforceRotationPlanCreatorTest
```

**Verify**:
- [ ] AgentforceRotationPlanCreator deployed successfully
- [ ] AgentforceRotationPlanCreatorTest deployed successfully
- [ ] No compilation errors

### **Step 2: Run Tests**
```bash
# Run tests to verify functionality
sf apex run test --class-names AgentforceRotationPlanCreatorTest --result-format human --code-coverage
```

**Verify**:
- [ ] All 6 tests pass (100% pass rate)
- [ ] Code coverage ≥ 75% (should be 84%)
- [ ] No test failures or errors

### **Step 3: Deploy Flow**
```bash
# Deploy the Flow
sf project deploy start --source-dir force-app/main/default/flows/DM_Agentforce_Create_Rotation_Plan.flow-meta.xml
```

**Verify**:
- [ ] Flow deployed successfully
- [ ] Flow is Active status
- [ ] No validation errors

### **Step 4: Test Flow Manually**
1. **Navigate to Flow**
   - Setup → Process Automation → Flows
   - Open "DM Agentforce Create Rotation Plan"
   - Click "Run"

2. **Test Input**
   ```json
   {
     "rotationPlanName": "Deployment Test Plan",
     "fieldName": "West 99 Field",
     "startDate": "2025-01-01",
     "endDate": "2025-12-31",
     "status": "Draft",
     "seasons": []
   }
   ```

**Verify**:
- [ ] Flow executes without errors
- [ ] Success output variables populated
- [ ] Rotation Plan record created

## 🤖 **Agentforce Configuration**

### **Step 5: Create Agentforce Action**

1. **Navigate to Actions**
   - Setup → Agentforce → Actions
   - Click "New Action"

2. **Configure Action**
   ```
   Name: Create Crop Rotation Plan
   Type: Flow
   Flow: DM Agentforce Create Rotation Plan
   Description: Creates rotation plans from agent recommendations
   ```

3. **Action Instructions**
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

**Verify**:
- [ ] Action created successfully
- [ ] Action is Active
- [ ] Instructions are clear and complete

### **Step 6: Configure Agent**

1. **Open Agent Builder**
   - Setup → Agentforce → Agent Builder
   - Open "Crop Planning Advisor" agent

2. **Add Action to Agent**
   - Go to Actions tab
   - Add "Create Crop Rotation Plan" action
   - Save agent configuration

3. **Update Agent Instructions**
   Add to agent instructions:
   ```
   When users accept a rotation plan recommendation, use the "Create Crop Rotation Plan" action.

   Format your recommendations as JSON with proper field names and date formats.
   Always use exact field names from Salesforce (e.g., "West 99 Field", "East 99 Field").
   Use YYYY-MM-DD format for dates and proper picklist values for crop types and seasons.
   ```

**Verify**:
- [ ] Action assigned to agent
- [ ] Agent instructions updated
- [ ] Agent configuration saved

## 🧪 **Testing & Validation**

### **Step 7: End-to-End Testing**

1. **Test Agent Interaction**
   - Open Agent window
   - Request rotation plan creation
   - Verify agent calls action correctly

2. **Test Sample Scenarios**
   - [ ] Basic rotation plan creation
   - [ ] JSON with multiple seasons
   - [ ] Error handling (invalid field name)
   - [ ] Data normalization (case conversion)

3. **Verify Data Creation**
   - [ ] Rotation Plan records created correctly
   - [ ] Season records linked properly
   - [ ] Data normalized as expected

### **Step 8: Performance Testing**

**Test Metrics**:
- [ ] Response time < 3 seconds
- [ ] Success rate > 95% for valid inputs
- [ ] Proper error messages for invalid inputs
- [ ] No governor limit issues

### **Step 9: User Acceptance Testing**

**Test with End Users**:
- [ ] Agent responds appropriately to requests
- [ ] Created plans meet business requirements
- [ ] Error messages are user-friendly
- [ ] Overall user experience is satisfactory

## 🔧 **Post-Deployment Configuration**

### **Step 10: Security Review**

**Permissions Check**:
- [ ] Users have appropriate object permissions
- [ ] Field-level security configured correctly
- [ ] Sharing rules allow access to created records
- [ ] No security vulnerabilities identified

### **Step 11: Monitoring Setup**

**Configure Monitoring**:
- [ ] Enable debug logs for troubleshooting
- [ ] Set up Agentforce analytics monitoring
- [ ] Configure error notifications if needed
- [ ] Document support procedures

### **Step 12: Documentation**

**Ensure Documentation is Complete**:
- [ ] Technical documentation updated
- [ ] User guides created/updated
- [ ] Training materials prepared
- [ ] Support procedures documented

## ✅ **Go-Live Checklist**

### **Final Verification**
- [ ] All deployment steps completed successfully
- [ ] All tests passing
- [ ] Agent functioning correctly
- [ ] End users trained
- [ ] Support team ready
- [ ] Rollback plan prepared

### **Communication**
- [ ] Stakeholders notified of deployment
- [ ] Users informed of new functionality
- [ ] Support team briefed
- [ ] Documentation distributed

### **Monitoring**
- [ ] Initial monitoring in place
- [ ] Error tracking configured
- [ ] Performance baselines established
- [ ] Support procedures activated

## 🚨 **Rollback Plan**

If issues arise:

1. **Immediate Actions**
   - [ ] Deactivate Agentforce action
   - [ ] Disable agent if necessary
   - [ ] Document issues encountered

2. **Investigation**
   - [ ] Review debug logs
   - [ ] Check error messages
   - [ ] Identify root cause

3. **Resolution**
   - [ ] Fix identified issues
   - [ ] Re-test functionality
   - [ ] Re-deploy if necessary

## 📞 **Support Contacts**

**Technical Issues**:
- Salesforce Administrator
- Development Team
- Agentforce Support

**Business Issues**:
- Business Analyst
- End User Representatives
- Project Manager

---

**Deployment Date**: ___________
**Deployed By**: ___________
**Verified By**: ___________
**Approved By**: ___________
