#define LOGO_DIR "materials/panorama/images/tournaments/teams"
#define LOGO_DOWNLOAD_BASE_URL "static/img/logos"

public void HandleNewLogos() {
    if (!DirExists(LOGO_DIR)) {
        if (!CreateDirectory(LOGO_DIR, 755)) {
            LogError("Failed to create logo directory: %s", LOGO_DIR);
            return;
        }
    }

    char logo1[64];
    char logo2[64];
    GetConVarStringSafe("mp_teamlogo_1", logo1, sizeof(logo1));
    GetConVarStringSafe("mp_teamlogo_2", logo2, sizeof(logo2));
    CheckForLogo(logo1);
    CheckForLogo(logo2);
}

public void CheckForLogo(const char[] logo) {
    if (StrEqual(logo, "")) {
        return;
    }

    char logoPath[PLATFORM_MAX_PATH + 1];
    Format(logoPath, sizeof(logoPath), "%s/%s.svg", LOGO_DIR, logo);

    // Try to fetch the file if we don't have it.
    if (!FileExists(logoPath)) {
        LogDebug("Fetching logo for %s", logo);
        char url[MAX_URL_LEN];
        Format(url, MAX_URL_LEN, "%s/%s.svg", LOGO_DOWNLOAD_BASE_URL, logo);
        g_HTTPClient.DownloadFile(url, logoPath, LogoDownloadedCallback);
    }
}

public void LogoDownloadedCallback(HTTPStatus status, any value, const char[] error) {
    if (status != HTTPStatus_OK) {
        LogError("Logo download failed! HTTP status code: %d", status);
        return;
    }
    LogMessage("Saved logo");
}

