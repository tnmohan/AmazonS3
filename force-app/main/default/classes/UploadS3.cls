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
        String key = this.ACCESS_KEY;
        String secret = this.SECRET_KEY;
        String bucketname = this.bucket;
        String folder = this.folder;
        String host = 's3-us-west-1.amazonaws.com';
        String method = 'PUT';
        ContentVersion cv = getContentVersion();
        String filename = cv.Id + '-' + cv.Title;
        String attachmentBody = EncodingUtil.base64Encode(cv.versionData);
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

  public void saveAttachment(){
        ContentVersion attach = [
        SELECT id , Title, versionData, contentSize, fileType from ContentVersion LIMIT 1
        ];

    String attachmentBody = EncodingUtil.base64Encode(attach.versionData);
    String formattedDateString = Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss z');
    
    String key = 'AKIAIPOJF5R4FE6YB5VQ';
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