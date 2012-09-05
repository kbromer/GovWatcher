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
    	    	system.debug('Have CONTACT');
                Contact c = (Contact)obj;
                result = new FGW_Search_Result__c();                
                result.Name = c.Bioguide_ID__c;    	
                result.Full_Name__c = c.Title + ' ' + c.FirstName + ' ' + c.LastName;
                
                                    
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

}