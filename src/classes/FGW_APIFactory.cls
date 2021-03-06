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
* @description Global factory for instantiating congressional apis defined by user 
*/
global class FGW_APIFactory {

    public static FGW_Application_Settings__c AppSettings = FGW_Constants.AppSettings;

    public static FGW_IAPI getDefault_Federal_API_Instance(){
    	system.debug('AppSETTINGS: ' + AppSettings.Federal_API_Name__c);
        return FGW_APIFactory.getAPI_Instance(AppSettings.Federal_API_Name__c);
    }
    
    public static FGW_IAPI getDefault_State_API_Instance(){
        return FGW_APIFactory.getAPI_Instance(AppSettings.State_API_Name__c);    	
    }
    
    public static FGW_IAPI getAPI_Instance(String APIName){
            	
    	String IAPIClass;
        FGW_IAPI API;
        
        try{
            FGW_API_Settings__c APISettings = FGW_API_Settings__c.getInstance(APIName);
            IAPIClass = APISettings.Class_Name__c;
            Type t = Type.forName(IAPIClass);
            API = (FGW_IAPI)t.newInstance();
        }
        catch (Exception e){
            throw new FGW_Exception.APICreationException(e, 'Error Creating API Instance');           
        }       
        return API;
    }
}