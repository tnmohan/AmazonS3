public with sharing class UploadS3 {
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
    req.setHeader('Content-type', attach.FileType);
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