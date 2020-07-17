/**
 * =============================================================================
 * Get5 web API integration
 * Copyright (C) 2016. Sean Lewis.  All rights reserved.
 * =============================================================================
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "include/get5.inc"
#include "include/logdebug.inc"
#include <cstrike>
#include <sourcemod>
#include <testing>
#include <ripext>

#pragma semicolon 1
#pragma newdecls required

#define APIURL_CONVAR_NAME "get5_rest_api_url"
#define APIKEY_CONVAR_NAME "get5_rest_api_key"

// TODO: consider having string for matchid...
ConVar g_APIKeyCvar;
ConVar g_APIURLCvar;

#include "get5/util.sp"
#include "get5/version.sp"
#include "get5restapi/httpclient.sp"
#include "get5restapi/events.sp"
#include "get5restapi/logo.sp"
#include "get5restapi/tests.sp"

// clang-format off
public Plugin myinfo = {
    name = "Get5 REST API Integration",
    author = "mathiassmichno",
    description = "New and improved REST API interface for get5",
    version = PLUGIN_VERSION,
    url = "https://github.com/mathiassmichno/get5"
};
// clang-format on

public void OnPluginStart() {
    InitDebugLog("get5_rest_api_debug", "get5_restapi");
    LogDebug("OnPluginStart version=%s", PLUGIN_VERSION);

    g_APIKeyCvar = CreateConVar(APIKEY_CONVAR_NAME, "",
            "Match API key, this is automatically set through rcon");
    HookConVarChange(g_APIKeyCvar, ApiKeyChanged);

    g_APIURLCvar = CreateConVar(APIURL_CONVAR_NAME, "",
            "URL of the get5 rest api");
    HookConVarChange(g_APIURLCvar, ApiUrlChanged);

    RegConsoleCmd("get5_rest_api_available", Command_Avaliable);
    RegServerCmd("get5_rest_api_register", Command_Register);

    // Test commands
    RegServerCmd("get5_rest_api_test", Command_Test,
            "Runs get5 REST API tests - should not be used on a live match server and requires REST API endpoints...");
}

public void OnPluginEnd() {
    g_APIURLCvar.RestoreDefault();
    g_APIKeyCvar.RestoreDefault();
}

public Action Command_Avaliable(int client, int args) {
    char versionString[64] = "unknown";
    ConVar versionCvar = FindConVar("get5_version");
    if (versionCvar != null) {
        versionCvar.GetString(versionString, sizeof(versionString));
    }

    JSONObject json = new JSONObject();
    json.SetInt("gamestate", view_as<int>(Get5_GetGameState()));
    json.SetBool("available", true);
    json.SetString("plugin_version", versionString);
    char jsonStr[MAX_JSONSTR_LEN];
    json.ToString(jsonStr, MAX_JSONSTR_LEN);
    delete json;

    ReplyToCommand(client, jsonStr);

    return Plugin_Handled;
}

public Action Command_Register(int args) {
    if (!StrEqual(g_APIURL, "")) {
        RegisterServerWithRestApi();
    } else {
        ReplyToCommand(0, "REST API URL must be set first");
    }

    return Plugin_Handled;
}

