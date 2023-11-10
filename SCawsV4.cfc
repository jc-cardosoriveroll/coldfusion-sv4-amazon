<cfcomponent>
    <!---------------------------------------------------------------------->
    <!----- Main method to send requests to Amazon Seller Central APIS ----->
    <!---------------------------------------------------------------------->
    <cffunction name="postRequest" hint="all scripts" access="public">
        <cfargument name="keys" required="true" type="struct" hint="struct with keys from DB">
        <cfargument name="requestMethod" required="false" default="GET">
        <cfargument name="path" default="sellers/v1/marketplaceParticipations">
        <cfargument name="qString" default="" hint="">
        <cfargument name="payLoad" required="false" default="">
        <cfargument name="endpoint" required="false" default="https://sellingpartnerapi-na.amazon.com">

        <cfset local.data = structnew()>
        <cfset local.data.auth = getAccessToken(keys=arguments.keys)>
        <cfset variables.dteNow = dateAdd("s",GetTimeZoneInfo().UTCTotalOffset, now())>
        <cfset variables.strCanonicalDate = getCanonicalDateFormat(dteNow = variables.dteNow)>
        <cfset variables.strShortDate = getShortDateFormat(dteNow = variables.dteNow)>
        <cfset local.data.strCanonical = createCanonical(
                            strHTTPRequestMethod       = "#arguments.requestMethod#",
                            strCanonicalURI            = "/#arguments.path#",
                            strCanonicalQueryString    = "#arguments.qString#",
                            arrCanonicalHeaders        = ["host:#arguments.endpoint#","x-amz-date:#variables.strCanonicalDate#"],
                            arrSignedHeaders           = ["host","x-amz-date"],
                            strPayLoad                 = "#arguments.payLoad#"
                            )>        
        <cfset local.data.strStringToSign    = createStringToSign(
                            strAlgorithm        = "AWS4-HMAC-SHA256",
                            strRequestDate        = "#variables.strCanonicalDate#",
                            strCredentialScope    = strShortDate & "/" & arguments.keys.zone & "/execute-api/aws4_request",
                            strCanonicalRequest    = local.data.strCanonical
                            )>
        <cfset local.data.bSigningKey    = createSigningKey(
                            keys        = arguments.keys,
                            dateStamp    = strShortDate,
                            regionName    = keys.zone,
                            serviceName    = "execute-api"
                            )>
        <cfset local.data.bSignatureNew = lcase(hmac(local.data.strStringToSign,local.data.bSigningKey,"HMACSHA256")) >
        <cfset local.url = "#arguments.endpoint#/#arguments.path#">
        <cfif arguments.qString neq ''><cfset local.url = local.url & "?#arguments.qString#"></cfif>
        <cfhttp method="#arguments.requestMethod#" url="#local.url#">
            <cfhttpparam type="header" name="x-amz-date" value="#variables.strCanonicalDate#">
            <cfhttpparam type="header" name="Authorization" value="AWS4-HMAC-SHA256 Credential=#arguments.keys.strPublicKey#/#variables.strShortDate#/#arguments.keys.zone#/execute-api/aws4_request, SignedHeaders=host;x-amz-date, Signature=#local.data.bSignatureNew#" />
            <cfhttpparam type="header" name="x-amz-access-token" value="#local.data.auth.access_token#" />
            <cfhttpparam type = "body" value = "#arguments.payLoad#">
        </cfhttp>
        <cfreturn cfhttp.filecontent>
    </cffunction>

    <!---------------------------------------------------------------------->
    <!----- Main method to get access token from AWS  ---------------------->
    <!---------------------------------------------------------------------->
    <cffunction name="getAccessToken" access="public">
        <cfargument name="keys" required="true" type="struct" hint="struct with keys from DB">
        <cfargument name="grant_type" default="refresh_token">
        <cfargument name="scope" default="sellingpartnerapi::notifications">

        <cfset local.result = structnew()>
        <cfset local.result["success"] = false>
        <cfset requestBody = '{"grant_type":"#arguments.grant_type#",
                                "client_id":"#keys.client_id#",
                                "client_secret":"#keys.client_secret#",
                                "refresh_token":"#keys.refresh_token#"}'/>
        <cfhttp method="POST" url="https://api.amazon.com/auth/o2/token">
            <cfhttpparam type="header" name="Content-type" value="application/json">
            <cfhttpparam type="body" value="#requestBody#" />
        </cfhttp>
        <cfreturn deserializeJSON(cfhttp.filecontent)>
    </cffunction>

    <!---------------------------------------------------------------------->
    <!--- Amazon Signature V4 Related Functions to create valid request ---->
    <!---------------------------------------------------------------------->
    <cffunction name="createCanonical" access="private" returnType="string" output="false" hint="Create the canonical request">
        <cfargument name="strHTTPRequestMethod"        type="string"    required="true"                 />
        <cfargument name="strCanonicalURI"            type="string"    required="true"                 />
        <cfargument name="strCanonicalQueryString"    type="string"    required="false"    default=""    />
        <cfargument name="arrCanonicalHeaders"         type="array"    required="true"                    />
        <cfargument name="arrSignedHeaders"            type="array"    required="true"                    />
        <cfargument name="strPayload"                type="string"    required="false"    default=""    />
        
        <cfscript>
            var intCount            = 0;
            var strHeaderString     = "";
            var strNewLine          = Chr(10);
            var strCanonicalRequest = 
                arguments.strHTTPRequestMethod&strNewLine&arguments.strCanonicalURI&strNewLine&arguments.strCanonicalQueryString&strNewLine;            
            //Headers
            for(intCount=1; intCount <= arraylen(arrCanonicalHeaders); intCount++){
                strCanonicalRequest &=arguments.arrCanonicalHeaders[intCount] & strNewLine;
            }
            strCanonicalRequest &=strNewLine;            
            //Signed headers
            for(intCount=1; intCount <= arraylen(arrSignedHeaders); intCount++){
                strHeaderString        = arguments.arrSignedHeaders[intCount];
                strCanonicalRequest    &= strHeaderString;                
                //put a semi-colon between headers, or a new line at end
                if(intCount EQ arraylen(arrSignedHeaders)){
                    strCanonicalRequest    &= strNewLine;
                }else{
                    strCanonicalRequest    &= ";";
                }
            }            
            strCanonicalRequest    &= lcase(hash(arguments.strPayload, "SHA-256"));   
            return trim(strCanonicalRequest);
        </cfscript>
    </cffunction>

    <cffunction name="createStringToSign" access="public" returnType="string" output="false" hint="I create the string to sign">
        <cfargument name="strAlgorithm"            type="string" required="true" />
        <cfargument name="strRequestDate"        type="string" required="true" />
        <cfargument name="strCredentialScope"    type="string" required="true" />
        <cfargument name="strCanonicalRequest"    type="string" required="true" />
        
        <cfscript>
            var strNewLine = Chr(10);
            var strStringToSign  = arguments.strAlgorithm&strNewLine&arguments.strRequestDate&strNewLine&arguments.strCredentialScope&strNewLine&lcase(hash(arguments.strCanonicalRequest, "SHA-256"));
            return trim(strStringToSign);
        </cfscript>
    </cffunction>

    <cffunction name="createSigningKey" access="public" returnType="binary" output="false" hint="THIS WORKS DO NOT FUCK WITH IT.">
        <cfargument name="keys" required="true" type="struct" hint="struct with keys from DB">
        <cfargument name="dateStamp"    type="string"    required="true" />
        <cfargument name="regionName"    type="string"    required="true" />
        <cfargument name="serviceName"    type="string"    required="true" />
        <cfscript>        
            var kSecret = "AWS4" & arguments.keys.strSecretKey;
            var kDate   = HMAC_SHA256(arguments.dateStamp, kSecret);
            var kRegion = HMAC_SHA256(arguments.regionName, kDate);
            var kService = HMAC_SHA256(arguments.serviceName, kRegion);
            var kSigning = HMAC_SHA256("aws4_request", kService);
            return kSigning;
        </cfscript>
    </cffunction>

    <!----------------------------------------------------------------------->
    <!---- Helper tools to format date for AWS Signature (do not modify) ---->
    <!----------------------------------------------------------------------->
    <cffunction name="getCanonicalDateFormat" access="private" returnType="string" output="false" hint="I return a formatted date time for the canonical part of the process">
        <cfargument name="dteNow"    type="date"    required="true" />
        <cfreturn "#dateformat(arguments.dteNow, 'yyyymmdd')#T#TimeFormat(arguments.dteNow, 'HHnnss')#Z" />
    </cffunction>

    <cffunction name="getShortDateFormat" access="private" returnType="string" output="false" hint="I return a short date time">
        <cfargument name="dteNow"    type="date"    required="true" />        
        <cfreturn "#dateformat(arguments.dteNow, 'yyyymmdd')#" />
    </cffunction>

    <!----------------------------------------------------------------------->
    <!---- Encryption Related Functions for AWS Signature (do not modify) --->
    <!----------------------------------------------------------------------->
    <cffunction name="HMAC_SHA256" returntype="any" access="public" output="true" hint="Calculates hash message authentication code using SHA256 algorithm.">
        <cfargument name="Data" type="string" required="true" />
        <cfargument name="Key" type="any" required="true" />

        <cfset hmacHex = lcase(hmac(arguments.data,arguments.key,"HMACSHA256")) />
        <cfset charset = BinaryDecode(hmacHex, "hex") />
        <cfreturn charset />
    </cffunction>
    
</cfcomponent>
