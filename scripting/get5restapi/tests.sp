JSONArray testCases;

public Action Command_Test(int args) {
    Setup();
    test_PostRequestSimple();
    test_PostRequestWithJson();

    return Plugin_Handled;
}

static void Setup() {
    if (strcmp(g_APIURL, "") == 0) {
        SetConVarString(g_APIURLCvar, "http://127.0.0.1:5000", true, true);
    }
    SetConVarString(g_APIKeyCvar, "test_api_key", true, true);
    _SetTestHTTPRequestCallback(TestHttpCallback);

    testCases = new JSONArray();
}

public void TestHttpCallback(HTTPResponse response, any value) {
    char testCase[64];
    testCases.GetString(view_as<int>(value), testCase, 64);
    SetTestContext(testCase);
    AssertEq("HTTP Ok", view_as<int>(response.Status), view_as<int>(HTTPStatus_OK));
}

static bool test_PostRequestSimple() {
    char testCaseName[] = "test_PostRequestSimple";
    SetTestContext(testCaseName);
    testCases.PushString(testCaseName);
    int testCaseNum = testCases.Length - 1;

    JSONObject json = new JSONObject();
    _MakeTestPostRequest(json, testCaseNum);
}

static bool test_PostRequestWithJson() {
    char testCaseName[] = "test_PostRequestWithJson";
    SetTestContext(testCaseName);
    testCases.PushString(testCaseName);
    int testCaseNum = testCases.Length - 1;

    JSONObject json = new JSONObject();
    json.SetBool("test", true);
    json.SetString("api_url", g_APIURL);
    json.SetString("api_key", g_APIKey);
    json.SetInt("test_case_num", testCaseNum);
    json.SetString("test_case", testCaseName);
    char jsonStr[512];
    json.ToString(jsonStr, 512);
    LogDebug("JSON DATA %s", jsonStr);

    _MakeTestPostRequest(json, testCaseNum);
}
