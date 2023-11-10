# coldfusion-sv4-amazon (Signature Version 4)
Implement Signature v4 without SDK for HTTP/API requests using Coldfusion

------

This Component was built to help connect with Amazon's Seller Central using SV4.
https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html
It is tested and working well. Used in fba.plus 

***********************************
https://FBA.plus (soon to be released)
"SAAS for managing customer messaging & order validation to connect with fulfilled by Amazon FBA's, Seller Central API's".
************************************


Examples -

*MarketplaceParticipations*
<br>https://developer-docs.amazon.com/sp-api/docs/sellers-api-v1-reference##getmarketplaceparticipations

<br>
<code>
  data = deserializeJSON(postRequest(keys=arguments.keys,path="sellers/v1/marketplaceParticipations"));
</code>
----
# sample key vars
<pre>
keys = {
"client_id" : "amzn1.application-oa2-clie...",
"client_secret" :	"1d26...",
"iam" :	"17...:user/w...",
"refresh_token" :	"Atzr...",
"seller_id" :	"A2L..",
"strPublicKey" :	"AKI...",
"strSecretKey" :	"dytsZa...",
"zone" :	"us-east-1"
}
</pre>
<hr>
<br>
(1) Defined in SC: seller_id, client_id, client_secret, refresh_token 
<br>
(2) Defined in AWS/IAM: IAM, PublicKey/SecretKey, Zone
