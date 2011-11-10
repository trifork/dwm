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

#library('dart-webmachine-resource');
#import('../dlib/utils.dart');
#import('../dlib/utf8.dart');

class WMResource {

    /** test if the resource is avaible */
    bool get available() => true;

    /** known methods */
    Collection<String> get knownMethods() => DEFAULT_KNOWN_METHODS;

    static Set<String> _default_known_methods;
    static Set<String> get DEFAULT_KNOWN_METHODS() {
	if (_default_known_methods == null) {
	    _default_known_methods =
		new Set.from(const ['GET', 'HEAD', 'POST', 'PUT',
				'DELETE', 'TRACE', 'CONNECT', 'OPTIONS']);
	}
	return _default_known_methods;
    }

    /** Return the maximum allowed length of a URI (or -1 if no such limit applies) */
    int get maxURILength() => -1;

    /** allowed methods */
    Set<String> get allowedMethods() => DEFAULT_ALLOWED_METHODS;

    static Set<String> _default_allowed_methods;
    static get DEFAULT_ALLOWED_METHODS() {
	if (_default_allowed_methods == null) {
	    _default_allowed_methods = new Set.from(const ['GET', 'HEAD']);
	}
	return _default_allowed_methods;
    }

    bool get isMalformed() => false;

    /** call one of the three methods on the WMAuthenticate interface, or
     *  none if no authentication is needed. */
    void authenticate(WMAuthenticate auth) => null;

    /** return true if this invocation is forbidden */
    bool get forbidden() => false;

    Map get providedContentTypes() => {'text/html': this.toHTML};

    Map get acceptedContentTypes() => const {};

    Map get providedCharsets() => {
        'UTF8'       : (string) => UTF8Encoder.encodeString(string),
        // 'ISO-8859-1' : (string) => string.charCodes(),
      };

    Map get providedEncodings() => {'identity' : (v)=>v};

    Map get providedLanguages() => null;

    List get variances() => const [];

    bool get isConflict() => false;

    bool get multipleChoises() => false;

    bool get previouslyExisted() => false;

    String get movedPermanently() => false;
    String get movedTemporarily() => false;

    bool get postIsCreate() => false;
    String createPath() => null;

    bool get exists() => true;

    String baseURI() => null;

    String get etag() => null;
    Date get expires() => null;
    Date get lastModified() => null;

    abstract String toHTML();

    void finishRequest() {}
    void stop() {}
}


interface WMAuthenticate {
    
    respond(int code, [String message]);
    respondError(String reason, [int code, String message]);
    respondAuthenticate(String authHeader);

}

