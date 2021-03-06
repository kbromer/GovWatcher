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
    	   newBills = [select id, Name, Bill_Id__c from Legislation__c where ID IN :newIds];
    	   newobjs.addAll((List<sobject>)newBills);    	   
    	}    
    	
    	
    	List<String> billIds = new List<String>();
    	
    	//if we're configured to retrieve all amendments, get the list on creation of the legislation object
    	if (hasBills && FGW_Constants.AppSettings.Amendment_Tracking__c == 'All Amendments'){
    		for (Legislation__c l : newBills){
    			billIds.add(l.Bill_Id__c);    			
    		}
    		if (!billIds.isEmpty()){
    			FGW_Main.getBillAmendments(billIds);
    		}    		
    	}
    	
    	//if we're configured to retrieve all roll votes, get the list on creation of the legislation object
    	if (hasBills && FGW_Constants.AppSettings.Roll_Vote_Tracking__c == 'All Roll Votes'){
            if (billIds.isEmpty()){                            
                for (Legislation__c l : newBills){
                    billIds.add(l.Bill_Id__c);              
                }
            }                
            if (!billIds.isEmpty()){
                FGW_Main.getBillRollVotes(billIds);
            }           
        }    		   
    	
    	if (!newobjs.isEmpty())
    	   FGW_ChatterUtilities.chatterResultConversion(newobjs);
    	
    	return converted_records_count;
    }     
    
    //take a list of full bill ids and add the associated rollvotes
    @future(callout=true)
    private static void getBillRollVotes(List<String> billIds){
        //construct a list of RFPs based on the provided billIds
        FGW_RequestFilterParameters rfp = new FGW_RequestFilterParameters();
        rfp.APIName = FGW_Constants.AppSettings.Federal_API_Name__c;
        rfp.objectName = 'Roll_Vote__c';
        rfp.queryReturnType = FGW_Constants.queryReturntype.Full;        
         
        for (String s : billIds){
            rfp.fieldNames.add('Bill_ID__c');
            rfp.boolOperators.add(FGW_Constants.operators.Equals);
            rfp.comparisonValues.add(s);
        }                               

        FGW_IAPI API = FGW_APIFactory.getDefault_Federal_API_Instance();
        List<Roll_Vote__c> RollVoteList = new List<Roll_Vote__c>();
        Map<String, List<FGW_RequestFilterParameters>> rfpMap = new Map<String, List<FGW_RequestFilterParameters>>();
        rfpMap.put('Roll_Vote__c', new List<FGW_RequestFilterParameters>{rfp});
        RollVoteList = (List<Roll_Vote__c>)FGW_Main.runObjectQuery(rfpMap, API);
        
        //map for chatter coms
        Map<String, Object> ChatterMap = new Map<String, Object>();
        
        //connect rollvote to their amendments or bills...
        for (Roll_Vote__c rv : RollVoteList){
        	if (rv.Amendment_ID__c != null && rv.Amendment_ID__c != ''){
                Amendment__c a = new Amendment__c();
                a.Amendment_ID__c = rv.Amendment_ID__c;
                rv.Amendment__r = a;
        	}
        	//link it both ways if possible 
        	if (rv.Bill_ID__c != null && rv.Bill_ID__c != ''){
        		Legislation__c l = new Legislation__c();
        		l.Bill_ID__c = rv.Bill_ID__c;
        		rv.Legislation__r = l;
        	}
        	if (rv.Bill_ID__c != null){
                if (ChatterMap.containsKey(rv.Bill_ID__c)){
                    if (ChatterMap.get(rv.Bill_ID__c) instanceof Integer){                    
                        Integer i = (Integer)ChatterMap.get(rv.Bill_ID__c);                  
                        i++;
                        ChatterMap.put(rv.Bill_ID__c, i);
                    }
                    else{                   
                        Integer i = 2;
                        ChatterMap.put(rv.Bill_ID__c, i);
                    }                               
                }        	                
                else{               
                    ChatterMap.put(rv.Bill_ID__c, rv.Roll_ID__c);
                }
        	}                            
        }                
        
        database.insert(RollVoteList, false);        
        FGW_ChatterUtilities.chatterRollVoteAddition(ChatterMap);      
    }
    
    
    //take a list of full bill ids and add the associated amendments
    @future(callout=true)
    private static void getBillAmendments(List<String> billIds){
    
        //construct a list of RFPs based on the provided billIds
        FGW_RequestFilterParameters rfp = new FGW_RequestFilterParameters();
        rfp.APIName = FGW_Constants.AppSettings.Federal_API_Name__c;
        rfp.objectName = 'Amendment__c';
        rfp.queryReturnType = FGW_Constants.queryReturntype.Full;        
         
        for (String s : billIds){
            rfp.fieldNames.add('Bill_ID__c');
            rfp.boolOperators.add(FGW_Constants.operators.Equals);
            rfp.comparisonValues.add(s);
        }                            	

        FGW_IAPI API = FGW_APIFactory.getDefault_Federal_API_Instance();
        List<Amendment__c> AmendmentList = new List<Amendment__c>();
        Map<String, List<FGW_RequestFilterParameters>> rfpMap = new Map<String, List<FGW_RequestFilterParameters>>();
        rfpMap.put('Amendment__c', new List<FGW_RequestFilterParameters>{rfp});
        AmendmentList = (List<Amendment__c>)FGW_Main.runObjectQuery(rfpMap, API);
        
        Map<String, Object> ChatterMap = new Map<String, Object>();
        
        //connect the amendments to their bills
        for (Amendment__c a : AmendmentList){
        	Legislation__c l = new Legislation__c();
        	l.Bill_ID__c = a.Bill_ID__c;
        	a.Legislation__r = l;
        	if (ChatterMap.containsKey(a.Bill_ID__c)){
                if (ChatterMap.get(a.Bill_ID__c) instanceof Integer){                    
                	Integer i = (Integer)ChatterMap.get(a.Bill_ID__c);                	
                	i++;
                    ChatterMap.put(a.Bill_ID__c, i);
                }
                else{                	
                	Integer i = 2;
                	ChatterMap.put(a.Bill_ID__c, i);
                }                        		
        	}
        	else{        		
        		ChatterMap.put(a.Bill_ID__c, a.Amendment_ID__c);
        	}        	
        }
    	
    	Database.insert(AmendmentList, false);
    	FGW_ChatterUtilities.chatterAmendmentAddition(ChatterMap);    	
    } 
    
    
    
        	
	
	

}