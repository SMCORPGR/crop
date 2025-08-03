({
   init : function (component) {
      // Find the component whose aura:id is "flowData"
      var flow = component.find("flowData");
      // In that component, start your flow. Reference the flow's API Name.
      flow.startFlow("digitalm__DM_New_Sale");
   },
                                
    
    handleStatusChange : function (component, event) {
      if(event.getParam("status") === "FINISHED") 
      {
         // Get the output variables and iterate over them
         var outputVariables = event.getParam("outputVariables");
         console.log(outputVariables); 
         var outputVar;
         for(var i = 0; i < outputVariables.length; i++) 
         {
            outputVar = outputVariables[i];
            console.log(outputVar);
            // Pass the values to the component's attributes
            if(outputVar.name === "recordId") 
            console.log(outputVar.name);    
            {
               var urlEvent = $A.get("e.force:navigateToSObject");
               urlEvent.setParams({"recordId": outputVar.value});
               urlEvent.fire();
               $A.get('e.force:refreshView').fire();
            } 
         }
        }
   },
})