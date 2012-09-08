/*
    Copyright (c) 2012, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.com Foundation
* @date 2012
* @description Main record processing and creation factory 
*/
public with sharing class FGW_Main{
    
    //helper 
    private static List<sobject> runObjectQuery(Map<String, List<FGW_RequestFilterParameters>> rfpByObject, FGW_IAPI API){
    	List<sobject> returnList = new List<sobject>();
    	
    	for (String objectName : rfpByObject.keySet()){
            if (objectName == 'Legislation__c')
                returnList.addAll((List<sobject>)API.getBills(rfpByObject.get(objectName)));
    		else if (objectName == 'Contact')
                returnList.addAll((List<sobject>)API.getLegislators(rfpByObject.get(objectName)));    		  
    		else if (objectName == 'Amendment__c')
    	      	returnList.addAll((List<sobject>)API.getAmendments(rfpByObject.get(objectName)));
            else if (objectName == 'Roll_Vote__c')
            	returnList.addAll((List<sobject>)API.getRollVotes(rfpByObject.get(objectName)));
            else if (objectName == 'Legislator_Vote__c')
                returnList.addAll((List<sobject>)API.getVotes(rfpByObject.get(objectName)));
    	}
        return returnList;    	
    }
    
    
    
    //take a list of filter parameters and returns the contained sobjects from the API
    public static List<sobject> runSearch(List<FGW_RequestFilterParameters> rfpList){
         
        List<sobject> returnList = new List<sobject>();
        Map<String, Map<String, List<FGW_RequestFilterParameters>>> rfpByAPINameandObject = FGW_Utilities.sortRequestFilterParameters(rfpList); 
        
        for (String FilterAPIName : rfpByAPINameandObject.keySet()){
            if (FilterAPIName == FGW_Constants.FederalAPI.Name)
                returnList.addAll(runObjectQuery(rfpByAPINameandObject.get(FilterAPIName), FGW_APIFactory.getDefault_Federal_API_Instance()));
            else if (FilterAPIName == FGW_Constants.StateAPI.Name)
                returnList.addAll(runObjectQuery(rfpByAPINameandObject.get(FilterAPIName), FGW_APIFactory.getDefault_State_API_Instance()));
            else
                returnList.addAll(runObjectQuery(rfpByAPINameandObject.get(FilterAPIName), FGW_APIFactory.getAPI_Instance(FilterAPIName))); 
        }        
        return returnList;
    }
    
    public static Integer convertSearchResults(List<FGW_Search_Result__c> srList){
    	Integer converted_records_count = 0;
    	
    	//convert search results to RFPs to pass to the API class
        List<FGW_RequestFilterParameters> rfpList = FGW_Utilities.convertSearchResultsToParameters(srList); 
    	
    	List<sobject> sobjs = FGW_Main.runSearch(rfpList);
        
        List<id> newIds = new List<Id>();
        List<Contact> newCons = new List<Contact>();
        List<Legislation__c> newBills = new List<Legislation__c>();
                
        //save a query 
        Boolean hasCons = false;
        Boolean hasBills = false;        
                        
    	Database.Saveresult[] srs = Database.insert(sobjs);
    	for (Database.saveresult sr : srs){
    		if(sr.isSuccess()){        
                newIds.add(sr.getId());
                if (('' + sr.getId()).subString(0,3) == '003')
                    hasCons = true;
                else
                    hasBills = true;                                        
    		
                converted_records_count++;    		  
    		}    	
    	}    	
    	
    	List<Sobject> newobjs = new List<sobject>();
    	
    	//get new contacts
    	if (hasCons){
    	   newCons = [select id, Name from Contact where ID IN :newIds];
    	   newobjs.addAll((List<sobject>)newCons);
    	}    	       	
    	//get new bills
    	if (hasBills){
    	   newBills = [select id, Name from Legislation__c where ID IN :newIds];
    	   newobjs.addAll((List<sobject>)newBills);    	   
    	}    	   
    	
    	if (!newobjs.isEmpty())
    	   FGW_ChatterUtilities.chatterResultConversion(newobjs);
    	
    	return converted_records_count;
    }     
    
    
        	
	
	

}