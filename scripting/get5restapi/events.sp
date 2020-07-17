#define MAX_STR_LEN 128

char g_MatchID[MAX_STR_LEN];

/* helpers */

static void StoreMatchID() {
    /* TODO: validate match id to be url safe */
    Get5_GetMatchID(g_MatchID, sizeof(g_MatchID));
}

public void UpdateRoundStats(int mapNumber) {
    int t1score = CS_GetTeamScore(Get5_MatchTeamToCSTeam(MatchTeam_Team1));
    int t2score = CS_GetTeamScore(Get5_MatchTeamToCSTeam(MatchTeam_Team2));

    JSONObject params = new JSONObject();
    params.SetInt("team1score", t1score);
    params.SetInt("team2score", t2score);
    MakePostRequest(params, "match/%s/map/%d/update", g_MatchID, mapNumber);

    KeyValues kv = new KeyValues("Stats");
    Get5_GetMatchStats(kv);
    char mapKey[32];
    Format(mapKey, sizeof(mapKey), "map%d", mapNumber);
    if (kv.JumpToKey(mapKey)) {
        if (kv.JumpToKey("team1")) {
            UpdatePlayerStats(kv, MatchTeam_Team1);
            kv.GoBack();
        }
        if (kv.JumpToKey("team2")) {
            UpdatePlayerStats(kv, MatchTeam_Team2);
            kv.GoBack();
        }
        kv.GoBack();
    }
    delete kv;
}

public void UpdatePlayerStats(KeyValues kv, MatchTeam team) {
    char name[MAX_NAME_LENGTH];
    char auth[AUTH_LENGTH];
    int mapNumber = MapNumber();

    if (kv.GotoFirstSubKey()) {
        do {
            kv.GetSectionName(auth, sizeof(auth));
            kv.GetString("name", name, sizeof(name));
            char teamString[MAX_STR_LEN];
            GetTeamString(team, teamString, sizeof(teamString));

            /* TODO: Maybe we can subclass kv to make "json dump"-able  */
            JSONObject params = new JSONObject();
            params.SetString("team", teamString);
            params.SetString("name", name);
            params.SetInt(STAT_KILLS, kv.GetNum(STAT_KILLS));
            params.SetInt(STAT_DEATHS, kv.GetNum(STAT_DEATHS));
            params.SetInt(STAT_ASSISTS, kv.GetNum(STAT_ASSISTS));
            params.SetInt(STAT_FLASHBANG_ASSISTS, kv.GetNum(STAT_FLASHBANG_ASSISTS));
            params.SetInt(STAT_TEAMKILLS, kv.GetNum(STAT_TEAMKILLS));
            params.SetInt(STAT_SUICIDES, kv.GetNum(STAT_SUICIDES));
            params.SetInt(STAT_DAMAGE, kv.GetNum(STAT_DAMAGE));
            params.SetInt(STAT_HEADSHOT_KILLS, kv.GetNum(STAT_HEADSHOT_KILLS));
            params.SetInt(STAT_ROUNDSPLAYED, kv.GetNum(STAT_ROUNDSPLAYED));
            params.SetInt(STAT_BOMBPLANTS, kv.GetNum(STAT_BOMBPLANTS));
            params.SetInt(STAT_BOMBDEFUSES, kv.GetNum(STAT_BOMBDEFUSES));
            params.SetInt(STAT_1K, kv.GetNum(STAT_1K));
            params.SetInt(STAT_2K, kv.GetNum(STAT_2K));
            params.SetInt(STAT_3K, kv.GetNum(STAT_3K));
            params.SetInt(STAT_4K, kv.GetNum(STAT_4K));
            params.SetInt(STAT_5K, kv.GetNum(STAT_5K));
            params.SetInt(STAT_V1, kv.GetNum(STAT_V1));
            params.SetInt(STAT_V2, kv.GetNum(STAT_V2));
            params.SetInt(STAT_V3, kv.GetNum(STAT_V3));
            params.SetInt(STAT_V4, kv.GetNum(STAT_V4));
            params.SetInt(STAT_V5, kv.GetNum(STAT_V5));
            params.SetInt(STAT_FIRSTKILL_T, kv.GetNum(STAT_FIRSTKILL_T));
            params.SetInt(STAT_FIRSTKILL_CT, kv.GetNum(STAT_FIRSTKILL_CT));
            params.SetInt(STAT_FIRSTDEATH_T, kv.GetNum(STAT_FIRSTDEATH_T));
            params.SetInt(STAT_FIRSTDEATH_CT, kv.GetNum(STAT_FIRSTDEATH_CT));
            params.SetInt(STAT_TRADEKILL, kv.GetNum(STAT_TRADEKILL));
            params.SetInt(STAT_CONTRIBUTION_SCORE, kv.GetNum(STAT_CONTRIBUTION_SCORE));

            MakePostRequest(params, "match/%s/map/%d/player/%s/update",
                    g_MatchID, mapNumber, auth);

        } while (kv.GotoNextKey());
        kv.GoBack();
    }
}

static int MapNumber() {
    int t1, t2, n;
    int buf;
    Get5_GetTeamScores(MatchTeam_Team1, t1, buf);
    Get5_GetTeamScores(MatchTeam_Team2, t2, buf);
    Get5_GetTeamScores(MatchTeam_TeamNone, n, buf);
    return t1 + t2 + n;
}

/* Event handlers */

public void Get5_OnBackupRestore() {
    StoreMatchID();
}

public void Get5_OnSeriesInit() {
    StoreMatchID();
    HandleNewLogos();
}

public void Get5_OnGoingLive(int mapNumber) {
    char mapName[MAX_STR_LEN];
    GetCurrentMap(mapName, sizeof(mapName));

    JSONObject params = new JSONObject();
    params.SetString("mapname", mapName);

    MakePostRequest(params, "match/%s/map/%d/start", g_MatchID, mapNumber);

    Get5_AddLiveCvar(APIKEY_CONVAR_NAME, g_APIKey);
    Get5_AddLiveCvar(APIURL_CONVAR_NAME, g_APIURL);
}

public void Get5_OnMapResult(const char[] map, MatchTeam mapWinner,
        int team1Score, int team2Score, int mapNumber) {
    char winnerString[MAX_STR_LEN];
    GetTeamString(mapWinner, winnerString, sizeof(winnerString));

    JSONObject params = new JSONObject();
    params.SetInt("team1Score", team1Score);
    params.SetInt("team2Score", team2Score);
    params.SetString("winner", winnerString);

    MakePostRequest(params, "match/%s/map/%d/finish", g_MatchID, mapNumber);
}

public void Get5_OnSeriesResult(MatchTeam seriesWinner, int team1MapScore, int team2MapScore) {
    char winnerString[MAX_STR_LEN];
    GetTeamString(seriesWinner, winnerString, sizeof(winnerString));

    KeyValues kv = new KeyValues("Stats");
    Get5_GetMatchStats(kv);
    bool forfeit = kv.GetNum(STAT_SERIES_FORFEIT, 0) != 0;
    delete kv;

    JSONObject params = new JSONObject();
    params.SetInt("team1mapscore", team1MapScore);
    params.SetInt("team2mapscore", team2MapScore);
    params.SetString("winner", winnerString);
    params.SetBool("forfeit", forfeit);

    MakePostRequest(params, "match/%s/finish", g_MatchID);
}

public void Get5_OnRoundStatsUpdated() {
    if (Get5_GetGameState() == Get5State_Live) {
        UpdateRoundStats(MapNumber());
    }
}
