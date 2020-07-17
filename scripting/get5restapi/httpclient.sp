#define MAX_URL_LEN 1024
#define MAX_KEY_LEN 128
#define MAX_JSONSTR_LEN 4096

char g_APIURL[MAX_URL_LEN];
char g_APIKey[MAX_KEY_LEN];
public HTTPClient g_HTTPClient;
HTTPRequestCallback _TestHTTPRequestCallback;

public void LogJson(JSONObject json) {
    char jsonStr[MAX_JSONSTR_LEN];
    json.ToString(jsonStr, MAX_JSONSTR_LEN, JSON_INDENT(2));
    LogDebug("JSON data: '%s'", jsonStr);
}

public void CreateHTTPClient() {
    if (g_HTTPClient != null) { delete g_HTTPClient; }

    g_HTTPClient = new HTTPClient(g_APIURL);
    g_HTTPClient.SetHeader("Authorization", g_APIKey);
}

public void _SetTestHTTPRequestCallback(HTTPRequestCallback callback) {
    _TestHTTPRequestCallback = callback;
}

public void ApiUrlChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    convar.GetString(g_APIURL, sizeof(g_APIURL));

    CreateHTTPClient();

    LogDebug("New base URL: %s [old value: '%s'] (API key: '%s')", g_APIURL, oldValue, g_APIKey);
}

public void ApiKeyChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    convar.GetString(g_APIKey, sizeof(g_APIKey));

    if (g_HTTPClient != null) {
        g_HTTPClient.SetHeader("key", g_APIKey);
    } else {
        LogError("No base URL defined!");
    }

    LogDebug("New API key: '%s' [old value: '%s']", g_APIKey, oldValue);
}

static void SetCvarString(JSONObject json, const char[] convarName, const char[] jsonKeyName="") {
    char cvarString[MAX_JSONSTR_LEN];
    ConVar convar = FindConVar(convarName);
    if (convar == null)
        return;
    convar.GetString(cvarString, sizeof(cvarString));
    delete convar;
    if (StrEqual(jsonKeyName, ""))
        json.SetString(convarName, cvarString);
    else
        json.SetString(jsonKeyName, cvarString);
}

public void RegisterServerWithRestApi() {
    JSONObject params = new JSONObject();
    SetCvarString(params, "hostport", "port");
    SetCvarString(params, "ip");
    SetCvarString(params, "hostname");
    SetCvarString(params, "rcon_password");
    SetCvarString(params, "get5_version");

    MakePostRequestWithCallback(RegisterCallback, params, "register");
}

public void RegisterCallback(HTTPResponse response, any value, const char[] error) {
    if(!CheckResponse(response, error, "Register request failed")) {
        LogError("Unable to register with REST API...");
        return;
    }
    JSONObject json = view_as<JSONObject>(response.Data);
    LogJson(json);
    if (json.HasKey("match")) {
        JSONObject matchJson = view_as<JSONObject>(json.Get("match"));
        matchJson.ToFile("get5_restapi_match.json");
        Get5_LoadMatchConfig("get5_restapi_match.json");
        delete matchJson;
    }
    delete json;
}

public void _MakeTestPostRequest(JSONObject json, int testCaseNum) {
    LogDebug("Test POST request (%d)", testCaseNum);
    LogJson(json);

    g_HTTPClient.Post("test", json, _TestHTTPRequestCallback, testCaseNum);
    delete json;
}

public void MakePostRequest(JSONObject json, const char[] urlfmt, any:...) {
    /* We need to do VFormat here, since I'm too lazy to do native with ... support */
    char formattedURL[MAX_URL_LEN];
    VFormat(formattedURL, MAX_URL_LEN, urlfmt, 3);
    MakePostRequestWithCallback(RequestCallback, json, urlfmt);
}

public void MakePostRequestWithCallback(
    HTTPRequestCallback callback, JSONObject json, const char[] urlfmt, any:...) {

    char formattedURL[MAX_URL_LEN];
    VFormat(formattedURL, MAX_URL_LEN, urlfmt, 3);
    LogDebug("POST request to %s", formattedURL);
    LogJson(json);

    g_HTTPClient.Post(formattedURL, json, callback);
    delete json;
}

static bool CheckResponse(HTTPResponse response, const char[] error, const char[] msg) {
    if (response.Status != HTTPStatus_OK || response.Data == null) {
        LogError("API request failed! %s%sHTTP status code: %d%s%s",
                msg, StrEqual(msg, "") ? "" : "\n", response.Status,
                StrEqual(error, "") ? "" : "\n", error);
        return false;
    }
    return true;
}

public void RequestCallback(HTTPResponse response, any value, const char[] error) {
    CheckResponse(response, error, "");
}
