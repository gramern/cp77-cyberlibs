#pragma once

#include <RED4ext/RED4ext.hpp>
#include <RedLib.hpp>
#include "Helpers.hpp"
#include "Structs.hpp"

#include <string>
#include <vector>
#include <windows.h>
#include <psapi.h>

import libpe;

namespace CyberlibsCore
{
class GameModule : Red::IScriptable
{
public:
    static Red::CString GetCompanyName(const Red::CString& fileNameOrPath);
    static Red::CString GetDescription(const Red::CString& fileNameOrPath);
    static Red::CString GetEntryPoint(const Red::CString& fileNameOrPath);
    static Red::DynArray<GameModuleExportArray> GetExport(const Red::CString& fileNameOrPath);
    static Red::CString GetFilePath(const Red::CString& fileNameOrPath);
    static Red::CString GetFileSize(const Red::CString& fileNameOrPath);
    static Red::CString GetFileType(const Red::CString& fileNameOrPath);
    static Red::DynArray<GameModuleImportArray> GetImport(const Red::CString& fileNameOrPath);
    static Red::CString GetLoadAddress(const Red::CString& fileNameOrPath);
    static Red::DynArray<Red::CString> GetLoadedModules();
    static Red::CString GetMappedSize(const Red::CString& fileNameOrPath);
    static Red::CString GetTimeDateStamp(const Red::CString& fileNameOrPath);
    static Red::CString GetVersion(const Red::CString& fileNameOrPath);
    static bool IsLoaded(const Red::CString& fileNameOrPath);

    RTTI_IMPL_TYPEINFO(CyberlibsCore::GameModule);
    RTTI_IMPL_ALLOCATOR();
};
} // namespace CyberlibsCore

RTTI_DEFINE_CLASS(CyberlibsCore::GameModule,
{
    RTTI_ALIAS("CyberlibsCore.GameModule");

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
