#pragma once

#include <RED4ext/RED4ext.hpp>
#include <RedLib.hpp>
#include "GameModules.hpp"

namespace CyberlibsAPI
{
class Cyberlibs : Red::IScriptable
{
public:
    inline static Red::CString Version()
    {
        return CyberlibsCore::GameModules::GetVersion("Cyberlibs.dll");
    }

    static void Help(Red::Optional<int32_t> number, Red::Optional<bool> forceLog) {}
    inline static void SetPrintingStyle(bool isEnabled) {}

    inline static Red::CString GetVersion(const Red::CString& fileNameOrPath)
    {
        return CyberlibsCore::GameModules::GetVersion(fileNameOrPath);
    }

    inline static void PrintAttribute(const Red::CString& fileNameOrPath, const Red::CString& attribute,
                               Red::Optional<bool> forceLog) {}
    inline static void PrintExport(const Red::CString& fileNameOrPath, Red::Optional<bool> forceLog) {}
    inline static void PrintImport(const Red::CString& fileNameOrPath, Red::Optional<bool> forceLog) {}
    inline static void PrintIsLoaded(const Red::CString& fileNameOrPath, Red::Optional<bool> forceLog) {}
    inline static void PrintLoadedModules(Red::Optional<bool> forceLog){}
    inline static void PrintTimeDateStamp(const Red::CString& fileNameOrPath, Red::Optional<bool> forceLog) {}
    inline static void PrintVersion(const Red::CString& fileNameOrPath, Red::Optional<bool> forceLog) {}

    RTTI_IMPL_TYPEINFO(CyberlibsAPI::Cyberlibs);
    RTTI_IMPL_ALLOCATOR();
};
} // namespace CyberlibsAPI

RTTI_DEFINE_CLASS(CyberlibsAPI::Cyberlibs,
{
    RTTI_ALIAS("CyberlibsAPI.Cyberlibs");

    RTTI_METHOD(Help);
    RTTI_METHOD(Version);
    RTTI_METHOD(SetPrintingStyle);

    RTTI_METHOD(GetVersion);

    RTTI_METHOD(PrintAttribute);
    RTTI_METHOD(PrintExport);
    RTTI_METHOD(PrintImport);
    RTTI_METHOD(PrintIsLoaded);
    RTTI_METHOD(PrintLoadedModules);
    RTTI_METHOD(PrintTimeDateStamp);
    RTTI_METHOD(PrintVersion);
});
