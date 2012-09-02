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
* @date Salesforce Foundation 2012
* @description Main GovWatcher console controller
*/
public with sharing class FGW_Console_CTRL{
    
    public FGW_Application_Settings__c AppSettings;
    public Id ChatterUserId{get;set;}
    public Id FeedDisplayId{get; set;}
    public List<Legislation__c> followedLegislation;
    public List<Contact> followedLegislators;
    public String FeedName{get;set;}     
    public String adv_query{get;set;} 
    public String queryObject{get;set;}
    
    //search results
    public List<FGW_Search_Result__c> searchResults{get;set;}
    
    //the name of the non-default API to use for this query 
    public String APIOverrideName{get; set;}
    private Map<String, FGW_API_Settings__c> availableFedAPIs;
    private Map<String, FGW_API_Settings__c> availableStateAPIs;
    
    
    
    public FGW_Console_CTRL(){
        AppSettings = FGW_Constants.AppSettings;
        ChatterUserId = AppSettings.Chatter_User_Id__c; 
        FeedDisplayId = ChatterUserId;
        FeedName = [select Name from User where Id = :ChatterUserId].Name;
        Map<String, FGW_API_Settings__c> allAPIs = FGW_API_Settings__c.getAll();
        availableFedAPIs = new Map<String, FGW_API_Settings__c>();
        availableStateAPIs = new Map<String, FGW_API_Settings__c>();
        
        for (String s : allAPIs.keySet()){
        	FGW_API_Settings__c a = allAPIs.get(s);
        	if (a.API_Type__c == 'Federal')
        	   availableFedAPIs.put(a.Name, a);
        	else if (a.API_Type__c == 'State')
        	   availableStateAPIs.put(a.Name, a);
        }
        
        searchResults = [select Name from FGW_Search_Result__c order by LastModifiedDate desc];
        
    }
    
    public void viewAllFeeds(){
        FeedDisplayId = ChatterUserId;
        FeedName = [select Name from User where Id = :ChatterUserId].Name;
    }
    
    public void assignFeedName(){           
        String f;
        
        if (((String)FeedDisplayId).startsWith('003'))
            FeedName = [select Name from Contact where Id = :FeedDisplayId].Name;
        else
            FeedName = [select Name from Legislation__c where Id = :FeedDisplayId].Name;
    }
    
    public List<Legislation__c> getfollowedLegislation(){
        followedLegislation = new List<Legislation__c>();
        
        //get all of the legislation IDs that the chatter user follows
        EntitySubscription[] followingES = [select id, parentid, subscriberid, parent.name
                                    from EntitySubscription
                                    where subscriberid =:ChatterUserId];//Set to the User's Id

        List<Id> legIds = new List<Id> ();

        String legSObjectPrefix =  Legislation__c.sObjectType.getDescribe().getKeyPrefix();

        for(EntitySubscription es: followingES){
            if(('' + es.parentid).substring(0,3) == legSObjectPrefix){
                legIds.add(es.parentid);
            }
        }
                
        followedLegislation = [select Name, Status__c from Legislation__c where Id IN :legIds];
        return followedLegislation;
    }    
    
    public List<Contact> getfollowedLegislators(){
        followedLegislators = new List<Contact>();
        
        //get all of the legislation IDs that the chatter user follows
        EntitySubscription[] followingES = [select id, parentid, subscriberid, parent.name
                                    from EntitySubscription
                                    where subscriberid =:ChatterUserId];//Set to the User's Id

        List<Id> conIds = new List<Id> ();

        String conSObjectPrefix =  Contact.sObjectType.getDescribe().getKeyPrefix();

        for(EntitySubscription es: followingES){
            if(('' + es.parentid).substring(0,3) == conSObjectPrefix){
                conIds.add(es.parentid);
            }
        }
        followedLegislators = [select Name from Contact where Id IN :conIds];       
        return followedLegislators;
    }
    
    public PageReference runAdvSearch(){
        FGW_RequestFilterParameters rfp = new FGW_RequestFilterParameters();
        rfp.adv_query = adv_query;
        rfp.queryReturnType = FGW_Constants.queryReturntype.Basic;
        
        
        rfp.APIName = APIOverrideName != null ? APIOverrideName : null;
        searchResults = runSearches(new List<FGW_RequestFilterParameters>{rfp});
        
        
        return null;        
    }
    

    
    
    private List<FGW_Search_Result__c> runSearches(List<FGW_RequestFilterParameters> rfps){
        //get the default APIs for State & Federal
        FGW_IAPI default_FedAPI = FGW_APIFactory.getDefault_Federal_API_Instance();
        FGW_IAPI default_StateAPI = FGW_APIFactory.getDefault_State_API_Instance();        
        
        List<FGW_Search_Result__c> searchResults = new List<FGW_Search_Result__c>();
        
        for (FGW_RequestFilterParameters rfp : rfps){
            
            //hold the result, either Legislation__c or Contacts here
            List<SObject> searchObjs = new List<SObject>();
            
            //use the default federal API
            if (rfp.APIName == FGW_Constants.FederalAPI.Name){
                if (queryObject == 'Legislation')
                    searchObjs = default_FedAPI.getBills(rfps);        	
                else if (queryObject == 'Legislator')
                    searchObjs = default_FedAPI.getLegislators(rfps);        
            }
            //use the default state API     	   
            else if (rfp.APIName == FGW_Constants.StateAPI.Name){
            	if (queryObject == 'Legislation')
                    searchObjs = default_StateAPI.getBills(rfps);         
                else if (queryObject == 'Legislator')
                    searchObjs = default_StateAPI.getLegislators(rfps); 
            }
        
            //its a non-default API, so we need a new API object to accomodate
            else{            	
            	FGW_IAPI custom_API = FGW_APIFactory.getAPI_Instance(rfp.APIName);
            	
            	if (queryObject == 'Legislation')
                    searchObjs = custom_API.getBills(rfps);         
                else if (queryObject == 'Legislator')
                    searchObjs = custom_API.getLegislators(rfps); 
            }
        
            for (SObject obj : searchObjs){
            	FGW_Search_Result__c sr = FGW_Utilities.convertObjectToSearchResult(obj);
                sr.Saved_Search__c = rfp.SavedSearchId;          
            	searchResults.add(sr);
            }            
        
        }
        return searchResults;
    }
    
    
    
}