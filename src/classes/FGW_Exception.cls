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
* @description Exception methods for the Foundation GovWatcher
*/
public virtual class FGW_Exception extends Exception{
    
    //errors when instantiating a new API instance from the settings
    public class APICreationException extends FGW_Exception{
        public APICreationException(Exception e, String s){
            generateError(e, s);                    	     	
        }
    }
        
    
    
    private void generateError(Exception e, String s){
        FGW_Error__c error = new FGW_Error__c(
            Error_Datetime__c = system.now(),
            Error_Line_Number__c = String.valueOf(e.getLineNumber()),    
            Error_Message__c = e.getMessage().substring(0,254),
            Error_Stack_Trace__c = e.getStackTraceString().substring(0,254),
            Error_Type__c = e.getTypeName()            
        );
        
        if (s != null && s != '')
            error.Friendly_Message__c = s;
        else
            error.Friendly_Message__c = e.getMessage().substring(0,254);     
            	
    	insert error;
    }
}