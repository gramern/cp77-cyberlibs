#pragma once

#include <RED4ext/RED4ext.hpp>
#include <RedLib.hpp>

namespace CyberlibsCore
{
class Cyberlibs : Red::IScriptable
{
public:
    static Red::CString Version();
    static void Help(Red::Optional<int32_t> number, Red::Optional<bool> forceLog) {}
    static void SetPrintingStyle(bool isEnabled) {}

    static Red::CString GetVersion(const Red::CString& fileNameOrPath);

    static void PrintAttribute(const Red::CString& fileNameOrPath, const Red::CString& attribute,
                               Red::Optional<bool> forceLog) {}
    static void PrintExport(const Red::CString& fileNameOrPath, Red::Optional<bool> forceLog) {}
    static void PrintImport(const Red::CString& fileNameOrPath, Red::Optional<bool> forceLog) {}
    static void PrintIsLoaded(const Red::CString& fileNameOrPath, Red::Optional<bool> forceLog) {}
    static void PrintLoadedModules(Red::Optional<bool> forceLog){}
    static void PrintTimeDateStamp(const Red::CString& fileNameOrPath, Red::Optional<bool> forceLog) {}
    static void PrintVersion(const Red::CString& fileNameOrPath, Red::Optional<bool> forceLog) {}

    RTTI_IMPL_TYPEINFO(CyberlibsCore::Cyberlibs);
    RTTI_IMPL_ALLOCATOR();
};
} // namespace CyberlibsCore

RTTI_DEFINE_CLASS(CyberlibsCore::Cyberlibs, {
    RTTI_ALIAS("CyberlibsCore.Cyberlibs");

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
