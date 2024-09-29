#include "GameModule.hpp"

// CompanyName
Red::CString CyberlibsCore::GameModule::GetCompanyName(const Red::CString& fileNameOrPath)
{
    const char* const UNKNOWN = "Unknown";

    auto filePath = ResolvePath(fileNameOrPath);
    if (!IsValidPath(filePath))
    {
        return UNKNOWN;
    }

    auto verData = GetVersionInfo(filePath);
    if (verData.empty())
    {
        return UNKNOWN;
    }

    return GetVersionInfoString(verData, L"CompanyName");
}

// Description
Red::CString CyberlibsCore::GameModule::GetDescription(const Red::CString& fileNameOrPath)
{
    const char* const UNKNOWN = "Unknown";

    auto filePath = ResolvePath(fileNameOrPath);
    if (!IsValidPath(filePath))
    {
        return UNKNOWN;
    }

    auto verData = GetVersionInfo(filePath);
    if (verData.empty())
    {
        return UNKNOWN;
    }

    return GetVersionInfoString(verData, L"FileDescription");
}

// EntryPoint
Red::CString CyberlibsCore::GameModule::GetEntryPoint(const Red::CString& fileNameOrPath)
{
    const char* const UNKNOWN = "Unknown";

    std::wstring wFileNameOrPath(fileNameOrPath.c_str(), fileNameOrPath.c_str() + fileNameOrPath.Length());
    HMODULE hModule = GetModuleHandleW(wFileNameOrPath.c_str());
    if (hModule == NULL)
    {
        return UNKNOWN;
    }

    libpe::Clibpe pe;
    if (pe.OpenFile(wFileNameOrPath.c_str()) != libpe::PEOK)
    {
        return UNKNOWN;
    }

    auto ntHeader = pe.GetNTHeader();
    if (!ntHeader)
    {
        return UNKNOWN;
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
        return UNKNOWN;
    }

    char buffer[32];
    snprintf(buffer, sizeof(buffer), "0x%08X", entryPoint);

    return buffer;
}

// Export
Red::DynArray<CyberlibsCore::GameModuleExportArray> CyberlibsCore::GameModule::GetExport(const Red::CString& fileNameOrPath)
{
    Red::DynArray<GameModuleExportArray> result;

    auto filePath = ResolvePath(fileNameOrPath);
    if (!IsValidPath(filePath))
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
            GameModuleExportArray funcInfo;
            funcInfo.entry = Red::CString(func.strFuncName.c_str());
            funcInfo.ordinal = func.dwOrdinal;
            funcInfo.rva = func.dwFuncRVA;
            funcInfo.forwarderName = func.strForwarderName;
            result.PushBack(funcInfo);
        }
    }
    return result;
}

// File Path
Red::CString CyberlibsCore::GameModule::GetFilePath(const Red::CString& fileNameOrPath)
{
    const char* const UNKNOWN = "Unknown";

    std::wstring wFileNameOrPath(fileNameOrPath.c_str(), fileNameOrPath.c_str() + fileNameOrPath.Length());
    HMODULE hModule = GetModuleHandleW(wFileNameOrPath.c_str());
    if (hModule == NULL)
    {
        return UNKNOWN;
    }

    wchar_t wFilePath[MAX_PATH];
    DWORD result = GetModuleFileNameW(hModule, wFilePath, MAX_PATH);
    if (result == 0 || result == MAX_PATH)
    {
        return UNKNOWN;
    }

    char filePath[MAX_PATH];
    WideCharToMultiByte(CP_UTF8, 0, wFilePath, -1, filePath, MAX_PATH, NULL, NULL);

    return Red::CString(filePath);
}

// File Size
Red::CString CyberlibsCore::GameModule::GetFileSize(const Red::CString& fileNameOrPath)
{
    const char* const UNKNOWN = "Unknown";

    auto filePath = ResolvePath(fileNameOrPath);
    if (!IsValidPath(filePath))
    {
        return UNKNOWN;
    }

    HANDLE hFile =
        CreateFileW(filePath.c_str(), GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE)
    {
        return UNKNOWN;
    }

    LARGE_INTEGER fileSize;
    if (!GetFileSizeEx(hFile, &fileSize))
    {
        CloseHandle(hFile);
        return UNKNOWN;
    }
    CloseHandle(hFile);

    char buffer[32];
    snprintf(buffer, sizeof(buffer), "%lld", fileSize.QuadPart);

    return Red::CString(buffer);
}

// File Type
Red::CString CyberlibsCore::GameModule::GetFileType(const Red::CString& fileNameOrPath)
{
    const char* const UNKNOWN = "Unknown";

    auto filePath = ResolvePath(fileNameOrPath);
    if (!IsValidPath(filePath))
    {
        return UNKNOWN;
    }

    libpe::Clibpe pe;
    if (pe.OpenFile(filePath.c_str()) != libpe::PEOK)
    {
        return UNKNOWN;
    }

    auto ntHeader = pe.GetNTHeader();
    if (!ntHeader)
    {
        return UNKNOWN;
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
        return UNKNOWN;
    }
}

// Import
Red::DynArray<CyberlibsCore::GameModuleImportArray> CyberlibsCore::GameModule::GetImport(const Red::CString& fileNameOrPath)
{
    Red::DynArray<GameModuleImportArray> result;

    auto filePath = ResolvePath(fileNameOrPath);
    if (!IsValidPath(filePath))
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
            GameModuleImportArray moduleInfo;
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

// Load Address
Red::CString CyberlibsCore::GameModule::GetLoadAddress(const Red::CString& fileNameOrPath)
{
    const char* const UNKNOWN = "Unknown";

    std::wstring wFileNameOrPath(fileNameOrPath.c_str(), fileNameOrPath.c_str() + fileNameOrPath.Length());
    HMODULE hModule = GetModuleHandleW(wFileNameOrPath.c_str());
    if (hModule == NULL)
    {
        return UNKNOWN;
    }

    char buffer[32];
    snprintf(buffer, sizeof(buffer), "0x%p", hModule);

    return buffer;
}

// List Loaded Modules
Red::DynArray<Red::CString> CyberlibsCore::GameModule::GetLoadedModules()
{
    auto modules64 = GetModules64();
    auto modules32 = GetModules32();

    Red::DynArray<Red::CString> result;
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

// Mapped Size
Red::CString CyberlibsCore::GameModule::GetMappedSize(const Red::CString& fileNameOrPath)
{
    const char* const UNKNOWN = "Unknown";

    std::wstring wFileNameOrPath(fileNameOrPath.c_str(), fileNameOrPath.c_str() + fileNameOrPath.Length());
    HMODULE hModule = GetModuleHandleW(wFileNameOrPath.c_str());
    if (hModule == NULL)
    {
        return UNKNOWN;
    }

    MODULEINFO moduleInfo;
    if (!GetModuleInformation(GetCurrentProcess(), hModule, &moduleInfo, sizeof(moduleInfo)))
    {
        return UNKNOWN;
    }

    char buffer[32];
    snprintf(buffer, sizeof(buffer), "%llu", static_cast<unsigned long long>(moduleInfo.SizeOfImage));
    return Red::CString(buffer);
}

// TimeDateStamp
Red::CString CyberlibsCore::GameModule::GetTimeDateStamp(const Red::CString& fileNameOrPath)
{
    const char* const UNKNOWN = "Unknown";
    auto filePath = ResolvePath(fileNameOrPath);
    if (!IsValidPath(filePath))
    {
        return UNKNOWN;
    }

    libpe::Clibpe pe;
    if (pe.OpenFile(filePath.c_str()) != libpe::PEOK)
    {
        return UNKNOWN;
    }

    auto ntHeader = pe.GetNTHeader();
    if (!ntHeader)
    {
        return UNKNOWN;
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
        return UNKNOWN;
    }

    char buffer[64];
    time_t unixTime = static_cast<time_t>(timeDateStamp);
    struct tm timeInfo;
    gmtime_s(&timeInfo, &unixTime);
    strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S", &timeInfo);

    return Red::CString(buffer);
}

// Version
Red::CString CyberlibsCore::GameModule::GetVersion(const Red::CString& fileNameOrPath)
{
    const char* const UNKNOWN = "Unknown";

    auto filePath = ResolvePath(fileNameOrPath);
    if (!IsValidPath(filePath))
    {
        return UNKNOWN;
    }

    auto verData = GetVersionInfo(filePath);
    if (verData.empty())
    {
        return UNKNOWN;
    }

    UINT size = 0;
    VS_FIXEDFILEINFO* verInfo = nullptr;
    if (!VerQueryValueW(verData.data(), L"\\", (VOID FAR * FAR*)&verInfo, &size))
    {
        return UNKNOWN;
    }

    if (size < sizeof(VS_FIXEDFILEINFO) || verInfo->dwSignature != 0xfeef04bd)
    {
        return UNKNOWN;
    }

    char szVersion[32];
    sprintf_s(szVersion, "%d.%d.%d.%d",
        HIWORD(verInfo->dwFileVersionMS),
        LOWORD(verInfo->dwFileVersionMS),
        HIWORD(verInfo->dwFileVersionLS),
        LOWORD(verInfo->dwFileVersionLS));

    return Red::CString(szVersion);
}

// IsLoaded
bool CyberlibsCore::GameModule::IsLoaded(const Red::CString& fileNameOrPath)
{
    std::wstring wFileNameOrPath(fileNameOrPath.c_str(), fileNameOrPath.c_str() + fileNameOrPath.Length());
    HMODULE hModule = GetModuleHandleW(wFileNameOrPath.c_str());

    bool isLoaded = (hModule != NULL);

    return isLoaded;
}
