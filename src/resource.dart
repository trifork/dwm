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
    Collection<String> get knownMethods() =>
        const ['GET', 'HEAD', 'POST', 'PUT',
               'DELETE', 'TRACE', 'CONNECT', 'OPTIONS'];

    /** Return the maximum allowed length of a URI (or -1 if no such limit applies) */
    int get maxURILength() => -1;

    /** allowed methods */
    Collection<String> get allowedMethods() => const ['GET', 'HEAD'];

    bool get isMalformed() => false;

    /** call one of the three methods on the WMAuthenticate interface, or
     *  none if no authentication is needed. */
    void doAuthenticate(WMAuthenticate auth) {}

    /** return true if this invocation is forbidden */
    bool get forbidden() => false;

    Map get providedContentTypes() => {'text/html': ()=>this.toHTML() };

    Map get providedCharsets() => {
        'UTF8'       : (string) => UTF8Encoder.encodeString(string),
        // 'ISO-8859-1' : (string) => string.charCodes(),
      };

    Map get providedEncodings() => {'identity' : (v)=>v};

    Map get providedLanguages() => null;

    List get variances() => const [];

    /** does this resource exist */
    bool get exists() => true;

    /** operations on non-existing resource */

    Map get acceptedContentTypes() => const {};

    /** did this resource exist previously? */
    bool get previouslyExisted() => false;

    String get movedPermanently() => false;
    String get movedTemporarily() => false;

    bool get isConflict() => false;

    bool get allowMissingPOST() => false;

    bool get multipleChoises() => false;

    bool get postIsCreate() => false;
    String doCreatePath() => null;

    /* If post_is_create returns false, then this will be called to
     * process any POST requests. If it succeeds, it should return
     * true. */
    bool doProcessPOST() { return false; }

    String get baseURI() => null;

    String get etag() => null;
    Date get expires() => null;
    Date get lastModified() => null;

    abstract String toHTML();

    void doFinishRequest() {}
    void doStop() {}
}


interface WMAuthenticate {
    
    respond(int code, [String message]);
    respondError(String reason, [int code, String message]);
    respondAuthenticate(String authHeader);

}

