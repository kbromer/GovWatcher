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
* @description Controller for the FGW settings page 
*/
public with sharing class FGW_Settings_CTRL {


    public String activeTabPanel{get;set;}
    public Boolean isEditingAppSettings{get;private set;}
    public List<FGW_Error__c> errorList{get;set;}
    public Integer errorCount{get{return errorList.size();}} 
    public List<FGW_API_Settings__c> existingAPIs{get; set;}
    public FGW_API_Settings__c newdatasource{get{return newdatasource!=null?newdatasource:new FGW_API_Settings__c();}set;}
    public Boolean showEditBlock{get;set;}
    public String datasourcetext{get;set;}
    
    public FGW_Settings_CTRL(){

        //set the active panel
        activeTabPanel = 'app_settings';
        
        //check for possible errors
        errorList = new List<FGW_Error__c>();
        errorList = [select Error_Datetime__c, Error_Line_Number__c, Error_Message__c, Error_Stack_Trace__c,
                            Error_Type__c, Friendly_Message__c, Id from FGW_Error__c order by Error_Datetime__c desc];
        
        existingAPIs = FGW_API_Settings__c.getAll().values();
        showEditBlock = false;
        
        
        //set the GovWatcher scheduled job, if possible
        
        
    }
     
    
    
    
    public PageReference saveAppSettings(){
    	
    	return null;
    }
    
    public PageReference cancel(){
    	
    	return null;
    }
    
     public PageReference cancelDS(){
        datasourcetext = '';
        //dump the current one
        newdatasource = new FGW_API_Settings__c();
        activeTabPanel = 'ds_settings';        
        //turn off the edit block
        showEditBlock=false;        
        return null;
    }
    
    public PageReference editApp_settings(){ 
    	return null;
    }
    
    public PageReference createNewDS(){
        Boolean editDSSource = false;
        for (FGW_API_Settings__c f : existingAPIs){
        	if (datasourcetext == f.Name){
        	    newdatasource = f;
                editDSSource = true;                        	       
        	    break;
        	}	   
        }
        if (!editDSSource)
            newdatasource = new FGW_API_Settings__c();
        
        showEditBlock = true;    	   
        return null;
    }      
    public PageReference saveDSSettings(){
        Boolean isInsert;
        if (newdatasource.id != null)
            isInsert = false;
        else
            isInsert = true;            
        
        upsert(newdatasource);      
        showEditBlock = false;  
        
        if (isInsert)
            existingAPIs.add(newdatasource);
        newdatasource = null;
        return null;    
    }
    public PageReference deleteDS(){
    	Integer delete_element_index = 0;
    	for (FGW_API_Settings__c f : existingAPIs){
            if (datasourcetext == f.Name){
                newdatasource = f;                                          
                break;
            }      
            delete_element_index++;
        }
        delete newdatasource;
        existingAPIs.remove(delete_element_index);
        return null;    	
    }


}