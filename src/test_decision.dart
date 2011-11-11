

#import('decision.dart');
#import('resource.dart');
#import('../dlib/json/dart_json.dart');

class DummyReq {
    var method, path, headers;
    DummyReq(this.method, this.path, this.headers);
}

class DummyResp {
    var statusCode;
    var contentLength;
    var headers;

    StringBuffer reply;

    DummyResp() : headers = new Map(), reply = new StringBuffer() ;

    writeList(list,start,len,[then=null]) {
        var actual = list.getRange(start,len);
        reply.add( new String.fromCharCodes(actual) );
        if (then != null) {
            then();
        }
    }

    writeDone() {
        print("did receive\n----${JSON.stringify(headers)}\n----\n$reply\n----");
    }

    setHeader(k,v) { headers[k] = v; }
}

class DummyRes extends WMResource {
    String toHTML() => '<html><body>HELLO!</body></html>';
}

main() {

    DummyReq req = new DummyReq('HEAD', '/a/b/c', {});
    DummyResp resp = new DummyResp();
    DummyRes resource = new DummyRes();

    WMRequest r;

    r = new WMRequest(resource, req, resp, {}, baseURI:'http://foobar.com/');
    r.execute();

    r = new WMRequest(resource, req, resp, {}, baseURI:'http://foobar.com/');
    r.execute();

}