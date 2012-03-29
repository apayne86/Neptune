﻿<cfcomponent extends="com.sebtools.Records" output="no">

<cfset variables.prefix = "util">

<cffunction name="init" access="public" returntype="any" output="no" hint="I initialize and return this component.">
	<cfargument name="Manager" type="any" required="true">
	<cfargument name="Settings" type="any" required="false">
	
	<cfset initInternal(argumentCollection=arguments)>
	
	<cfreturn This>
</cffunction>

<cffunction name="addContentBlock" access="public" returntype="any" output="no" hint="I add the given setting if it doesn't yet exist.">
	
	<cfset var qCheck = getContentBlocks(ContentBlockName=Arguments.ContentBlockName,ExcludeComponent=Arguments.Component,fieldlist="ContentBlockID,Component")>
	
	<cfif qCheck.RecordCount>
		<cfset throwError(Message="A content block of this name is already being used by another component (""#qCheck.Component#"").",ErrorCode="NameConflict")>
	</cfif>
	
	<!---
	Only take action if this doesn't already exists for this component.
	(we don't want to update because the admin may have change the notice from the default settings)
	--->
	<cfif NOT hasContentBlocks(ContentBlockName=Arguments.ContentBlockName,Component=Arguments.Component)>
		<cfset saveContentBlock(ArgumentCollection=arguments)>
	</cfif>
	
</cffunction>

<cffunction name="getContentBlockHTML" access="public" returntype="string" output="no" hint="I get the HTML for the requested content block.">
	<cfargument name="ContentBlockName" type="string" required="yes">
	
	<cfset var qContentBlock = getContentBlocks(ContentBlockName=Arguments.ContentBlockName,fieldlist="ContentBlockID,isHTML,ContentBlockText")>
	<cfset var result = "">
	
	<cfif qContentBlock.RecordCount>
		<cfset result = qContentBlock.ContentBlockText>
		<cfif NOT ( qContentBlock.isHTML IS true )>
			<cfset result = ParagraphFormatFull(qContentBlock.ContentBlockText)>
		</cfif>
		<cfif StructKeyExists(Variables,"Settings") AND StructKeyExists(Variables.Settings,"populate")>
			<cfset output = Variables.Settings.populate(result)>
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getContentBlockID" access="public" returntype="string" output="no" hint="I get the ID for the requested content block.">
	<cfargument name="ContentBlockName" type="string" required="yes">
	
	<cfset var qContentBlock = getContentBlocks(ContentBlockName=Arguments.ContentBlockName,fieldlist="ContentBlockID")>
	<cfset var result = 0>
	
	<cfif qContentBlock.RecordCount>
		<cfset result = qContentBlock.ContentBlockID>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getContentBlockText" access="public" returntype="string" output="no" hint="I get the TEXT for the requested content block.">
	<cfargument name="ContentBlockName" type="string" required="yes">
	
	<cfset var qContentBlock = getContentBlocks(ContentBlockName=Arguments.ContentBlockName,fieldlist="ContentBlockID,isHTML,ContentBlockText")>
	<cfset var result = "">
	
	<cfif qContentBlock.RecordCount>
		<cfset result = qContentBlock.ContentBlockText>
		<cfif qContentBlock.isHTML IS true>
			<cfset result = HTMLEditFormat(qContentBlock.ContentBlockText)>
		</cfif>
		<cfif StructKeyExists(Variables,"Settings") AND StructKeyExists(Variables.Settings,"populate")>
			<cfset output = Variables.Settings.populate(result)>
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getFieldsArray" access="public" returntype="array" output="no">
	
	<cfset var qContentBlocks = 0>
	<cfset var aResults = 0>
	
	<cfif StructKeyExists(Arguments,"ContentBlockID") AND Len(Arguments.ContentBlockID) AND NOT isNumeric(Arguments.ContentBlockID)>
		<cfset qContentBlocks = getContentBlocks(ContentBlockNames=Arguments.ContentBlockID,fieldlist="ContentBlockID,ContentBlockName,isHTML,ContentBlockText")>
		<cfset aResults = ArrayNew(1)>
		
		<cfoutput query="qContentBlocks">
			<cfset ArrayAppend(aResults,StructNew())>
			<cfset aResults[ArrayLen(aResults)]["name"] = qContentBlocks.ContentBlockID[CurrentRow]>
			<cfif isHTML IS true>
				<cfset aResults[ArrayLen(aResults)]["type"] = "FCKeditor">
			<cfelse>
				<cfset aResults[ArrayLen(aResults)]["type"] = "textarea">
			</cfif>
			<cfset aResults[ArrayLen(aResults)]["label"] = ContentBlockName>
			<cfset aResults[ArrayLen(aResults)]["defaultValue"] = ContentBlockText>
		</cfoutput>
		<!---<cfdump var="#aResults#">
		<cfdump var="#Super.getFieldsArray(ArgumentCollection=Arguments)#">
		<cfabort>--->
		<cfreturn aResults>
	<cfelse>
		<cfreturn Super.getFieldsArray(ArgumentCollection=Arguments)>
	</cfif>
</cffunction>

<cffunction name="getFieldsStruct" access="public" returntype="struct" output="no">
	
	<cfset var sFields = StructNew()>
	<cfset var aFields = 0>
	<cfset var ii = 0>
	
	<cfset aFields = getFieldsArray(argumentCollection=arguments)>
	
	<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
		<cfif StructKeyExists(aFields[ii],"name")>
			<cfset sFields[aFields[ii]["name"]] = aFields[ii]>
		</cfif>
	</cfloop>
	
	<cfreturn sFields>
</cffunction>

<!---<cffunction name="getContentBlocksEditQuery" access="public" returntype="string" output="no">
	<cfargument name="ContentBlockNames" type="string" required="yes">
	
	<cfset var qContentBlock = getContentBlocks(ContentBlockNames=Arguments.ContentBlockNames,fieldlist="ContentBlockID,isHTML,ContentBlockText")>
	<cfset var result = "">
	
	<cfif qContentBlock.RecordCount>
		<cfset result = qContentBlock.ContentBlockText>
		<cfif qContentBlock.isHTML IS true>
			<cfset result = HTMLEditFormat(qContentBlock.ContentBlockText)>
		</cfif>
		<cfif StructKeyExists(Variables,"Settings") AND StructKeyExists(Variables.Settings,"populate")>
			<cfset output = Variables.Settings.populate(result)>
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>--->

<cffunction name="saveContentBlock" access="public" returntype="string" output="no">
	
	<cfset var qContentBlocks = 0>
	
	<cfif isMultiEdit(ArgumentCollection=Arguments)>
		<cfset qContentBlocks = getContentBlocks(fieldlist="ContentBlockID")>
		<cfoutput query="qContentBlocks">
			<cfif StructKeyExists(Arguments,"a#qContentBlocks['ContentBlockID'][CurrentRow]#")>
				<cfset saveRecord(ContentBlockID=qContentBlocks['ContentBlockID'][CurrentRow],ContentBlockText=Arguments["a#qContentBlocks['ContentBlockID'][CurrentRow]#"])>
			</cfif>
		</cfoutput>
	<cfelse>
		<cfreturn saveRecord(ArgumentCollection=Arguments)>
	</cfif>
	
</cffunction>

<cffunction name="isMultiEdit" access="private" returntype="boolean" output="no">
	
	<cfset var qContentBlocks = getContentBlocks(fieldlist="ContentBlockID")>
	<cfset var result = false>
	
	<cfoutput query="qContentBlocks">
		<cfif StructKeyExists(Arguments,"a#qContentBlocks['ContentBlockID'][CurrentRow]#")>
			<cfreturn true>
		</cfif>
	</cfoutput>
	
	<cfreturn false>
</cffunction>

<cffunction name="validateContentBlock" access="public" returntype="struct" output="no">
	
	<cfset Arguments = validateBrief(ArgumentCollection=Arguments)>
	
	<cfreturn Arguments>
</cffunction>

<cffunction name="validateBrief" access="private" returntype="struct" output="no">
	
	<cfif StructKeyExists(Arguments,"ContentBlockText")>
		<cfset Arguments.ContentBlockBrief = Abbreviate(Arguments.ContentBlockText,150)>
	</cfif>
	
	<cfreturn Arguments>
</cffunction>

<cffunction name="Abbreviate" access="public" returntype="string" output="no">
	<cfargument name="string" type="string" required="true">
	<cfargument name="length" type="string" required="true">
	
	<cfset var result = Arguments.string>
	<cfset var addEllipses = false>
	
	<!--- Remove all contentless tags at the front and end of the string --->
	<cfset result = ReReplaceNoCase(result,"^.*?>","")>
	<cfset result = ReReplaceNoCase(result,"^(<.*?>\s*)*","")>
	<cfset result = ReReplaceNoCase(result, "(</[^>]*>|\s)*$","")>
	
	<cfif FindNoCase("</p>",result,1) GT 1>
		<cfset result = Left(result,FindNoCase("</p>",result,1)-1)>
		<cfset addEllipses = true>
	</cfif>
	<cfif FindNoCase("<br",result,1) GT 1>
		<cfset result = Left(result,FindNoCase("<br",result,1)-1)>
		<cfset addEllipses = true>
	</cfif>
	
	<cfset result = Left(result,Arguments.length+1)>
	<cfif Len(Trim(result)) GT Arguments.length>
		<cfset result = Left(result,Arguments.length-3)>
		<cfset result = ReReplaceNoCase(result,"[^\s]*$","")>
		<cfset addEllipses = true>
	</cfif>
	
	<cfset result = Trim(result)>
	<cfset result = stripHTML(result)>
	
	<cfif addEllipses>
		<cfset result = "#Trim(result)#...">
		<cfset result = ReReplaceNoCase(result,"\.{4,}$","...")>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="xml" access="public" output="yes">
<tables prefix="#variables.prefix#">
	<table entity="Content Block" universal="true" Specials="CreationDate,LastUpdateDate">
		<field name="Component" label="Component" type="text" Langth="120" help="A unique identifier for the component or program using this setting" />
		<field name="isHTML" label="HTML?" type="boolean" default="false" />
		<field name="ContentBlockText" label="Text" type="memo" />
		<field name="ContentBlockBrief" label="Brief" type="text" Length="150" />
		<filter name="ExcludeComponent" field="Component" operator="NEQ" />
	</table>
</tables>
</cffunction>
<cfscript>
/**
 * Removes HTML from the string.
 * v2 - Mod by Steve Bryant to find trailing, half done HTML.        
 * v4 mod by James Moberg - empties out script/style blocks
 * 
 * @param string      String to be modified. (Required)
 * @return Returns a string. 
 * @author Raymond Camden (ray@camdenfamily.com) 
 * @version 4, October 4, 2010 
 */
function stripHTML(str) {
    str = reReplaceNoCase(str, "<*style.*?>(.*?)</style>","","all");
    str = reReplaceNoCase(str, "<*script.*?>(.*?)</script>","","all");

    str = reReplaceNoCase(str, "<.*?>","","all");
    //get partial html in front
    str = reReplaceNoCase(str, "^.*?>","");
    //get partial html at end
    str = reReplaceNoCase(str, "<.*$","");
    return trim(str);
}

function ParagraphFormatFull(str) {
    //first make Windows style into Unix style
    str = replace(str,chr(13)&chr(10),chr(10),"ALL");
    //now make Macintosh style into Unix style
    str = replace(str,chr(13),chr(10),"ALL");
    //now fix tabs
    str = replace(str,chr(9),"&nbsp;&nbsp;&nbsp;","ALL");
    //now return the text formatted in HTML
    str = replace(str,chr(10),"<br />","ALL");
    
    str = replace(str,"<br /><br />","</p><p>","ALL");
    
    str = "<p>#str#</p>";
    
    return str;
}
</cfscript>
</cfcomponent>