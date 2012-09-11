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
* @description Global interface for congressional APIs, supports multiple implementations 
*/
global interface FGW_IAPI{
    //Methods to retrieve information from the data source given a list of parameters
    List<Legislation__c> getBills(List<FGW_RequestFilterParameters> params);    
    List<Amendment__c> getAmendments(List<FGW_RequestFilterParameters> params);
    List<Legislator_Vote__c> getVotes(List<FGW_RequestFilterParameters> params);    
    List<Contact> getLegislators(List<FGW_RequestFilterParameters> params);
    List<Roll_Vote__c> getRollVotes(List<FGW_RequestFilterParameters> params);
    
    //Returns the most recent status code of the data source, should default to -1(no request yet made)
    //and return 0(bad request), 1(good request) or the HTTP request response
    Integer getStatusCode();
    
    //holds the mapping between GovWatcher fields and the API fields.  Used to determine
    //what search criteria to make available for any given data source, and to indicate
    //what types of collections are available for the source
    //format is <ObjectName, <GovWatcherFieldName, APIFieldNameParameter>>. 
    //Example: <'Legislation__c', <'Bill_Id__c', 'bill_id'>>
    //NOTE: Special optional 'FullText' parameter is acceptable for GovWatcherFieldName if the 
    //API/collection allows a full text search. For example, the Real Time Congress API accepts full text search 
    //for a variety of collections, for bills, it would be:  <'Legislation__c', <'FullText', 'search'>>
    Map<String, Map<String, String>> getFieldMapping();
}