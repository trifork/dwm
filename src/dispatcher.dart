/**
 * Copyright (c) 2011 by Trifork
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

#library('dart-webmachine-dispatcher');
#import('../dlib/utils.dart');
#import('../dlib/http.dart');

class MatchSpec {

    var _matchers, _lastmatcher;
    var _value;

    get value() => _value;

    MatchSpec(String spec, this._value) { 

	if (spec.length < 1 || spec[0] != '/') {
	    throw new IllegalArgumentException(spec);
	}

	List<String> parts = spec.substring(1).split('/');
	_matchers = [];
	
	if (parts.length > 0) {
	    for (int i = 0; i < parts.length-1; i++) {
		_matchers.add( _get_matcher(parts[i]) );
	    }

	    _lastmatcher = _get_matcher(parts[parts.length-1]);
	} else {
	    _lastmatcher = null;
	}
    }


    static _get_matcher(String spec) {

	if ('*' == spec) {
	    return (tok,map) => true;
	    
	} else if (spec.length>0 && spec[0] == @'$') {
	    var name = spec.substring(1);
	    return (tok,map) { map[name]=tok; return true; } ;
	    
	} else {
	    return (tok,map) => (tok==spec);
	}
    }

    Map<String,String> match(String path) {
	assert (path.length>0 && path[0] == '/');
	return _match(path.substring(1).split('/'), path);
    }
    
    Map<String,String> _match(List<String> tokens, String full_path)
    {
	int rest_pos = 1;
	Map<String,String> parms = new Map<String,String>();
	int pos = 0;
	for(; pos < _matchers.length; pos++) {
	    var m = _matchers[pos];
	    var tok = tokens[pos];

	    if ( m(tok, parms) == false ) {
		return null;
	    }

	    rest_pos += (1 + tok.length);
	}
	
	if (_lastmatcher != null) {
	    int toklen = tokens.length;
	    String rest = full_path.substring(rest_pos);

	    if (_lastmatcher(rest, parms) == false) {
		return null;
	    } 

	}

	return parms;
    }

    static Map _match_path(String path, Collection<MatchSpec> specs)
    {
	assert (path.length>0 && path[0] == '/');
	var tokens = path.substring(1).split('/');
	for(var spec in specs) {
	    var bindings = spec._match(tokens, path);
	    if (bindings != null) {
		return {'value':spec.value, 'bindings':bindings};
	    }
	}

	return null;
    }
}

interface HTTPInvocation factory HTTPInvocationImpl {
    HTTPInvocation(HTTPRequest req,HTTPResponse resp);

    HTTPRequest get request();
    HTTPResponse get response();
}

class HTTPInvocationImpl implements HTTPInvocation {
    HTTPRequest _request;
    HTTPResponse _response;

    HTTPRequest get request() => _request;
    HTTPResponse get response() => _response;

    HTTPInvocationImpl(HTTPRequest this._request,
		       HTTPResponse this._response);

    factory HTTPInvocation(HTTPRequest req, HTTPResponse resp) {
	return new HTTPInvocationImpl(req,resp);
    }
}

typedef void http_handler(HTTPInvocation inv);

class _HTTPInvocationImpl2 extends HTTPInvocationImpl {

    Map<String,String> _pathBindings;

    Map<String,String> get pathBindings() => _pathBindings;

    _HTTPInvocationImpl2(HTTPInvocation inv, Map<String,String> bindings) 
	: super(inv.request, inv.response) {
	    this._pathBindings = bindings;
	}
}

class HTTPDispatcher {
      
    var _specs;
    http_handler notFoundHandler;

    HTTPDispatcher() {
	_specs = [];
	notFoundHandler = (HTTPInvocation inv) {
	    inv.response.resultCode = HTTPStatus.NOT_FOUND;
	    inv.response.writeDone();
	};
    }

    add(String spec, http_handler handler) {
	_specs.add (new MatchSpec(spec, handler));
    }     
    
    dispatch(HTTPInvocation inv) {
	HTTPRequest req = inv.request;
	String path = req.path;
	var found = MatchSpec._match_path( path, _specs );
	
	if (found == null) {
	    notFoundHandler(req,resp);
	} else {
	    http_handler handler = found['value'];
	    Map<String,String> bindings = found['bindings'];
	    handler(new _HTTPInvocationImpl2(inv, bindings));
	}
    }

    dispatch2(HTTPRequest req, HTTPResponse resp) {
	return dispatch(new HTTPInvocation(req,resp));
    }
}


