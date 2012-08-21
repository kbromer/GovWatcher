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
* @description Global static constants used for any given transaction 
*/
global with sharing class FGW_Constants {

    //possible filter operators for query requests
    global enum operators{LessThan, LessThanEqualTo, GreaterThan, GreatThanEqualTo, NotEqual, Match, MatchCS, Exists, ValueIn, ValueNotIn, All}

    global static FGW_Application_Settings__c AppSettings;

    global FGW_Application_Settings__c getAppSettings(){
        if (AppSettings == null){
            AppSettings = FGW_Application_Settings__c.getOrgDefaults();        
            
            //no settings defined at all for this org, load some defaults
            if (AppSettings == null){
                AppSettings = new FGW_Application_Settings__c(
                    Federal_API_Name__c = 'FGW_RealTimeCongressAPI',
                    State_API_Name__c = 'FGW_OpenStatesAPI'                
                );
                insert AppSettings;                	
            }
        }    
    	return AppSettings;
    }


}