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
* @description Utility methods used during GovWatcher processing 
*/
public with sharing class FGW_Utilities{

    /** Method converts Legislation & Contacts returned by the API into 
        search result objects **/
    public static FGW_Search_Result__c convertObjectToSearchResult(SObject obj){
    	FGW_Search_Result__c result;
    	
    	try{    	
    	    if (obj instanceof Contact){    	    	
                Contact c = (Contact)obj;
                result = new FGW_Search_Result__c();                
                result.Name = c.Bioguide_ID__c;    	
                result.Full_Name__c = c.Title + ' ' + c.FirstName + ' ' + c.LastName;
                result.isContact__c = true;
            }
            else if (obj instanceof Legislation__c){
                Legislation__c l = (Legislation__c)obj;
                result = new FGW_Search_Result__c(); 
                if (l.Name.length() > 80)
                    result.Name = (l.Name).subString(0, 79);
                else
                    result.Name = l.Name;
                result.Full_Name__c = l.Bill_Title__c;                            
            }
            else{        
                throw new FGW_Exception.SearchConversionException();
            }
    	}catch(Exception e){
            FGW_Exception.generateError(e, 'Error converting search results');
        }            	
    	return result;
    }
    
    /** Generate the most concise RFPs possible for a given list of search results to be converted **/
    public static List<FGW_RequestFilterParameters> convertSearchResultsToParameters(List<FGW_Search_Result__c> srList){
        
        List<FGW_RequestFilterParameters> rfpReturnList = new List<FGW_RequestFilterParameters>();    	
    	
    	//because we're converting search results, we know we'll only have two RFPs max of bioguide or billIds per API
    	Map<String, List<FGW_RequestFilterParameters>> rfpByAPI = new Map<String, List<FGW_RequestFilterParameters>>();

    	for (FGW_Search_Result__c sr : srList){
    		
    		//get the obj type for this search result
    		String objName = sr.isContact__c ? 'Contact' : 'Legislation__c';
    		
            if (rfpByAPI.containsKey(sr.API_Name__c)){
                //we already have an RFP list for this API type
                List<FGW_RequestFilterParameters> lrfp = rfpByAPI.get(sr.API_Name__c);
                
                //to hold either a new or the existing RFP
                FGW_RequestFilterParameters rfp = new FGW_RequestFilterParameters();
                                
                //do we have a filter parameter for this object already?
                boolean haveRFP = false;
                for (FGW_RequestFilterParameters r : lrfp){
                	if (objName == r.objectName){
                        rfp = r;
                        haveRFP = true;
                	}                		
                }
                
                //if we have one already, we just need to append this SRs Name to the comparisonvalue string for this RFP
                //should only be one since we're only searching on the IDs of the relevant object, the params
                //can be deconstructed in the API class
                if (haveRFP){
                	String cValues = rfp.comparisonValues[0];
                	cValues += '|' + sr.Name;
                	rfp.comparisonValues[0] = cValues;
                }
                //we need to create a new RFP for this object for this API name
                else{                	
                	rfp.objectName = objName;
                    rfp.fieldNames = new List<String>{sr.isContact__c ? 'Bioguide_ID__c' : 'Bill_Id__c'};
                    rfp.boolOperators = new List<FGW_Constants.operators>{FGW_Constants.operators.ValueIn};
                    rfp.comparisonValues = new List<String>{sr.Name};               
                    rfp.queryReturnType = FGW_Constants.queryReturntype.Full;
                    rfp.APIName = sr.API_Name__c;
                    rfp.SavedSearchId = sr.Saved_Search__c;
                    lrfp.add(rfp);
                    rfpByAPI.put(sr.API_Name__c, lrfp);
                }
            }
            
            //new API usage, need a new list and key                	   	
    		else{
    			FGW_RequestFilterParameters rfp = new FGW_RequestFilterParameters();
    			rfp.objectName = objName;
    			rfp.fieldNames = new List<String>{sr.isContact__c ? 'Bioguide_ID__c' : 'Bill_Id__c'};
    			rfp.boolOperators = new List<FGW_Constants.operators>{FGW_Constants.operators.ValueIn};
    			rfp.comparisonValues = new List<String>{sr.Name};    			
    			rfp.queryReturnType = FGW_Constants.queryReturntype.Full;
    			rfp.APIName = sr.API_Name__c;
    			rfp.SavedSearchId = sr.Saved_Search__c;
    			rfpByAPI.put(sr.API_Name__c, new List<FGW_RequestFilterParameters>{rfp});
    		}
    	}    	
    	
    	for (String s : rfpByAPI.keySet()){
    		List<FGW_REquestFilterParameters> rl = rfpByAPI.get(s);
    		for (FGW_RequestFilterParameters r : rl)
                rfpReturnList.add(r);    		  
    	}
    	return rfpReturnList;
    }
    
    
    
    
    public static testMethod void testconvertSearchResultsToParameters(){
        
        List<FGW_Search_Result__c> srList = new List<FGW_Search_Result__c>();
        
        FGW_Search_Result__c sr = new FGW_Search_Result__c(
            Name = 'hr1234-123',
            isContact__c = false,
            API_Name__c = 'Real Time Congress',
            Saved_Search__c = '001000000000000'
        );
        srList.add(sr);
        FGW_Search_Result__c sr2 = new FGW_Search_Result__c(
            Name = 'hr1234-321',
            isContact__c = false,
            API_Name__c = 'Real Time Congress',
            Saved_Search__c = '001000000000000'
        );
        srList.add(sr2);
        FGW_Search_Result__c sr3 = new FGW_Search_Result__c(
            Name = 'hr1234-001',
            isContact__c = false,
            API_Name__c = 'Govtrack',
            Saved_Search__c = '001000000000000'
        );    	
    	srList.add(sr3);    	
    	FGW_Search_Result__c sr4 = new FGW_Search_Result__c(
            Name = 'R000146',
            isContact__c = true,
            API_Name__c = 'Govtrack',
            Saved_Search__c = '001000000000000'
        );      
        srList.add(sr4);
    	
    	List<FGW_RequestFilterParameters> rfpList = FGW_Utilities.convertSearchResultsToParameters(srList);
    	system.assertEquals(3, rfpList.size());
    }
    
    
    
    
}