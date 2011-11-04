

#import('dispatcher.dart');

class DummyReq {
    var path;
    DummyReq(String this.path);
}

class DummyResp {
    var resultCode;
    var contentLength;
    writeDone() {}
}

main() {
    
    var disp = new HTTPDispatcher();

    disp.add(@'/person/$id', (HTTPInvocation inv) {
	    print("getting person ${inv.pathBindings['id']}");
	});
    disp.add(@'/*', handlerForDir("/tmp"));

    disp.dispatch2( new DummyReq("/person/4"), new DummyResp());
    disp.dispatch2( new DummyReq("/x/../person/4/.."), new DummyResp());

}