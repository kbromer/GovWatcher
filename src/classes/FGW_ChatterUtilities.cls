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
* @description Handles creating and maintaining Chatter messages for various FGW actions 
*/
public with sharing class FGW_ChatterUtilities {
	
    public static void chatterResultConversion(List<sobject> conversionresults){
        List<FeedItem> feeditemInserts = new List<FeedItem>();
        List<EntitySubscription> esInserts = new List<EntitySubscription>();
        
        for (sobject obj : conversionresults){
            if (obj.id != null){
                feeditemInserts.add(FGW_ChatterUtilities.createConversionFeedItem(obj));
                esInserts.add(new EntitySubscription(ParentId = obj.id, SubscriberId = FGW_Constants.AppSettings.Chatter_User_Id__c));
            }            	
        }
        
        if(!esInserts.isEmpty()) insert esInserts;
        if(!feeditemInserts.isEmpty()) insert feeditemInserts;
    	
    }
    
     public static void chatterRollVoteAddition(Map<String, Object> rvMap){
     	List<FeedItem> feeditemInserts = new List<FeedItem>();
        
        List<Legislation__c> legList = [select id, Bill_ID__c from Legislation__c where Bill_ID__c IN :rvMap.keySet()];
        Map<String, ID> legIDsByBillID = new Map<String, ID>();
        
        for (Legislation__c l : legList){
            legIDsByBillID.put(l.Bill_ID__c, l.id);
        }
                                    
        for (String s : rvMap.keySet()){
            feeditemInserts.add(createNewRollVoteFeedItem(legIDsByBillId.get(s), s, rvMap.get(s)));         
        }
        if(!feeditemInserts.isEmpty()) insert feeditemInserts;
     }
     
    //map of bill id plus either the amendment ID (string) or the total count of amendments if more than
    //one (integer)
    public static void chatterAmendmentAddition(Map<String, Object> amendmentMap){
        List<FeedItem> feeditemInserts = new List<FeedItem>();
        
        List<Legislation__c> legList = [select id, Bill_ID__c from Legislation__c where Bill_ID__c IN :amendmentMap.keySet()];
        Map<String, ID> legIDsByBillID = new Map<String, ID>();
        for (Legislation__c l : legList){
        	legIDsByBillID.put(l.Bill_ID__c, l.id);
        }
                                    
    	for (String s : amendmentMap.keySet()){
            feeditemInserts.add(createNewAmendmentFeedItem(legIDsByBillId.get(s), s, amendmentMap.get(s)));    		
    	}
    	if(!feeditemInserts.isEmpty()) insert feeditemInserts;    	
    }
    
    private static FeedItem createConversionFeedItem(Sobject obj){
        FeedItem fi = new FeedItem(
            Type = 'TextPost',
            ParentId = obj.Id,
            CreatedById = FGW_Constants.AppSettings.Chatter_User_Id__c,
            Body = System.label.FGW_Chatter_ConversionPost.replace('{!Name}', (String)obj.get('Name'))            
        );              
        return fi;    	    	  
    }
    
    private static FeedItem createNewAmendmentFeedItem(Id LegId, String Bill_id, object obj){
    	FeedItem fi = new FeedItem(
            Type = 'TextPost',    
            CreatedById = FGW_Constants.AppSettings.Chatter_User_Id__c,
            ParentId = LegId                        
        );
        
        //its a single insert, so we have an amendment id
        if(obj instanceof String){
        	fi.Body = System.Label.FGW_Chatter_SingleAmendmentInsertPost.replace('{!Bill}', Bill_id).replace('{!Name}', (string)obj);
        }
        
        //multiple amendments, so we just indicate how many are inserted 
        else{
        	fi.Body = system.label.FGW_Chatter_MultipleAmendmentInsertPost.replace('{!Bill}', Bill_id).replace('{!Name}', String.valueOf((Integer)obj));
        }
    	return fi;    	
    }
    
    private static FeedItem createNewRollVoteFeedItem(Id LegId, String Bill_id, object obj){
    	FeedItem fi = new FeedItem(
            Type = 'TextPost',    
            CreatedById = FGW_Constants.AppSettings.Chatter_User_Id__c,
            ParentId = LegId                        
        );
        
        //its a single insert, so we have a roll vote id
        if(obj instanceof String){
            fi.Body = System.Label.FGW_Chatter_SingleRollVoteInsertPost.replace('{!Bill}', Bill_id).replace('{!Name}', (string)obj);
        }
        
        //multiple roll votes, so we just indicate how many are inserted 
        else{
            fi.Body = system.label.FGW_Chatter_MultipleRollVoteInsertPost.replace('{!Bill}', Bill_id).replace('{!Name}', String.valueOf((Integer)obj));
        }       
        
    	return fi;
    }
}