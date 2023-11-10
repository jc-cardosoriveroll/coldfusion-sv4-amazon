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
https://developer-docs.amazon.com/sp-api/docs/sellers-api-v1-reference##getmarketplaceparticipations
data = deserializeJSON(postRequest(keys=arguments.keys,path="sellers/v1/marketplaceParticipations"));

keys = {}
