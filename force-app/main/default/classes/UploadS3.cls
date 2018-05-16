public with sharing class UploadS3 {

    private String region;
    private String bucket;
    private String folder;
    private String ACCESS_KEY;
    private String SECRET_KEY;
    private final string BASE_URL= 'https://s3.amazonaws.com';
    private final string service= 's3';


    public UploadS3(){
        this('default');
    }

    public UploadS3(String CustomSettingName){
        String setting='default';

        if (!String.isBlank(CustomSettingName)) setting=CustomSettingName;
        AmazonS3__mdt[] s3 =[SELECT label,	DeveloperName, AccessKey__c, SecretKey__c, bucket__c, folder__c, region__c 
                             FROM AmazonS3__mdt 
                             WHERE DeveloperName=:setting];
         if (s3!=NULL || !s3.isEmpty()){
            System.debug('s3');
            this.region = s3[0].region__c;
            this.bucket=s3[0].bucket__c;
            this.folder=s3[0].folder__c;
            this.ACCESS_KEY=s3[0].AccessKey__c;
            this.SECRET_KEY=s3[0].SecretKey__c;
        }
        else System.debug('Custom Setting for AmzonS3 cannot be empty. Set a \'default\' record to begin with.' );
    }

    public ContentVersion getContentVersion(){
         List<ContentVersion> cvList = [SELECT id , Title, versionData, contentSize, fileType from ContentVersion LIMIT 1];
         return cvList[0];
    }

    public void uploadFileToS3(){
        String formattedDateString = Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss z');
        //String key = this.ACCESS_KEY;
        //String secret = this.SECRET_KEY;
            String key = 'AKIAJN2L6E4XTZDX5B7Q';
    String secret = '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';
        String bucketname = this.bucket;
        String folder = this.folder;
        String host = 's3.amazonaws.com';
        String method = 'PUT';
        ContentVersion cv = getContentVersion();
        String filename = cv.Id + '-' + cv.Title;
        String attachmentBody = EncodingUtil.base64Encode(cv.versionData);
        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        req.setEndpoint('https://' + bucketname + '.' + host + '/' + folder + '/' + filename);
        req.setHeader('Host', bucketname + '.' + host);
        req.setHeader('Content-Length', String.valueOf(attachmentBody.length()));
        req.setHeader('Content-Encoding', 'UTF-8');
        req.setHeader('Content-type', 'application/pdf');
        req.setHeader('Connection', 'keep-alive');
        req.setHeader('Date', formattedDateString);
        req.setHeader('ACL', 'public-read');
        req.setBody(attachmentBody);
        String stringToSign = 'PUT\n\n' +
            cv.FileType + '\n' +
            formattedDateString + '\n' +
            '/' + bucketname + '/' + bucketname + '/' + filename;

        String encodedStringToSign = EncodingUtil.urlEncode(stringToSign, 'UTF-8');
        Blob mac = Crypto.generateMac('HMACSHA1', blob.valueof(stringToSign),blob.valueof(secret));
        String signed = EncodingUtil.base64Encode(mac);
        String authHeader = 'AWS' + ' ' + key + ':' + signed;
        req.setHeader('Authorization',authHeader);
        String decoded = EncodingUtil.urlDecode(encodedStringToSign , 'UTF-8');

        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('*Resp:' + String.ValueOF(res.getBody()));
        System.debug('RESPONSE STRING: ' + res.toString());
        System.debug('RESPONSE STATUS: ' + res.getStatus());
        System.debug('STATUS_CODE: ' + res.getStatusCode());
   }

   //method to use the S3 webservice and save pdf file
  public void saveToS3(){
        /*  Input Variable Explanations
        binaryPDF -- this is a base64 Encoded binary string representation of a PDF I get from a different web service
        docName --  any name you want to use as the saved document name
        bucketname --  the Amazon S3 bucket you are saving to
        method --  I currently only use PUT
        contentType --  I leave this blank and it seems to work fine
        region --  !!!Important, this needs to be the region that the S3 bucket is set to, for example '-us-west-2'
        key --  this is the key you generate in the AWS console under Identity & Access Management for the user account setup to access the S3 bucket
        secret --  this is the secret you generate during the same process
        */

        //setup variables
        String formattedDateString = Datetime.now().format('EEE, dd MMM yyyy HH:mm:ss z','America/Denver');    //this is needed for the PUT operation and the generation of the signature.  I use my local time zone.
        ContentVersion cv = getContentVersion();
        String filename = cv.Id + '-' + cv.Title;
        String method='PUT';
        String contentType='';
        String docName= cv.Title + '-' + cv.id;
        HttpRequest req = new HttpRequest();
        Http http = new Http();
        Blob binaryPDF=cv.versionData;
        filename = folder +    //Include any folders and subfolders you are using in your S3 Bucket
            docName.replace(' ', '+') + '.pdf';   //this replaces any spaces in the desired document name with a Plus symbol '+', as the filename needs to be URL friendly
        
        req.setHeader('Content-Type', contentType);
        req.setMethod(method);
        req.setHeader('Host',bucket + '.s3-' + region + '.amazonaws.com');  //path style
        req.setEndpoint('https://' + bucket + '.s3-' + region + '.s3.amazonaws.com' + '/'+ bucket + '/' + filename);   //path style
        req.setHeader('Date', formattedDateString);
        req.setHeader('Authorization',createAuthHeader(method,contentType,filename,formattedDateString,bucket,ACCESS_KEY,SECRET_KEY));
        
        if(binaryPDF != null && binaryPDF.size() > 0){
            //Blob pdfBlob = EncodingUtil.base64Decode(binaryPDF);
            req.setBodyAsBlob(binaryPDF);
            req.setHeader('Content-Length', string.valueOf(binaryPDF.size()));
            
            //Execute web service call
            try {
                HTTPResponse res = http.send(req);
                System.debug('MYDEBUG: ' + docName + ' RESPONSE STRING: ' + res.toString());
                System.debug('MYDEBUG: ' + docName + ' RESPONSE STATUS: '+res.getStatus());
                System.debug('MYDEBUG: ' + docName + ' STATUS_CODE:'+res.getStatusCode());
                
            } catch(System.CalloutException e) {
                system.debug('MYDEBUG: AWS Service Callout Exception on ' + docName + 'ERROR: ' + e.getMessage());
            }
        }
    }
    
    //create authorization header for Amazon S3 REST API
    public string createAuthHeader(String method,String contentType,String filename,String formattedDateString,String bucket,String key,String secret){
        string auth;
        String stringToSign = method+'\n\n'+contentType+'\n'+formattedDateString+'\n/'+bucket+'/'+filename;
        Blob mac = Crypto.generateMac('HMACSHA1', blob.valueof(stringToSign),blob.valueof(secret));
        String sig = EncodingUtil.base64Encode(mac);
        auth = 'AWS' + ' ' + key + ':' + sig;
        return auth;
    }

  public void saveAttachment(){
        ContentVersion attach = [
        SELECT id , Title, versionData, contentSize, fileType from ContentVersion LIMIT 1
        ];

    String attachmentBody = EncodingUtil.base64Encode(attach.versionData);
    String formattedDateString = Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss z');
    
    String key = 'AKIAJBD3UCZAHLZ4APMQ';
    String secret = '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';
    String bucketname = 'mybucket-salesforce';
    String host = 's3-us-west-1.amazonaws.com';
    String method = 'PUT';
    String filename = attach.Id + '-' + attach.Title;

    HttpRequest req = new HttpRequest();
    req.setMethod(method);
    req.setEndpoint('https://' + bucketname + '.' + host + '/' + bucketname + '/' + filename);
    req.setHeader('Host', bucketname + '.' + host);
    req.setHeader('Content-Length', String.valueOf(attachmentBody.length()));
    req.setHeader('Content-Encoding', 'UTF-8');
    req.setHeader('Content-type', 'application/pdf');
    req.setHeader('Connection', 'keep-alive');
    req.setHeader('Date', formattedDateString);
    req.setHeader('ACL', 'public-read');
    req.setBody(attachmentBody);
    String stringToSign = 'PUT\n\n' +
        attach.FileType + '\n' +
        formattedDateString + '\n' +
        '/' + bucketname + '/' + bucketname + '/' + filename;

    String encodedStringToSign = EncodingUtil.urlEncode(stringToSign, 'UTF-8');
    Blob mac = Crypto.generateMac('HMACSHA1', blob.valueof(stringToSign),blob.valueof(secret));
    String signed = EncodingUtil.base64Encode(mac);
    String authHeader = 'AWS' + ' ' + key + ':' + signed;
    req.setHeader('Authorization',authHeader);
    String decoded = EncodingUtil.urlDecode(encodedStringToSign , 'UTF-8');

    Http http = new Http();
    HTTPResponse res = http.send(req);
    System.debug('*Resp:' + String.ValueOF(res.getBody()));
    System.debug('RESPONSE STRING: ' + res.toString());
    System.debug('RESPONSE STATUS: ' + res.getStatus());
    System.debug('STATUS_CODE: ' + res.getStatusCode());
   }
}