
#library('webmachine-decision-core');
#import('webmachine.dart', prefix:'WM');
#import('resource.dart');
#import('../dlib/http.dart');
#import('../dlib/utils.dart');

typedef _fun0();

class WMRequest implements WMAuthenticate {

    HTTPRequest _request;
    HTTPResponse _response;
    Map<String,String> _pathProps;
    Map<String,String> _replyHeaders;

    bool _did_respond = false;
    String _path, _baseURI;
    WMResource res;
    var _body;

    String _content_type;
    String _chosen_charset;
    String _chosen_encoding;

    static final DONE = const Object();

    //
    String get method() => _request.method;
    String get uri() => _request.uri;
    String get path() => _path;
    Map<String,String> get requestHeaders() => _request.headers;

    String get baseURI() => _baseURI;

    WMRequest(WMResource res, HTTPRequest request, HTTPResponse response, Map pathProps, [String baseURI=null])
    {
        this.res = res;
        _request = request;
        _response = response;
        _pathProps = pathProps;
        _replyHeaders = new Map<String,String>();
        _baseURI = baseURI;
        _path = request.path;

        if (_baseURI==null) {
            String host = requestHeaders['Host'];
            if (host != null) {
                _baseURI = "http://${host}";
            }
        }
    }

    set responseBody(body)
    {
        this._body = body;
    }

    setHeader(String hdr, String value) {
        _replyHeaders[hdr] = value;
    }

    respond(int code, [String message=null])
    {
        if (! _did_respond) {
            _response.statusCode = code;
            if (message != null) {
                _response.reasonPhrase = message;
            }
            _did_respond = true;

            if (code == 304) {
                _replyHeaders.remove('Content-Type');
                String etag = res.generateETag();
                if (etag != null) {
                    setHeader('ETag', '"$etag"');
                }
                Date expires = res.expires();
                if (expires != null) {
                    setHeader('Expires', _date_to_string(expires));
                }
            }

            res.finishRequest();

            for(var key in _replyHeaders.getKeys()) {
                _response.setHeader(key, _replyHeaders[key]);
            }

            _send_response(code);
        }
        return DONE;
    }

    static _date_to_string(Date date) =>
        date.changeTimeZone(const TimeZone.utc()).toString();

    _send_response(int code) {

        _response.statusCode = code;

        {
            var chunk = _body;
            if (chunk is String) {
                if (_chosen_charset != null) {
                    chunk = res.providedCharsets[_chosen_charset](chunk);
                } else {
                    chunk = chunk.charCodes();
                }
            }

            if (chunk is List<int>) {
                if (_chosen_encoding != null) {
                    chunk = res.providedEncodings[_chosen_encoding](chunk);
                }
                _response.contentLength = chunk.length;
                _response.writeList(chunk, 0, chunk.length);
                _response.writeDone();
                res.stop();
                return;
            }
        }

        if (chunk is ! _fun0) {
            _response.statusCode = 500;
            _response.writeDone();
            res.stop();
            return;
        }


        _writeBody();
    }

    _writeBody() {
        var chunk = _body();
        if (chunk == null) {
            _response.writeDone();
            res.stop();
            return;
        }

        if (chunk is String) {
            if (_chosen_charset != null) {
                chunk = res.providedCharsets[_chosen_charset](chunk);
            } else {
                chunk = chunk.charCodes();
            }
        }

        if (chunk is List<int>) {
            if (_chosen_encoding != null) {
                chunk = res.providedEncodings[_chosen_encoding](chunk);
            }
            _response.writeList(chunk, 0, chunk.length, _writeBody);
        } else {
            print("internal error: next chunk is $chunk");
            _response.writeDone();
            res.stop();
        }
    }



    respondError(String reason, [int code=500, String message=null])
    {
        String errorHTML = WM.errorHandler(code, this, reason);
        respond(code, message:message);
        setHeader('Content-Type', 'text/html;charset=UTF8');
        this.response = errorHTML;
        return respond(code, message:message);
    }

    respondAuthenticate(String authHeader)
    {
        setHeader('WWW-Authenticate', authHeader);
        return respond(401);
    }

    void execute()
    {
        decision();
    }

    state(str) {
        print("state: $str");
    }

    decision()
    {
        var tmp;

        state('B13');
        if (! res.available )
            return respond(503);

        state('B12');
        if (! res.knownMethods.contains(method) )
            return respond(501);

        state('B11');
        if ( res.maxURILength != -1 && res.maxURILength > uri.length )
            return respond(414);

        state('B10');
        if (! contains(tmp=res.allowedMethods, method )) {
            setHeader('Allow', Strings.join(toList(tmp), ', '));
            return respond(405);
        }

        state('B9');
        if ( res.isMalformed ) {
            return respond(400);
        }

        state('B8');
        res.authenticate(this);
        if (_did_respond)
            return DONE;

        state('B7');
        if (res.forbidden) {
            return respond(403);
        }

        // TODO: More checks here ...
        // B6, B5, B4, B3

        // Process Accept header [C3, C4]
        state('C3');
        {
            Map<String,Function> provided = res.providedContentTypes;
            String acceptHeader = requestHeaders['Accept'];
            if (acceptHeader == null) {
                _content_type = toList(provided.getKeys())[0];
            } else {
                state('C4');
                String mediaType = _choose_media_type(provided, acceptHeader);
                switch(true) {
                case mediaType==null:
                    return respond(406);
                case mediaType==DONE:
                    return DONE;
                case mediaType is String:
                    _content_type = mediaType;
                default:
                    return respondError("wrong media type (1)");
                }
            }
        }

        // process Accept-Language [D4, D5]
        state('D4');
        {
            String acceptHeader = requestHeaders['Accept-Language'];
            String language = _do_choose(res.providedLanguages,
                                         acceptHeader == null ? '*' : acceptHeader,
                                         isGood:(String pro, String req) {

                                             if (pro==req)
                                                 return true;

                                             int ri = req.indexOf('-');

                                             if (ri == -1)
                                                 return false;

                                             pro = pro.toLowerCase();
                                             req = req.toLowerCase();

                                             return pro.startsWith(req.substring(0,ri+1));
                                         });
            switch(true) {
            case language==null:
                if (acceptHeader != null) {
                    return respond(406);
                }
                break;
            case language is String:
                _chosen_language = language;
                break;
            default:
                return respondError("wrong language type (1)");
            }
        }

        // process Accept-Charset [E5, E6]
        state('E5');
        {
            String acceptHeader = requestHeaders['Accept-Charset'];
            String charset = _do_choose(res.providedCharsets,
                                        acceptHeader == null ? '*' : acceptHeader,
                                        defaultValue:"ISO-8859-1");
            switch(true) {
            case charset==null:
                if (acceptHeader != null) {
                    return respond(406);
                } else {
                    _chosen_charset = first(res.providedCharsets.getKeys());
                }

                break;

            case charset is String:
                _chosen_charset = charset;
                break;

            default:
                return respondError("wrong charset type (1)");
            }
        }

        if (_chosen_charset == null) {
            setHeader('Content-Type', _content_type);
        } else {
            setHeader('Content-Type', "${_content_type}; charset=${_chosen_charset}");
        }

        // process Accept-Encoding [E5, E6]
        state('F6');
        {
            String acceptHeader = requestHeaders['Accept-Encoding'];
            String encoding = _do_choose(res.providedEncodings,
                                         acceptHeader == null ? 'identity;q=1.0,*;q=0.5' : acceptHeader,
                                         defaultValue:'identity');
            switch(true) {
            case encoding==null:
                if (acceptHeader != null) {
                    return respond(406);
                }

            case encoding=='identity':
                break;

            case encoding is String:
                _chosen_encoding = encoding;
                setHeader('Content-Encoding', encoding);
                break;

            default:
                return respondError("wrong encoding type (1)");
            }
        }

        // compute the Vary header
        List<String> variances = _compute_variances();
        if (variances != null && variances.length > 0) {
            setHeader('Vary', Strings.join(variances, ', '));
        }

        state('G7');
        switch (tmp = res.exists) {
        case DONE:
            return DONE;
        case false:
            tmp = resource_not_exists();
            break;
        case true:
            tmp = resource_exists();
            break;
        default:
            print("Hmm, exists => $tmp");
            return respondError("bad exists value (1)");
        }

    }

    resource_exists() {
        state('G8');


        state('O18');

        String etag = res.etag;
        if (etag != null) {
            setHeader('ETag', '"$etag"');
        }
        Date lastMod = res.lastModified;
        if (lastMod != null) {
            setHeader('Last-Modified', _date_to_string(lastMod));
        }
        Date expires = res.expires;
        if (expires != null) {
            setHeader('Expires', _date_to_string(expires));
        }

        var bodyFun = res.providedContentTypes[_content_type];
        var body = bodyFun();
        if (_did_respond) {
            return DONE;
        }

        if (body != null) {
            this.responseBody = body;
        }

        if (res.multipleChoises()) {
            return respond(300);
        } else {
            return respond(200);
        }
    }

    resource_not_exists() {
        state('H7');

        String ifmatch = requestHeaders['If-Match'];
        if (ifmatch == '*')
            return respond(412);

        state('I7');

        if (method == 'PUT') {

            state('I4');

            if (_test_moved_permanently() == DONE)
                return DONE;

            state('P3');

            if (_test_conflict() == DONE)
                return DONE;

        } else {

            state('K7');

            if (res.previouslyExisted()) {

                state('K5');
                if (_test_moved_permanently() == DONE)
                    return DONE;

                state('L5');
                if (_test_moved_temporarily() == DONE)
                    return DONE;

                state('M5');
                if (method != 'POST') {
                    return respond(401);
                }

                state('N5');
                if (! res.allowMissingPOST()) {
                    return respond(401);
                }

            } else {

                state('L7');
                if (method != 'POST') {
                    return respond(404);
                }

                state('M7');
                if (! res.allowMissingPOST()) {
                    return respond(404);
                }

            }

            state('N11');

            if (res.postIsCreate()) {
                String new_path = res.createPath();
                if (new_path == DONE) { return DONE; }
                if (new_path == null) { return respondError("postIsCreate w/o createPath"); }

                String base_uri = res.baseURI();
                if (base_uri == null) {
                    base_uri = baseURI();
                } else {
                    if (base_uri.endsWith('/')) {
                        base_uri = base_uri.substring(0, base_uri.length-1);
                    }
                }
                String full_path = path + '/' + new_path;
                setHeader('Location', base_uri + full_path);
                _path = full_path;


            } else {
                var tmp = res.processPOST();
                if (tmp == DONE) {
                    return DONE;
                } else if (tmp =! true) {
                    return respondError("bad reply from processPOST");
                }
            }
        }

        state('P11');

        if (_replyHeaders['Location'] != null) {
            return respond(201); // created
        }

        state('O20');
        if (!_has_response_body()) {
            return response(204); // no content
        }

        state('O18');
        if (res.multipleChoises()) {
            return respond(300);
        } else {
            return respond(200);
        }
    }



    _test_conflict() {
        var conflict = res.isConflict();
        switch(conflict) {
        case DONE: return DONE;
        case true:
            return respond(409);
        default:
            return false;
        }
    }

    _test_moved_permanently() {
        var url;
        switch (url=res.movedPermanently()) {
        case DONE: return DONE;

        case false:
            return false;

        default:
            response.setHeader('Location', url);
            return respond(301);
        }
    }

    _test_moved_temporarily() {
        var url;
        switch (url=res.movedTemporarily()) {
        case DONE: return DONE;

        case false:
            return false;

        default:
            response.setHeader('Location', url);
            return respond(307);
        }
    }

    _vary(String key, List<String> res, Map map) {
        if (map != null && map.length >1)
            res.add(key);
    }

    List<String> _compute_variances() {
        List<String> result = [];

        _vary('Accept', result, res.providedContentTypes);
        _vary('Accept-Encoding', result, res.providedEncodings);
        _vary('Accept-Charset', result, res.providedCharsets);

        List variances = res.variances;
        if (variances != null) {
            result.addAll(variances);
        }

        return result;
    }

 

}


_do_choose(Map<String,Function> provided, String acceptHeader,
           [defaultValue=null,
            isGood=null]) {

    if (isGood == null) {
        isGood = (v1,v2)=> v1==v2 || v1.toLowerCase()==v2.toLowerCase;
    }

    if (provided==null || provided.isEmpty())
        return null;

    List<String> choises = provided.getKeys();
    List<_QVal> acceptable = acceptHeader == null ? [] : _QVal.decode(acceptHeader);

    List<double> defaultPrio = [];
    List<double> starPrio = [];

    if (acceptable != null) {
    for (var qval in acceptable) {
        if (qval.prio == 0.0) {
            choises = choises.filter((type) => !isGood(type, qval.type));
        } else {
            for (String choise in choises) {
                if (isGood(choise, qval.type)) {
                    return choise;
                }
            }
        }

        if(defaultValue != null && isGood(defaultValue,qval.type)) { defaultPrio.add(qval.prio); }
        if(qval.type=='*') { starPrio.add(qval.prio); }
    }
    }

    bool defaultOK =
        defaultPrio.length == 0
        ? ( (starPrio.length==1 && starPrio[0] == 0.0)
            ? false
            : true )
        : ( defaultPrio[0] == 0.0
            ? false
            : true );
    bool anyOK =
        starPrio.length == 0
        ? false
        : ( (starPrio.length==1 && starPrio[0] == 0.0)
            ? false
            : true);


    if (anyOK) {
        return choises[0];
    } else if (defaultOK) {
        if (choises.some((e)=>isGood(e,defaultValue)))
            return defaultValue;
        else
            return null;
    } else {
        return null;
    }
}


class _QVal {
    String type;
    Map parms;
    double prio;

    _QVal(this.type, this.parms, this.prio);

    static List<_QVal> decode(String header)
    {
        List<_QVal> out = [];

        if (header == null)
            return out;

        var vals = header.split(',');
        vals.forEach((String val) {
                List elms = map(val.split(';'), (s)=>s.trim());
                Map parms = null;
                String type=elms[0];
                double prio = 1.0;
                for (int i = 1; i < elms.length; i++) {
                    String e = elms[i];
                    int eq = e.indexOf('=');
                    if (eq != -1) {
                        String k = e.substring(0,eq).trim();
                        String v = e.substring(eq+1).trim();

                        if (k == 'q') {
                            prio = Math.parseDouble(v);
                        } else {
                            if (parms == null) { parms = new Map(); }
                            parms[k] = v;
                        }
                    }
                }

                out.add(new _QVal(type, parms, prio));
            });

        out.sort((q1, q2) => -(q1.prio).compareTo(q2.prio));
    }
}


//main() {
//    print( new Date.now().changeTimeZone(const TimeZone.utc()) .toString() );
//}