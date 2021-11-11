import ballerina/http;
import ballerina/test;

final http:Client defaultRequestInterceptorClientEP = check new("http://localhost:" + defaultRequestInterceptorTestPort.toString());

listener http:Listener defaultRequestInterceptorServerEP = new(defaultRequestInterceptorTestPort, config = {
        interceptors : [new DefaultRequestInterceptor(), new LastRequestInterceptor()]
    });

service / on defaultRequestInterceptorServerEP {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-interceptor", check req.getHeader("default-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{}
function testDefaultRequestInterceptor() returns error? {
    http:Response res = check defaultRequestInterceptorClientEP->get("/");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-interceptor");
    assertHeaderValue(check res.getHeader("default-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check defaultRequestInterceptorClientEP->post("/", "testMessage");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-interceptor");
    assertHeaderValue(check res.getHeader("default-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}

final http:Client requestInterceptorReturnsErrorClientEP = check new("http://localhost:" + requestInterceptorReturnsErrorTestPort.toString());

listener http:Listener requestInterceptorReturnsErrorServerEP = new(requestInterceptorReturnsErrorTestPort, config = {
        interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorReturnsError(), new LastRequestInterceptor()]
    });

service / on requestInterceptorReturnsErrorServerEP {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testrequestInterceptorReturnsError() returns error? {
    http:Response res = check requestInterceptorReturnsErrorClientEP->get("/");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "Request interceptor returns an error");
}

final http:Client requestErrorInterceptorClientEP = check new("http://localhost:" + requestErrorInterceptorTestPort.toString());

listener http:Listener requestErrorInterceptorServerEP = new(requestErrorInterceptorTestPort, config = {
        interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorReturnsError(), new DefaultRequestErrorInterceptor(), new LastRequestInterceptor()]
    });

service / on requestErrorInterceptorServerEP {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-interceptor", check req.getHeader("default-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        res.setHeader("request-interceptor-error", check req.getHeader("request-interceptor-error"));
        res.setHeader("default-error-interceptor", check req.getHeader("default-error-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestErrorInterceptor() returns error? {
    http:Response res = check requestErrorInterceptorClientEP->get("/");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-error-interceptor");
    assertHeaderValue(check res.getHeader("default-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor-error"), "true");
    assertHeaderValue(check res.getHeader("default-error-interceptor"), "true");
}

final http:Client requestInterceptorSetPayloadClientEP = check new("http://localhost:" + requestInterceptorSetPayloadTestPort.toString());

listener http:Listener requestInterceptorSetPayloadServerEP = new(requestInterceptorSetPayloadTestPort, config = {
        interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorSetPayload(), new LastRequestInterceptor()]
    });

service / on requestInterceptorSetPayloadServerEP {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setTextPayload(check req.getTextPayload());
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-interceptor", check req.getHeader("default-interceptor"));
        res.setHeader("interceptor-setpayload", check req.getHeader("interceptor-setpayload"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestInterceptorSetPayload() returns error? {
    http:Request req = new();
    req.setHeader("interceptor", "databinding-interceptor");
    req.setTextPayload("Request from Client");
    http:Response res = check requestInterceptorSetPayloadClientEP->post("/", req);
    assertTextPayload(check res.getTextPayload(), "Text payload from interceptor");
    assertHeaderValue(check res.getHeader("last-interceptor"), "interceptor-setpayload");
    assertHeaderValue(check res.getHeader("default-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("interceptor-setpayload"), "true");
}
