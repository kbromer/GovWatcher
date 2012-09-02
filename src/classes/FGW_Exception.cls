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
            FGW_Exception.generateError(e, s);                           	     	
        }
    }
    
    //error recognizing API-returned object for search results
    public class SearchConversionException extends FGW_Exception{}
    
    public class CalloutStatusException extends FGW_Exception{}
    
    
    public static void generateError(Exception e, String s){
        FGW_Exception.createErrorObject(system.now(), e.getLineNumber(), e.getMessage(), e.getStackTraceString(), e.getTypeName(), s);
    }
    
    @future
    public static void createErrorObject(Datetime d, Integer line_number, String message, String stack_trace, String type_name, String friendly_message){    	
    	
        FGW_Error__c error = new FGW_Error__c(
            Error_Datetime__c = d,
            Error_Line_Number__c = string.valueOf(line_number),    
            Error_Message__c = message,
            Error_Stack_Trace__c = stack_trace,
            Error_Type__c = type_name            
        );
        
        if (friendly_message != null && friendly_message != '')
            error.Friendly_Message__c = friendly_message;
        else
            error.Friendly_Message__c = message;            	
    	insert error;
    }
}