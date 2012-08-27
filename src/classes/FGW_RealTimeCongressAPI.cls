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
* @author Wai Ho & Salesforce.com Foundation
* @date Exponent Partners 2011, Salesforce Foundation 2012
* @description Access to the Sunlight Foundation Real Time Congress API 
*/
global class FGW_RealTimeCongressAPI implements FGW_IAPI{
    
    private final FGW_API_Settings__c API_Config;
    private final String API_Key;
    private final String Endpoint;     
    private final Map<String, MAP<String, String>> RTC_Translation;
    
    private List<FGW_JSONObject_RTC> resultsList;    
    
    public FGW_RealTimeCongressAPI(){
    	API_Config = FGW_API_Settings__c.getInstance('Real Time Congress');
    	API_Key = API_Config.API_Key__c;
    	Endpoint = API_Config.API_Endpoint__c;    
    	RTC_Translation = getRTCMap();
    }    
    
    global List<Legislation__c> getBills(List<FGW_RequestFilterParameters> params){
    	resultsList = new List<FGW_JSONObject_RTC>();
        resultsList = runQueries('bills.json', params);
    	system.debug('resultlist size' + resultsList.size());
    	List<Legislation__c> returnList = new List<Legislation__c>();
    	
    	returnList = parseLegislationResults(resultsList);
    	system.debug('LEG RESULT....' + returnlist.size());
    	return returnList;
    }
    
    global List<Amendment__c> getAmendments(List<FGW_RequestFilterParameters> params){
    	
    	return new List<Amendment__c>();
    }
    global List<Legislator_Vote__c> getVotes(List<FGW_RequestFilterParameters> params){
    	
    	return new List<Legislator_Vote__c>();
    }

    global List<Contact> getLegislators(List<FGW_RequestFilterParameters> params){    	
    	return new List<Contact>();
    }    
    
    global List<Roll_Vote__c> getRollVotes(List<FGW_RequestFilterParameters> params){
    	return new List<Roll_Vote__c>();
    }
 
    global Amendment__c getAmendment(String amendmentId){
    	return new Amendment__c();
    }
 
    global Legislation__c getBill(String billId){
    	return new Legislation__c();
    }     
    
    global Contact getLegislator(String bioguide_id){
    	return new Contact();
    }
    
    private List<Legislation__c> parseLegislationResults(List<FGW_JSONObject_RTC> resultList){
    	
    	List<Legislation__c> returnList = new List<Legislation__c>();    	
    	
    	for (FGW_JSONObject_RTC JSObj : resultList){
            for (FGW_JSONObject_RTC.Bill b : JSObj.bills){
                Legislation__c leg = new Legislation__c();	
            	leg.Name = b.bill_id;
                returnList.add(leg);
            
            }   
    	}
    	
    	
    	return returnList;
    }
    
    
    
    
    
    
    
    //handles the callout and return the JSON Object for further parsing
    private List<FGW_JSONObject_RTC> runQueries(String collection, List<FGW_RequestFilterParameters> params){
    	
    	List<FGW_JSONObject_RTC> returnList = new List<FGW_JSONObject_RTC>();
    	
    	//for each collection of filters, run the query and return the parsed JSON object
    	for (FGW_RequestFilterParameters rfp : params){
           
           HttpRequest req = buildQueryString(collection, rfp);
           HttpResponse res = doCallout(req);
           
           
           
           FGW_JSONObject_RTC deserializedObj = (FGW_JSONObject_RTC)JSON.deserialize(res.getBody(), FGW_JSONObject_RTC.class);
           
           returnList.add(deserializedObj);           
           system.debug('SIZE: ' + returnList.size());
        }        
        
        
        
        
        return returnList;        
    }
    
    
    
    //construct the request, one request per filter param object
    private HttpRequest buildQueryString(String ResourceName, FGW_RequestFilterParameters params){
        
        String parameter_string = '';
        
        //user provided a query through the advanced interface - just assign the value to the URL
        if (params.adv_query != null){
        	parameter_string = params.adv_query;        	
        }
        
        else{           
            Integer i = 0;
            //loop through the objects params and construct our query string
            for (i=0; i < params.objectNames.size(); i++){
                parameter_string += constructParameter(params.objectNames[i], params.fieldNames[i], params.boolOperators[i], params.comparisonValues[i]);
                parameter_string += '&';
            }
            //trim off the last s, for savings. 
            parameter_string = parameter_string.substring(0, parameter_string.length());                            	   
        }
                
        //take only what you need to survive...
        if (ResourceName == 'bills.json' && params.queryType == FGW_Constants.querytype.Headers){
            parameter_string += '&sections=basic';            
        }

        //encode        
        parameter_string = EncodingUtil.urlEncode(parameter_string, 'UTF-8');
        
        // Compose the URL
        String url = Endpoint + '/' + ResourceName + '?' + parameter_string;
        
       // Instantiate a new HTTP request, GET method, set endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);        
        req.setMethod('GET');
        req.setHeader('X-APIKEY', API_Key);
        return req; 
    }
    
    private HttpResponse doCallout(HttpRequest req){    	
    	Http h = new Http();
    	HttpResponse res = h.send(req);
        return res;
    }
    
    
    private String constructParameter(String objName, String fieldName, FGW_Constants.operators operator, String value){
    	String return_parameter = '';
    	
    	Map<String, String> translationMap = RTC_Translation.get(objName);
    	
    	//special handling for things like bioguide id of votes
    	//if we're only doing votes, need to restrict the returned values as well
    	
    	return return_parameter;
    }    

    //construct a map of <ObjectName, Map<FieldName, API_Field_Name>> for use in building query params
    private Map<String, Map<String, String>> getRTCMap(){
        
        Map<String, Map<String, String>> RTCMap = new Map<String, Map<String, String>>();
        
        //need votes, rollvote, legislators, bills & amendments
               
        //votes - billid, amendmentid, bioguideid
        Map<String, String> VotesMap = new Map<String, String>();
        VotesMap.put('Legislation__r.Name', 'bill_id');
        VotesMap.put('Amendment__r.Name', 'amendment_id');
        VotesMap.put('Legislator__r.Bioguide_ID__c', 'XXXXXX.voter.bioguide_id__in');
        VotesMap.put('Roll_Vote__r.Vote_Type__c', 'vote_type');
        //VotesMap.put('Legislation__c.Keywords__c', '')        
        RTCMap.put('Legislator_Vote__c', VotesMap);
        
        //rollvote - amendmentid, billid, type
        Map<String, String> RollVoteMap = new Map<String, String>();
        RollVoteMap.put('Legislation__c.Name', 'bill_id');
        RollVoteMap.put('Amendment__c.Name', 'amendment_id');
        RollVoteMap.put('Roll_Vote__c.Vote_Type__c', 'vote_type');
        RTCMap.put('Roll_Vote__c', RollVoteMap);
        
        //legislators - state, district, chamber
        Map<String, String> LegislatorMap = new Map<String, String>();
        LegislatorMap.put('Chamber__c', 'chamber');
        LegislatorMap.put('Bioguide_Id__c', 'bioguide_id');
        LegislatorMap.put('Congressional_State__c', ''); 
        LegislatorMap.put('Congressional_District__c','');
        LegislatorMap.put('Party_Affiliation__c', '');                
        RTCMap.put('Contact', LegislatorMap);
        
        //amendments - billid
        Map<String, String> AmendmentMap = new Map<String, String>();
        AmendmentMap.put('Legislation__r.Name', 'bill_id');
        AmendmentMap.put('Name', 'amendment_id');
        RTCMap.put('Amendment__c', AmendmentMap);        
                
        //bills - ????????????????????????????
               
        
        return RTCMap;
    }



}