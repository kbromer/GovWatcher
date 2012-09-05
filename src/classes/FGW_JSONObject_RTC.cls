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
* @description Object model to hold deserialized JSON for RealTimeCongress API 
*/
public with sharing class FGW_JSONObject_RTC{
	
	public List<Amendment> amendments;
	public List<Bill> bills;	
	public List<Roll_Vote> rollvotes;
	public Integer count;
	public x_Page x_page;

	public class x_Page{
		public Integer count;
		public Integer per_page;
		public Integer page;
	}	
	
    public class Bill{
        public String bill_id;
        public String bill_type;
        public String x_number;
        public String session;
        public String chamber;
        public String short_title;
        public String official_title;              
        public String popular_title;
        public List<Title> titles;                 
        public String summary;
        public String sponsor_id;
        public Legislator sponsor;
        public List<Legislator> cosponsors;
        public List<String> committee_ids;
        public List<CommitteeHash> comittees;
        public List<String> amendment_ids;
        public List<Amendment> amendments;                              
        public integer amendments_count;
        public List<String> keywords;
        public List<Action> actions;
        public Action last_action;
        public String last_action_at;
        public List<Passage_Vote> passage_votes;                        
        public integer passage_votes_count;
        public String last_passage_vote_at;     
  //      public List<RelatedBillHash> related_bills;
        public String introduced_at;
        public String senate_passage_result;
        public String senate_passage_result_at;
        public String house_passage_result;
        public String house_passage_result_at;
        public Boolean awaiting_signature;
        public String awaiting_signature_since;
        public Boolean vetoed;                
        public String vetoed_at;
        public String senate_override_result;
        public String senate_override_result_at;
        public String house_override_result;
        public String house_override_result_at;
        public Boolean enacted;
        public String enacted_at;        
    }    
    
    public class Passage_Vote{
        public String result;
        public String voted_at;
        public String passage_type;
        public String text;
        public String how;
        public String roll_id;           
        public String chamber;
    }
    
    public class Action{
        public String text;
        public String acted_at;
        public String type;    
    }

    public class Title{
        public String title;
        public String type;
        public String x_as;        
    }
    
    public class RelatedBillHash{
        public Map<String, List<String>> bills;
    }
    
    public class CommitteeHash{
        public Map<String, List<Committee>> activity;
    }
    
    public class Committee{
        public String name;
        public String committee_id;
        public String chamber;      
    }
    
    public class Legislator{
        public String title = '';
        public String nickname = '';
        public String district = '';
        public String bioguide_id = '';
        public String govtrack_id = '';
        public String last_name = '';
        public String name_suffix = '';
        public String party = '';
        public String first_name = '';
        public String state = '';
        public String chamber = '';
    }
    
    public class Amendment{    	
        public String session;
        public String x_number;
        public String chamber;
        public String state;
        public String offered_at;
        public String description;
        public String purpose;
        public String sponsor_type;
        public String sponsor_id;
        public Legislator sponsor;  //this will need further parsing, can be either a committee or a sponsor
        public String bill_id;
        public Bill bill;
        public List<Action> actions;
        public String last_action_at;
    }
    
    public class Vote{
        public String vote;
        public Legislator voter;
    }
    
    public class Roll_Vote{
        public String session;
        public String chamber;
        public Integer year;
        public String vote_type;
        public String question;
        public String result;    	
        public String required;
        public String voted_at;
        public String how;
        public String roll_id;
        public String roll_type;
        public String bill_id;
        public Bill bill;
        public String amendment_id;
        public Amendment amendment;
        public Map<String, List<Vote>> voter_ids;
        public Map<String, List<Vote>> voters;
        public Map<String, List<Vote_Result>> vote_breakdown;                  	
    }
    
    public class Vote_Result{
    	public Integer Not_Voting;
    	public Integer Nay;
    	public Integer Present;
    	public Integer Yea;
    	public Map<String, Party_Result> party;    	
    }
    
    public class Party_Result{
    	public Integer Not_Voting;
        public Integer Nay;
        public Integer Present;
        public Integer Yea;    	
    }
    
    public static testMethod void testBillObjectModel(){
    	FGW_JSONObject_RTC deserializedBill = (FGW_JSONObject_RTC)JSON.deserialize(FGW_TestUtilities_TEST.getBillJSON(), FGW_JSONObject_RTC.class);
        system.assertNotEquals(deserializedBill, null);
    }
    
    public static testMethod void testVoteObjectModel(){
        FGW_JSONObject_RTC deserializedVote = (FGW_JSONObject_RTC)JSON.deserialize(FGW_TestUtilities_TEST.getVoteJSON(), FGW_JSONObject_RTC.class);
        system.assertNotEquals(deserializedVote, null);    	
    }
    
    public static testMethod void testAmendmentObjectModel(){
    	FGW_JSONObject_RTC deserializedAmendment = (FGW_JSONObject_RTC)JSON.deserialize(FGW_TestUtilities_TEST.getAmendmentJSON(), FGW_JSONObject_RTC.class);
    	system.assertNotEquals(deserializedAmendment, null);
        system.debug('ONE FIELD HERE: ' + deserializedAmendment.amendments[0].sponsor_id);
    }
}