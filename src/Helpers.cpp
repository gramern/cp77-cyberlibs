#include "Helpers.hpp"

// Loaded Modules

Red::DynArray<Red::CString> GetModules(DWORD flags)
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

Red::DynArray<Red::CString> GetModules64()
{
    return GetModules(LIST_MODULES_64BIT);
}

Red::DynArray<Red::CString> GetModules32()
{
    return GetModules(LIST_MODULES_32BIT);
}

// Paths

bool IsValidPath(const std::wstring& filePath)
{
    return GetFileAttributesW(filePath.c_str()) != INVALID_FILE_ATTRIBUTES;
}

std::wstring ResolvePath(const Red::CString& fileNameOrPath)
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

// VersionInfo

std::vector<BYTE> GetVersionInfo(const std::wstring& fileNameOrPath)
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

Red::CString GetVersionInfoString(const std::vector<BYTE>& verData, const wchar_t* key)
{
    const char* const UNKNOWN = "Unknown";

    LPVOID lpBuffer = nullptr;
    UINT size = 0;
    std::wstring queryPath = L"\\StringFileInfo\\040904B0\\" + std::wstring(key);

    if (!VerQueryValueW(verData.data(), queryPath.c_str(), &lpBuffer, &size) || size == 0 || lpBuffer == nullptr)
    {
        return UNKNOWN;
    }

    std::wstring wValue(static_cast<LPCWSTR>(lpBuffer), size);

    return WideCharToRedString(wValue);
}

// Conversion

Red::CString WideCharToRedString(const std::wstring& wide)
{
    const char* const UNKNOWN = "Unknown";

    if (wide.empty())
    {
        return UNKNOWN;
    }

    int size_needed = WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, NULL, 0, NULL, NULL);
    std::string utf8(size_needed, 0);
    WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, &utf8[0], size_needed, NULL, NULL);
    utf8.pop_back();

    return utf8.empty() ? UNKNOWN : Red::CString(utf8.c_str());
}

