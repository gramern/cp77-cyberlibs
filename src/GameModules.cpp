#include "GameModules.hpp"

// CompanyName
Red::CString CyberlibsCore::GameModules::GetCompanyName(const Red::CString& fileNameOrPath)
{
    if (!checkRateLimit())
    {
        return RATE_LIMIT_EXCEEDED;
    }

    SharedModuleLock lock;
    try
    {
        auto filePath = resolvePath(fileNameOrPath);
        if (!isValidPath(filePath))
        {
            return UNKNOWN_VALUE;
        }

        auto verData = getVersionInfoCached(filePath);
        if (verData.empty())
        {
            return UNKNOWN_VALUE;
        }

        return getVersionInfoString(verData, L"CompanyName");
    }
    catch (...)
    {
        return UNKNOWN_VALUE;
    }
}

// Description
Red::CString CyberlibsCore::GameModules::GetDescription(const Red::CString& fileNameOrPath)
{
    if (!checkRateLimit())
    {
        return RATE_LIMIT_EXCEEDED;
    }

    SharedModuleLock lock;
    try
    {
        auto filePath = resolvePath(fileNameOrPath);
        if (!isValidPath(filePath))
        {
            return UNKNOWN_VALUE;
        }

        auto verData = getVersionInfoCached(filePath);
        if (verData.empty())
        {
            return UNKNOWN_VALUE;
        }

        return getVersionInfoString(verData, L"FileDescription");
    }
    catch (...)
    {
        return UNKNOWN_VALUE;
    }
}

// EntryPoint
Red::CString CyberlibsCore::GameModules::GetEntryPoint(const Red::CString& fileNameOrPath)
{
    if (!checkRateLimit())
    {
        return RATE_LIMIT_EXCEEDED;
    }

    ModuleLock lock;
    try
    {
        std::wstring wFileNameOrPath(fileNameOrPath.c_str(), fileNameOrPath.c_str() + fileNameOrPath.Length());
        HMODULE hModule = GetModuleHandleW(wFileNameOrPath.c_str());
        if (hModule == NULL)
        {
            return UNKNOWN_VALUE;
        }

        libpe::Clibpe pe;
        if (pe.OpenFile(wFileNameOrPath.c_str()) != libpe::PEOK)
        {
            return UNKNOWN_VALUE;
        }

        auto ntHeader = pe.GetNTHeader();
        if (!ntHeader)
        {
            return UNKNOWN_VALUE;
        }

        DWORD entryPoint;
        libpe::EFileType fileType = libpe::GetFileType(ntHeader.value());
        if (fileType == libpe::EFileType::PE32)
        {
            entryPoint = ntHeader->unHdr.stNTHdr32.OptionalHeader.AddressOfEntryPoint;
        }
        else if (fileType == libpe::EFileType::PE64)
        {
            entryPoint = ntHeader->unHdr.stNTHdr64.OptionalHeader.AddressOfEntryPoint;
        }
        else
        {
            return UNKNOWN_VALUE;
        }

        char buffer[32];
        snprintf(buffer, sizeof(buffer), "0x%08X", entryPoint);

        return buffer;
    }
    catch (...)
    {
        return UNKNOWN_VALUE;
    }
}

// Export
Red::DynArray<CyberlibsCore::GameModulesExportEntry> CyberlibsCore::GameModules::GetExport(const Red::CString& fileNameOrPath)
{
    Red::DynArray<GameModulesExportEntry> result;

    if (!checkRateLimit())
    {
        GameModulesExportEntry funcInfo;
        funcInfo.entry = RATE_LIMIT_EXCEEDED;
        funcInfo.ordinal = 0;
        funcInfo.rva = 0;
        funcInfo.forwarderName = RATE_LIMIT_EXCEEDED;
        result.PushBack(funcInfo);

        return result;
    }

    ModuleLock lock;
    try
    {
        auto filePath = resolvePath(fileNameOrPath);
        if (!isValidPath(filePath))
        {
            return result;
        }

        libpe::Clibpe pe;
        if (pe.OpenFile(filePath.c_str()) != libpe::PEOK)
        {
            return result;
        }

        auto exportData = pe.GetExport();
        if (exportData)
        {
            for (const auto& func : exportData->vecFuncs)
            {
                GameModulesExportEntry funcInfo;
                funcInfo.entry = Red::CString(func.strFuncName.c_str());
                funcInfo.ordinal = func.dwOrdinal;
                funcInfo.rva = func.dwFuncRVA;
                funcInfo.forwarderName = func.strForwarderName;
                result.PushBack(funcInfo);
            }
        }

        return result;
    }
    catch (...)
    {
        GameModulesExportEntry funcInfo;
        funcInfo.entry = UNKNOWN_VALUE;
        funcInfo.ordinal = 0;
        funcInfo.rva = 0;
        funcInfo.forwarderName = UNKNOWN_VALUE;
        result.PushBack(funcInfo);

        return result;
    }
}

// File Path
Red::CString CyberlibsCore::GameModules::GetFilePath(const Red::CString& fileNameOrPath)
{
    if (!checkRateLimit())
    {
        return RATE_LIMIT_EXCEEDED;
    }

    ModuleLock lock;
    try
    {
        std::wstring wFileNameOrPath(fileNameOrPath.c_str(), fileNameOrPath.c_str() + fileNameOrPath.Length());
        HMODULE hModule = GetModuleHandleW(wFileNameOrPath.c_str());
        if (hModule == NULL)
        {
            return UNKNOWN_VALUE;
        }

        wchar_t wFilePath[MAX_PATH];
        DWORD result = GetModuleFileNameW(hModule, wFilePath, MAX_PATH);
        if (result == 0 || result == MAX_PATH)
        {
            return UNKNOWN_VALUE;
        }

        char filePath[MAX_PATH];
        WideCharToMultiByte(CP_UTF8, 0, wFilePath, -1, filePath, MAX_PATH, NULL, NULL);

        return Red::CString(filePath);
    }
    catch (...)
    {
        return UNKNOWN_VALUE;
    }
}

// File Size
Red::CString CyberlibsCore::GameModules::GetFileSize(const Red::CString& fileNameOrPath)
{
    if (!checkRateLimit())
    {
        return RATE_LIMIT_EXCEEDED;
    }

    SharedModuleLock lock;
    try
    {
        auto filePath = resolvePath(fileNameOrPath);
        if (!isValidPath(filePath))
        {
            return UNKNOWN_VALUE;
        }

        HANDLE hFile = CreateFileW(filePath.c_str(), GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING,
                                   FILE_ATTRIBUTE_NORMAL, NULL);
        if (hFile == INVALID_HANDLE_VALUE)
        {
            return UNKNOWN_VALUE;
        }

        LARGE_INTEGER fileSize;
        if (!GetFileSizeEx(hFile, &fileSize))
        {
            CloseHandle(hFile);
            return UNKNOWN_VALUE;
        }
        CloseHandle(hFile);

        char buffer[32];
        snprintf(buffer, sizeof(buffer), "%lld", fileSize.QuadPart);

        return Red::CString(buffer);
    }
    catch (...)
    {
        return UNKNOWN_VALUE;
    }
}

// File Type
Red::CString CyberlibsCore::GameModules::GetFileType(const Red::CString& fileNameOrPath)
{
    if (!checkRateLimit())
    {
        return RATE_LIMIT_EXCEEDED;
    }

    SharedModuleLock lock;
    try
    {
        auto filePath = resolvePath(fileNameOrPath);
        if (!isValidPath(filePath))
        {
            return UNKNOWN_VALUE;
        }

        libpe::Clibpe pe;
        if (pe.OpenFile(filePath.c_str()) != libpe::PEOK)
        {
            return UNKNOWN_VALUE;
        }

        auto ntHeader = pe.GetNTHeader();
        if (!ntHeader)
        {
            return UNKNOWN_VALUE;
        }

        libpe::EFileType fileType = libpe::GetFileType(ntHeader.value());

        switch (fileType)
        {
        case libpe::EFileType::PE32:
            return "PE32";
        case libpe::EFileType::PE64:
            return "PE64";
        case libpe::EFileType::PEROM:
            return "PEROM";
        default:
            return UNKNOWN_VALUE;
        }
    }
    catch (...)
    {
        return UNKNOWN_VALUE;
    }
}

// Import
Red::DynArray<CyberlibsCore::GameModulesImportEntry> CyberlibsCore::GameModules::GetImport(const Red::CString& fileNameOrPath)
{
    Red::DynArray<GameModulesImportEntry> result;

    if (!checkRateLimit())
    {
        GameModulesImportEntry moduleInfo;
        moduleInfo.fileName = RATE_LIMIT_EXCEEDED;
        result.PushBack(moduleInfo);

        return result;
    }

    ModuleLock lock;
    try
    {
        auto filePath = resolvePath(fileNameOrPath);
        if (!isValidPath(filePath))
        {
            return result;
        }

        libpe::Clibpe pe;
        if (pe.OpenFile(filePath.c_str()) != libpe::PEOK)
        {
            return result;
        }

        auto importData = pe.GetImport();
        if (importData)
        {
            for (const auto& module : *importData)
            {
                GameModulesImportEntry moduleInfo;
                moduleInfo.fileName = Red::CString(module.strModuleName.c_str());
                for (const auto& func : module.vecImportFunc)
                {
                    moduleInfo.entries.PushBack(Red::CString(func.strFuncName.c_str()));
                }
                result.PushBack(moduleInfo);
            }
        }

        return result;
    }
    catch (...)
    {
        GameModulesImportEntry moduleInfo;
        moduleInfo.fileName = UNKNOWN_VALUE;
        result.PushBack(moduleInfo);

        return result;
    }
}

// Load Address
Red::CString CyberlibsCore::GameModules::GetLoadAddress(const Red::CString& fileNameOrPath)
{
    if (!checkRateLimit())
    {
        return RATE_LIMIT_EXCEEDED;
    }

    ModuleLock lock;
    try
    {
        std::wstring wFileNameOrPath(fileNameOrPath.c_str(), fileNameOrPath.c_str() + fileNameOrPath.Length());
        HMODULE hModule = GetModuleHandleW(wFileNameOrPath.c_str());
        if (hModule == NULL)
        {
            return UNKNOWN_VALUE;
        }

        char buffer[32];
        snprintf(buffer, sizeof(buffer), "0x%p", hModule);

        return buffer;
    }
    catch (...)
    {
        return UNKNOWN_VALUE;
    }
}

// List Loaded Modules
Red::DynArray<Red::CString> CyberlibsCore::GameModules::GetLoadedModules()
{
    Red::DynArray<Red::CString> result;

    if (!checkRateLimit())
    {
        result.PushBack(RATE_LIMIT_EXCEEDED);

        return result;
    }

    try
    {
        auto modules64 = getModules64();
        auto modules32 = getModules32();

        result.Reserve(modules64.size + modules32.size);

        for (const auto& module : modules64)
        {
            result.PushBack(module);
        }

        for (const auto& module : modules32)
        {
            bool alreadyAdded = false;
            for (const auto& existingModule : result)
            {
                if (existingModule == module)
                {
                    alreadyAdded = true;
                    break;
                }
            }
            if (!alreadyAdded)
            {
                result.PushBack(module);
            }
        }

        return result;
    }
    catch (...)
    {
        result.Clear(); 
        result.PushBack(UNKNOWN_VALUE);

        return result;
    }
}

// Mapped Size
Red::CString CyberlibsCore::GameModules::GetMappedSize(const Red::CString& fileNameOrPath)
{
    if (!checkRateLimit())
    {
        return RATE_LIMIT_EXCEEDED;
    }

    ModuleLock lock;
    try
    {
        std::wstring wFileNameOrPath(fileNameOrPath.c_str(), fileNameOrPath.c_str() + fileNameOrPath.Length());
        HMODULE hModule = GetModuleHandleW(wFileNameOrPath.c_str());
        if (hModule == NULL)
        {
            return UNKNOWN_VALUE;
        }

        MODULEINFO moduleInfo;
        if (!GetModuleInformation(GetCurrentProcess(), hModule, &moduleInfo, sizeof(moduleInfo)))
        {
            return UNKNOWN_VALUE;
        }

        char buffer[32];
        snprintf(buffer, sizeof(buffer), "%llu", static_cast<unsigned long long>(moduleInfo.SizeOfImage));
        return Red::CString(buffer);
    }
    catch (...)
    {
        return UNKNOWN_VALUE;
    }
}

// TimeDateStamp
Red::CString CyberlibsCore::GameModules::GetTimeDateStamp(const Red::CString& fileNameOrPath)
{
    if (!checkRateLimit())
    {
        return RATE_LIMIT_EXCEEDED;
    }

    SharedModuleLock lock;
    try
    {
        auto filePath = resolvePath(fileNameOrPath);
        if (!isValidPath(filePath))
        {
            return UNKNOWN_VALUE;
        }

        libpe::Clibpe pe;
        if (pe.OpenFile(filePath.c_str()) != libpe::PEOK)
        {
            return UNKNOWN_VALUE;
        }

        auto ntHeader = pe.GetNTHeader();
        if (!ntHeader)
        {
            return UNKNOWN_VALUE;
        }

        DWORD timeDateStamp;
        libpe::EFileType fileType = libpe::GetFileType(ntHeader.value());
        if (fileType == libpe::EFileType::PE32)
        {
            timeDateStamp = ntHeader->unHdr.stNTHdr32.FileHeader.TimeDateStamp;
        }
        else if (fileType == libpe::EFileType::PE64)
        {
            timeDateStamp = ntHeader->unHdr.stNTHdr64.FileHeader.TimeDateStamp;
        }
        else
        {
            return UNKNOWN_VALUE;
        }

        char buffer[64];
        time_t unixTime = static_cast<time_t>(timeDateStamp);
        struct tm timeInfo;
        gmtime_s(&timeInfo, &unixTime);
        strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S", &timeInfo);

        return Red::CString(buffer);
    }
    catch (...)
    {
        return UNKNOWN_VALUE;
    }
}

// Version
Red::CString CyberlibsCore::GameModules::GetVersion(const Red::CString& fileNameOrPath)
{
    if (!checkRateLimit())
    {
        return RATE_LIMIT_EXCEEDED;
    }

    SharedModuleLock lock;
    try
    {
        auto filePath = resolvePath(fileNameOrPath);
        if (!isValidPath(filePath))
        {
            return UNKNOWN_VALUE;
        }

        auto verData = getVersionInfoCached(filePath);
        if (verData.empty())
        {
            return UNKNOWN_VALUE;
        }

        UINT size = 0;
        VS_FIXEDFILEINFO* verInfo = nullptr;
        if (!VerQueryValueW(verData.data(), L"\\", (VOID FAR * FAR*)&verInfo, &size))
        {
            return UNKNOWN_VALUE;
        }

        if (size < sizeof(VS_FIXEDFILEINFO) || verInfo->dwSignature != 0xfeef04bd)
        {
            return UNKNOWN_VALUE;
        }

        char szVersion[32];
        sprintf_s(szVersion, "%d.%d.%d.%d", HIWORD(verInfo->dwFileVersionMS), LOWORD(verInfo->dwFileVersionMS),
                  HIWORD(verInfo->dwFileVersionLS), LOWORD(verInfo->dwFileVersionLS));

        return Red::CString(szVersion);
    }
    catch (...)
    {
        return UNKNOWN_VALUE;
    }
}

// IsLoaded
bool CyberlibsCore::GameModules::IsLoaded(const Red::CString& fileNameOrPath)
{
    if (!checkRateLimit())
    {
        return RATE_LIMIT_EXCEEDED;
    }

    SharedModuleLock lock;

    std::wstring wFileNameOrPath(fileNameOrPath.c_str(), fileNameOrPath.c_str() + fileNameOrPath.Length());
    HMODULE hModule = GetModuleHandleW(wFileNameOrPath.c_str());

    bool isLoaded = (hModule != NULL);

    return isLoaded;
}

// Private Helpers

bool CyberlibsCore::GameModules::checkRateLimit()
{
    std::lock_guard<std::mutex> lock(rateMutex_);
    auto now = std::chrono::steady_clock::now();

    if (now - rateLimit_.lastRequest > RateLimit::TIME_WINDOW)
    {
        rateLimit_.requestCount = 1;
        rateLimit_.lastRequest = now;
        return true;
    }

    if (rateLimit_.requestCount >= RateLimit::MAX_REQUESTS)
    {
        return false;
    }

    rateLimit_.requestCount++;
    return true;
}

void CyberlibsCore::GameModules::cleanupCacheIfNeeded()
{
    auto now = std::chrono::steady_clock::now();
    if (now - cache_.lastCleanup > ResourceCache::CLEANUP_INTERVAL)
    {
        std::lock_guard<std::mutex> cacheLock(moduleMutex_);

        auto it = cache_.versionCache.begin();
        while (it != cache_.versionCache.end())
        {
            if (now - it->second.second > ResourceCache::CACHE_LIFETIME)
            {
                it = cache_.versionCache.erase(it);
            }
            else
            {
                ++it;
            }
        }

        auto pathIt = cache_.pathCache.begin();
        while (pathIt != cache_.pathCache.end())
        {
            if (now - pathIt->second.second > ResourceCache::CACHE_LIFETIME)
            {
                pathIt = cache_.pathCache.erase(pathIt);
            }
            else
            {
                ++pathIt;
            }
        }

        cache_.lastCleanup = now;
    }
}

Red::DynArray<Red::CString> CyberlibsCore::GameModules::getModules(DWORD flags)
{
    Red::DynArray<Red::CString> result;

    HANDLE hProcess = GetCurrentProcess();
    HMODULE hModules[1024];
    DWORD cbNeeded;

    if (EnumProcessModulesEx(hProcess, hModules, sizeof(hModules), &cbNeeded, flags))
    {
        for (unsigned int i = 0; i < (cbNeeded / sizeof(HMODULE)); i++)
        {
            char szModuleName[MAX_PATH];
            if (GetModuleFileNameExA(hProcess, hModules[i], szModuleName, sizeof(szModuleName) / sizeof(char)))
            {
                result.PushBack(Red::CString(szModuleName));
            }
        }
    }

    return result;
}

std::vector<BYTE> CyberlibsCore::GameModules::getVersionInfo(const std::wstring& fileNameOrPath)
{
    DWORD verSize = GetFileVersionInfoSizeW(fileNameOrPath.c_str(), NULL);
    if (verSize == 0)
    {
        return {};
    }

    std::vector<BYTE> verData(verSize);
    if (!GetFileVersionInfoW(fileNameOrPath.c_str(), 0, verSize, verData.data()))
    {
        return {};
    }

    return verData;
}

std::vector<BYTE> CyberlibsCore::GameModules::getVersionInfoCached(const std::wstring& path)
{
    auto now = std::chrono::steady_clock::now();

    {
        std::shared_lock<std::shared_mutex> readLock(moduleReadWriteMutex_);
        auto it = cache_.versionCache.find(path);
        if (it != cache_.versionCache.end() && (now - it->second.second < ResourceCache::CACHE_LIFETIME))
        {
            return it->second.first;
        }
    }

    auto verData = getVersionInfo(path);
    if (!verData.empty())
    {
        std::lock_guard<std::mutex> writeLock(moduleMutex_);
        cache_.versionCache[path] = {verData, now};
    }

    return verData;
}

Red::CString CyberlibsCore::GameModules::getVersionInfoString(const std::vector<BYTE>& verData, const wchar_t* key)
{
    LPVOID lpBuffer = nullptr;
    UINT size = 0;
    std::wstring queryPath = L"\\StringFileInfo\\040904B0\\" + std::wstring(key);

    if (!VerQueryValueW(verData.data(), queryPath.c_str(), &lpBuffer, &size) || size == 0 || lpBuffer == nullptr)
    {
        return UNKNOWN_VALUE;
    }

    std::wstring wValue(static_cast<LPCWSTR>(lpBuffer), size);

    return wideCharToRedString(wValue);
}

std::wstring CyberlibsCore::GameModules::resolvePath(const Red::CString& fileNameOrPath)
{
    std::wstring wFileNameOrPath(fileNameOrPath.c_str(), fileNameOrPath.c_str() + fileNameOrPath.Length());

    if (wFileNameOrPath.find(L'\\') != std::wstring::npos || wFileNameOrPath.find(L'/') != std::wstring::npos)
    {
        return wFileNameOrPath;
    }

    HMODULE hModule = GetModuleHandleW(wFileNameOrPath.c_str());
    if (hModule != NULL)
    {
        wchar_t wFilePath[MAX_PATH];
        DWORD result = GetModuleFileNameW(hModule, wFilePath, MAX_PATH);
        if (result != 0 && result != MAX_PATH)
        {
            return wFilePath;
        }
    }

    return L"";
}

Red::CString CyberlibsCore::GameModules::wideCharToRedString(const std::wstring& wide)
{
    if (wide.empty())
    {
        return UNKNOWN_VALUE;
    }

    int size_needed = WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, NULL, 0, NULL, NULL);
    std::string utf8(size_needed, 0);
    WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, &utf8[0], size_needed, NULL, NULL);
    utf8.pop_back();

    return utf8.empty() ? UNKNOWN_VALUE : Red::CString(utf8.c_str());
}
