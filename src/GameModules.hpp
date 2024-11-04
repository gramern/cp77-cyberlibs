#pragma once

#include <RED4ext/RED4ext.hpp>
#include <RedLib.hpp>
#include "Structs.hpp"

#include <string>
#include <vector>
#include <windows.h>
#include <psapi.h>
#include <mutex>
#include <shared_mutex>
#include <chrono>

import libpe;

namespace CyberlibsCore
{
struct GameModules : Red::IScriptable
{
public:
    static Red::CString GetCompanyName(const Red::CString& fileNameOrPath);
    static Red::CString GetDescription(const Red::CString& fileNameOrPath);
    static Red::CString GetEntryPoint(const Red::CString& fileNameOrPath);
    static Red::DynArray<GameModulesExportEntry> GetExport(const Red::CString& fileNameOrPath);
    static Red::CString GetFilePath(const Red::CString& fileNameOrPath);
    static Red::CString GetFileSize(const Red::CString& fileNameOrPath);
    static Red::CString GetFileType(const Red::CString& fileNameOrPath);
    static Red::DynArray<GameModulesImportEntry> GetImport(const Red::CString& fileNameOrPath);
    static Red::CString GetLoadAddress(const Red::CString& fileNameOrPath);
    static Red::DynArray<Red::CString> GetLoadedModules();
    static Red::CString GetMappedSize(const Red::CString& fileNameOrPath);
    static Red::CString GetTimeDateStamp(const Red::CString& fileNameOrPath, Red::Optional<bool> pathFriendly);
    static Red::CString GetVersion(const Red::CString& fileNameOrPath);
    static bool IsLoaded(const Red::CString& fileNameOrPath);

    RTTI_IMPL_TYPEINFO(CyberlibsCore::GameModules);
    RTTI_IMPL_ALLOCATOR();

private:
    static constexpr const char* UNKNOWN_VALUE = "Unknown";
    static constexpr const char* RATE_LIMIT_EXCEEDED = "Rate limit exceeded";

    struct ResourceCache
    {
        std::unordered_map<std::wstring, std::pair<std::vector<BYTE>, std::chrono::steady_clock::time_point>>
            versionCache;
        std::unordered_map<std::wstring, std::pair<Red::CString, std::chrono::steady_clock::time_point>> pathCache;
        std::chrono::steady_clock::time_point lastCleanup;

        static constexpr auto CACHE_LIFETIME = std::chrono::seconds(30);
        static constexpr auto CLEANUP_INTERVAL = std::chrono::minutes(5);
    };

    struct RateLimit
    {
        std::chrono::steady_clock::time_point lastRequest;
        uint32_t requestCount;

        static constexpr uint32_t MAX_REQUESTS = 1000;
        static constexpr auto TIME_WINDOW = std::chrono::seconds(1);
    };

    static inline ResourceCache cache_;
    static inline RateLimit rateLimit_;
    static inline std::mutex moduleMutex_;
    static inline std::mutex rateMutex_;
    static inline std::shared_mutex moduleReadWriteMutex_;

    static bool checkRateLimit();
    static void cleanupCacheIfNeeded();
    static Red::DynArray<Red::CString> getModules(DWORD flags);

    inline static Red::DynArray<Red::CString> getModules64()
    {
        return getModules(LIST_MODULES_64BIT);
    }

    inline static Red::DynArray<Red::CString> getModules32()
    {
        return getModules(LIST_MODULES_32BIT);
    }

    inline static bool isValidPath(const std::wstring& filePath)
    {
        return GetFileAttributesW(filePath.c_str()) != INVALID_FILE_ATTRIBUTES;
    }

    static std::wstring resolvePath(const Red::CString& moduleFileOrPath);
    static std::vector<BYTE> getVersionInfo(const std::wstring& modulePath);
    static std::vector<BYTE> getVersionInfoCached(const std::wstring& modulePath);
    static Red::CString getVersionInfoString(const std::vector<BYTE>& verData, const wchar_t* key);
    static Red::CString wideCharToRedString(const std::wstring& wide);

protected:
    class ModuleLock
    {
        std::lock_guard<std::mutex> lock_;

    public:
        ModuleLock() : lock_(moduleMutex_)
        {
            cleanupCacheIfNeeded();
        }
    };

    class SharedModuleLock
    {
        std::shared_lock<std::shared_mutex> lock_;

    public:
        SharedModuleLock()
            : lock_(moduleReadWriteMutex_)
        {
            cleanupCacheIfNeeded();
        }
    };
};
} // namespace CyberlibsCore

RTTI_DEFINE_CLASS(CyberlibsCore::GameModules,
{
    RTTI_ALIAS("CyberlibsCore.GameModules");

    RTTI_METHOD(GetCompanyName);
    RTTI_METHOD(GetDescription);
    RTTI_METHOD(GetEntryPoint);
    RTTI_METHOD(GetExport);
    RTTI_METHOD(GetFilePath);
    RTTI_METHOD(GetFileSize);
    RTTI_METHOD(GetFileType);
    RTTI_METHOD(GetImport);
    RTTI_METHOD(GetLoadAddress);
    RTTI_METHOD(GetLoadedModules);
    RTTI_METHOD(GetMappedSize);
    RTTI_METHOD(GetTimeDateStamp);
    RTTI_METHOD(GetVersion);
    RTTI_METHOD(IsLoaded);
});
