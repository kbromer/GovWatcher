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
    
         
    
    public FGW_Console_CTRL(){
        AppSettings = FGW_Constants.AppSettings;
        ChatterUserId = AppSettings.Chatter_User_Id__c; 
        FeedDisplayId = ChatterUserId;
        FeedName = [select Name from User where Id = :ChatterUserId].Name;          
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
    
}