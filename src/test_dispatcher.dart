

#import('dispatcher.dart');

class DummyReq {
    var path;
    DummyReq(String this.path);
}

class DummyResp {
    var resultCode;
}

main() {
    
    var disp = new HTTPDispatcher();

    disp.add(@'/person/$id', (HTTPInvocation inv) {
	    print("getting person ${inv.pathBindings['id']}");
	});
    disp.add(@'/*', handlerForDir("/tmp"));

    disp.dispatch2( new DummyReq("/person/4"), new DummyResp());

}