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
* @description Access to the Sunlight Foundation Real Time Congress & Congress APIs 
*/
global class FGW_RealTimeCongressAPI implements FGW_IAPI{
    
    private final FGW_API_Settings__c API_Config;
    private final String API_Key;
    private final Map<String, MAP<String, String>> RTC_Translation;
    //non-final to make endpoint switching easier if needed
    private String Endpoint;
    private Integer StatusCode;
    
    //keep the list around in case we need it...    
    private List<FGW_JSONObject_RTC> resultsList;    
    
    public FGW_RealTimeCongressAPI(){
    	API_Config = FGW_API_Settings__c.getInstance('Real Time Congress');
    	API_Key = API_Config.API_Key__c;
    	Endpoint = API_Config.API_Endpoint__c;
    	statusCode = -1;    
    	RTC_Translation = getRTCMap();    	
    }        
    
    global Integer getStatusCode(){return StatusCode;}
    
    global List<Legislation__c> getBills(List<FGW_RequestFilterParameters> params){
    	
    	resultsList = new List<FGW_JSONObject_RTC>();
        List<Legislation__c> returnList = new List<Legislation__c>();
        
        //error handling done internal to this execution path
        resultsList = runQueries('bills.json', params);
    	
    	try{
    	   returnList = parseLegislationResults(resultsList);
    	}catch(Exception e){
    		FGW_Exception.generateError(e, 'Error parsing callout results');
    	}
    	
    	return returnList;
    }
    
    global List<Amendment__c> getAmendments(List<FGW_RequestFilterParameters> params){
        resultsList = new List<FGW_JSONObject_RTC>();        
        List<Amendment__c> returnList = new List<Amendment__c>();
        
        //error handling done internal to this execution path
        resultsList = runQueries('amendments.json', params);
        
        try{
           returnList = parseAmendmentResults(resultsList);
        }catch(Exception e){
            FGW_Exception.generateError(e, 'Error parsing callout results');
        }
        
        return returnList;    	
    }
    global List<Legislator_Vote__c> getVotes(List<FGW_RequestFilterParameters> params){
        resultsList = new List<FGW_JSONObject_RTC>();        
        List<Legislator_Vote__c> returnList = new List<Legislator_Vote__c>();
        
        //error handling done internal to this execution path
        resultsList = runQueries('votes.json', params);
        
        try{
           returnList = parseLegislatorVotesResults(resultsList);
        }catch(Exception e){
            FGW_Exception.generateError(e, 'Error parsing callout results');
        }
        
        return returnList;
    }

    global List<Contact> getLegislators(List<FGW_RequestFilterParameters> params){
        resultsList = new List<FGW_JSONObject_RTC>();        
        List<Contact> returnList = new List<Contact>();
        
        //change endpoint to sunlight services API
        this.Endpoint = 'http://services.sunlightlabs.com/api';
        
        
        //error handling done internal to this execution path
        resultsList = runQueries('legislators.getList', params);
        
        try{
           returnList = parseContactResults(resultsList);
        }catch(Exception e){
            FGW_Exception.generateError(e, 'Error parsing callout results');
        }
        
        return returnList;
    }    
    
    global List<Roll_Vote__c> getRollVotes(List<FGW_RequestFilterParameters> params){
        resultsList = new List<FGW_JSONObject_RTC>();        
        List<Roll_Vote__c> returnList = new List<Roll_Vote__c>();
        
        //error handling done internal to this execution path
        resultsList = runQueries('votes.json', params);
        
        try{
           returnList = parseRollVoteResults(resultsList);
        }catch(Exception e){
            FGW_Exception.generateError(e, 'Error parsing callout results');
        }
        
        return returnList;
    } 
 
    /** Object Creation Methods **/
    
    //Create Amendment from JSON result
    private List<Amendment__c> parseAmendmentResults(List<FGW_JSONObject_RTC> resultList){
    	List<Amendment__c> returnList = new List<Amendment__c>();    	 
    	 
        for (FGW_JSONObject_RTC JSObj : resultList){
            for (FGW_JSONObject_RTC.Amendment a : JSObj.amendments){
                Amendment__c amd = new Amendment__c();  
                amd.Name = a.x_number;
                returnList.add(amd);            
            }   
        }
        return returnList;
    }
    
    //Create legislation from JSON result
    private List<Legislation__c> parseLegislationResults(List<FGW_JSONObject_RTC> resultList){
    	
    	List<Legislation__c> returnList = new List<Legislation__c>();    	
    	
    	for (FGW_JSONObject_RTC JSObj : resultList){
            for (FGW_JSONObject_RTC.Bill b : JSObj.bills){
                Legislation__c leg = new Legislation__c();	
                leg.Name = b.bill_id;
                leg.Bill_Title__c = b.official_title.length() > 255 ? b.official_title.substring(0,254) : b.official_title;
                leg.Bill_Number__c = Decimal.valueOf(b.x_number);
                leg.Bill_Prefix__c = (b.chamber == 'house' ? 'hr' : 's');
                leg.Congressional_Session__c = b.session;
                leg.Legislative_Body__c = b.chamber;
                if (b.summary != null && b.summary.length() > 32000) leg.Summary__c = b.summary.substring(0, 31999);
                else leg.Summary__c = b.summary;
                leg.Bill_Type__c = b.bill_type;
                leg.Sponsor_Id__c = b.sponsor_id;                
                //basic summaries will not have certain information
                if (b.sponsor != null){                
                    leg.Sponsor_Info__c = b.sponsor.first_name + ' ' + b.sponsor.last_name +  
                                        (b.sponsor.name_suffix != null? ' ' + b.sponsor.name_suffix : '') + ', ' + 
                                        b.sponsor.chamber + ' (' + b.sponsor.party + ' ' + b.sponsor.state + '-' + b.sponsor.district + ')';  
                }                
                leg.Amendment_Count__c = b.amendments_count;
                if (b.keywords != null){                                                
                    for (String keyword : b.keywords){
                	   leg.Categories__c += keyword + ';';
                    }
                }                
                if (b.cosponsors != null){
                	leg.Cosponsors__c = '';
                    leg.Cosponsors_Count__c = b.cosponsors.size();
                    for (FGW_JSONObject_RTC.Legislator l : b.cosponsors){
                        leg.Cosponsors__c += l.first_name + ' ' + l.last_name + (b.sponsor.name_suffix != null? ' ' + b.sponsor.name_suffix : '') + ', ' + 
                                             l.chamber + ' (' + l.party + ' ' + l.state + '-' + l.district + ') \r\n';                    
                    }
                }                
                if(b.last_action != null)leg.Status__c = b.last_action.text;
                if(b.last_action_at != null)leg.Status_Change_Date__c = DateTime.valueOf((b.last_action_at.replace('T', ' ')).replace('Z', ' '));
                if(b.introduced_at != null)leg.Introduced_Date__c = DateTime.valueOf((b.introduced_at.replace('T', ' ')).replace('Z', ' ')); 
                if(b.senate_passage_result_at != null)leg.Senate_Passage_Date__c = Datetime.valueOf((b.senate_passage_result_at.replace('T', ' ')).replace('Z', ' '));
                if(b.house_passage_result_at != null)leg.House_Passage_Date__c = Datetime.valueOf((b.house_passage_result_at.replace('T', ' ')).replace('Z', ' '));
                if(b.enacted_at != null)leg.Enacted_Date__c = Datetime.valueOf((b.enacted_at.replace('T', ' ')).replace('Z', ' '));
                if(b.vetoed_at != null)leg.Vetoed_Date__c = Datetime.valueOf((b.vetoed_at.replace('T', ' ')).replace('Z', ' '));
                if(b.awaiting_signature_since != null)leg.Awaiting_Signature_Date__c = Datetime.valueOf((b.awaiting_signature_since.replace('T', ' ')).replace('Z', ' '));
                leg.Description__c = b.popular_title;
                leg.Senate_Passage_Status__c = b.senate_passage_result;                
                leg.House_Passage_Status__c = b.house_passage_result;                
                leg.Enacted__c = b.enacted;                
                leg.Vetoed__c = b.vetoed;                
                leg.Awaiting_Signature__c = b.awaiting_signature;                
                leg.Passage_Vote_Count__c = b.passage_votes_count;                                                                
                returnList.add(leg);
            }   
        }        
        return returnList;
    }        
    
    //Create Contact from JSON results
    private List<Contact> parseContactResults(List<FGW_JSONObject_RTC> resultList){
        
        List<Contact> returnList = new List<Contact>();       
        
        for (FGW_JSONObject_RTC JSObj : resultList){
            for (FGW_JSONObject_RTC.Legislator l : JSObj.response.legislators){
            	
            	Contact c = new Contact();
            	system.debug('LASTNAME: ' + l.legislator.last_name); 
                c.LastName = l.legislator.last_name + ' ' + l.legislator.name_suffix;
                c.FirstName = l.legislator.first_name;
                c.Bioguide_ID__c = l.legislator.bioguide_id;         
                c.Title = l.legislator.title;
                if (l.legislator.birthdate != null) c.Birthdate = date.valueOf(l.legislator.birthdate);               
                c.Nickname__c = l.legislator.nickname;
                if (l.legislator.party == 'D') c.Party_Affiliation__c = 'Democrat';
                else if (l.legislator.party == 'R') c.Party_Affiliation__c = 'Republican';
                else if (l.legislator.party == 'I') c.Party_Affiliation__c = 'Independent';
                else if (l.legislator.party == 'G') c.Party_Affiliation__c = 'Green';
                else c.Party_Affiliation__c = l.legislator.party;
                c.Congressional_State__c = l.legislator.state;
                c.Congressional_District__c = l.legislator.district;
                c.Active_Member__c = l.legislator.in_office;
                c.Phone = l.legislator.phone;
                c.Fax = l.legislator.fax;
                c.Congressional_Website__c = l.legislator.website;
                c.Web_Contact_Form__c = l.legislator.webform;
                c.Email = l.legislator.email;                
                c.MailingStreet = l.legislator.congress_office;  
                c.FEC_ID__c = l.legislator.fec_id;
                c.Twitter_ID__c = l.legislator.twitter_id;
                c.Youtube_Site__c = l.legislator.youtube_url;
                c.Facebook_ID__c = l.legislator.facebook_id;
                c.Govtrack_ID__c = l.legislator.govtrack_id;
                returnList.add(c);
            }   
        }   
        
        return returnList;
    }
    
    //create roll votes from JSON results    	
    private List<Roll_Vote__c> parseRollVoteResults(List<FGW_JSONObject_RTC> resultList){
        
        List<Roll_Vote__c> returnList = new List<Roll_Vote__c>();       
        
        for (FGW_JSONObject_RTC JSObj : resultList){
            for (FGW_JSONObject_RTC.Roll_Vote r : JSObj.rollvotes){
                Roll_Vote__c rv = new Roll_Vote__c();  
                
                rv.Name = r.roll_id;
                
                if (r.amendment_id != null && r.amendment_id != '')
                    rv.Amendment__c = r.amendment_id;
                else{
                	rv.Legislation__c = r.bill_id;
                }                    
                returnList.add(rv);            
            }   
        }  	
    	return returnList;
    }
    
    
    //create votes from JSON results
    private List<Legislator_Vote__c> parseLegislatorVotesResults(List<FGW_JSONObject_RTC> resultList){
        
        List<Legislator_Vote__c> returnList = new List<Legislator_Vote__c>();       
        
        for (FGW_JSONObject_RTC JSObj : resultList){
            for (FGW_JSONObject_RTC.Roll_Vote rv : JSObj.rollvotes){
            	for (String s : rv.voter_ids.keySet()){
                    for (FGW_JSONObject_RTC.Vote v : rv.voters.get(s)){                    
                    
                        Legislator_Vote__c lv = new Legislator_Vote__c();  
                        lv.Roll_Vote__c = rv.bill_id;
                        lv.Legislator__c = v.voter.bioguide_id;
                        returnList.add(lv);
                    }                        
            	}           
            }   
        }   
        return returnList;
    }
    
    
    /** Call & Parsing Methods **/    
    
    private FGW_RequestFilterParameters condenseRFP(FGW_RequestFilterParameters rfp){
    	FGW_RequestFilterParameters rrfp = new FGW_RequestFilterParameters();
        rrfp.objectName = rfp.objectName;
        rrfp.queryReturnType = rfp.queryReturnType;
        rrfp.adv_query = rfp.adv_query;
        rrfp.APIName = rfp.APIName;
        rrfp.SavedSearchId = rfp.SavedSearchId;
        rrfp.fieldNames = new List<String>();
        rrfp.boolOperators = new List<FGW_Constants.operators>();
        rrfp.comparisonValues = new List<String>();
    	
    	Map<String, Integer> fieldNameMap = new Map<String, Integer>();
        
        Integer index = 0;    	    	
    	
    	for (String s : rfp.fieldNames){
    	    if (!fieldNameMap.containsKey(s)){
                fieldNameMap.put(s, index);
                rrfp.fieldNames.add(s);
                rrfp.boolOperators.add(FGW_Constants.operators.ValueIn);
                rrfp.comparisonValues.add(rfp.comparisonValues[index]);
            }
            else{
                Integer name_index = fieldNameMap.get(s);
                String existingValues = rrfp.comparisonValues[name_index];
                system.debug('ExistinValues: ' + existingValues);
                existingValues += '|' + rfp.comparisonValues[index];
                system.debug('ExistinValues: ' + existingValues);                                                                                
                rrfp.comparisonValues.add(name_index, existingValues);
                rrfp.boolOperators.add(name_index, FGW_Constants.operators.ValueIn);
    	    }	    	
            index++;
    	}
        return rrfp;
    }
    
    //handles the callout and return the JSON Object for further parsing
    private List<FGW_JSONObject_RTC> runQueries(String collection, List<FGW_RequestFilterParameters> params){
    	
    	List<FGW_JSONObject_RTC> returnList = new List<FGW_JSONObject_RTC>();
    	
    	//for each collection of filters, run the query and return the parsed JSON object
    	for (FGW_RequestFilterParameters rfp : params){
            
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();
            FGW_JSONObject_RTC deserializedObj = new FGW_JSONObject_RTC();
            Integer total_retrieved = 0;
            Integer current_page = 1;
            
            //wrap in do-while to control pagination                        
            do{
                try{
                    //exclude the page parameter if using the legislators api
                    if (collection != 'legislators.getList')
                        req = buildHTTPRequest(collection, rfp, '&per_page=50&page=' + current_page);
                    else{
                        req = buildHTTPRequest(collection, rfp, '');
                    }
                    res = doCallout(req);
                    StatusCode = res.getStatusCode();
                    if (res.getStatusCode() == 200){                
                    	String JSONBody = res.getBody();
                    	//replace apex protected words
                    	JSONBody = JSONBody.replace('number', 'x_number');
                    	JSONBody = JSONBody.replace(' as ', ' x_as ');
                        JSONBody = JSONBody.replace('page', 'x_page');
                        
                        //if its legislators, need to account for the slightly different legislator objects
                        if (collection == 'legislators.getList'){
                            JSONBody = JSONBody.replace('lastname', 'last_name');
                            JSONBody = JSONBody.replace('firstname', 'first_name');
                        }    
                        system.debug(JSONBody);
                        deserializedObj = (FGW_JSONObject_RTC)JSON.deserialize(JSONBody, FGW_JSONObject_RTC.class);
                        returnList.add(deserializedObj);                
                    }
                    else{
                        throw new FGW_Exception.CalloutStatusException('Callout Error: ' + res.toString());             
                    }               
                }catch (Exception e){
            	   FGW_Exception.generateError(e, 'Error Creating Valid Request');
                }            
                current_page++;
                
                if (deserializedObj.x_page != null)
                    total_retrieved += deserializedObj.x_page.count;
                else
                    total_retrieved = 1000;                                        
            }while(deserializedObj.count > total_retrieved && total_retrieved < 1000 && current_page < 11);
        }            
        return returnList;        
    }
    
    //construct the request, one request per filter param object
    private HttpRequest buildHTTPRequest(String ResourceName, FGW_RequestFilterParameters params, String page_param){
        
        String parameter_string = '';
        
        //user provided a query through the advanced interface - just assign the value to the URL
        if (params.adv_query != null){
        	parameter_string = params.adv_query;        	
        }
        
        else{  
        	//condense URL conditions for more efficient querying when available
        	if (ResourceName != 'legislators.getList')
        	   params = condenseRFP(params);
        	    
            Integer i = 0;
            //loop through the objects params and construct our query string
            for (i=0; i < params.fieldNames.size(); i++){
                parameter_string += constructParameter(params.objectName, params.fieldNames[i], params.boolOperators[i], params.comparisonValues[i]);
                parameter_string += '&'; 
            }
            //trim off the last s, for savings. 
            system.debug('PARAMETER STRING: ' + parameter_string);
            parameter_string = parameter_string.substring(0, parameter_string.length());           
            system.debug('PARAMETER STRING: ' + parameter_string);                 	   
        }
                
        //take only what you need to survive...
        if (ResourceName == 'bills.json' && params.queryReturnType == FGW_Constants.queryReturntype.Basic){
            parameter_string += '&sections=basic';            
        }
        //if we're using the older API, include the key in the URL and remove any advanced query operators
        if (ResourceName == 'legislators.getList'){
        	parameter_string += '&apikey=' + this.API_Key;
        }
        
        // Compose the URL
        String url = Endpoint + '/' + ResourceName + '?' + parameter_string + page_param;
        system.debug('ENDPOINT: ' + url);

       // Instantiate a new HTTP request, GET method, set endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);        
        req.setMethod('GET');
        req.setHeader('X-APIKEY', API_Key);
        return req; 
    }
    
    private HttpResponse doCallout(HttpRequest req){    	
    	Http h = new Http();
    	HttpResponse res = new HttpResponse();    	
    	res = h.send(req);
        return res;
    }
    
    
    private String constructParameter(String objName, String fieldName, FGW_Constants.operators operator, String value){
    	String return_parameter = '';
    	
    	Map<String, String> translationMap = RTC_Translation.get(objName);
    	
    	return_parameter += translationMap.get(fieldName);
         //global enum operators{Equals, LessThan, LessThanEqualTo, GreaterThan, GreatThanEqualTo, NotEqual, Match, MatchCS, Exists, ValueIn, ValueNotIn, All}
        if(operator == FGW_Constants.operators.Equals)
    	    return_parameter += '=' + value;    	
    	else if (operator == FGW_Constants.operators.LessThan)
            return_parameter += '__lt=' + value;    	   
    	else if (operator == FGW_Constants.operators.LessThanEqualTo)
            return_parameter += '__lte=' + value;    	   
    	else if (operator == FGW_Constants.operators.GreaterThan)
            return_parameter += '__gt=' + value;    	   
    	else if (operator == FGW_Constants.operators.GreaterThanEqualTo)
            return_parameter += '__gte=' + value;    	   
    	else if (operator == FGW_Constants.operators.NotEqual)
            return_parameter += '__ne=' + value;    	   
    	else if (operator == FGW_Constants.operators.Match) 
            return_parameter += '__match=' + value;    	
    	else if (operator == FGW_Constants.operators.MatchCS)
            return_parameter += '__match_s=' + value;    	
    	else if (operator == FGW_Constants.operators.Exists)
            return_parameter += '__exists=' + value;    	   
    	else if (operator == FGW_Constants.operators.ValueIn)
            return_parameter += '__in=' + value;    	
    	else if (operator == FGW_Constants.operators.ValueNotIn)
            return_parameter += '__nin=' + value;    	   
    	else if (operator == FGW_Constants.operators.All)
            return_parameter += '__all=' + value;    	   
    	
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
        LegislatorMap.put('Bioguide_ID__c', 'bioguide_id');
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
        Map<String, String> BillMap = new Map<String, String>();
        BillMap.put('Bill_Id__c', 'bill_id');
        RTCMap.put('Legislation__c', BillMap);       
        
        return RTCMap;
    }



}