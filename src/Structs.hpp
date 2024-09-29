#pragma once

#include <RED4ext/RED4ext.hpp>
#include <RedLib.hpp>

namespace CyberlibsCore
{

struct GameModuleExportArray
{
    Red::CString entry;
    int32_t ordinal;
    int32_t rva;
    Red::CString forwarderName;
};

struct GameModuleImportArray
{
    Red::CString fileName;
    Red::DynArray<Red::CString> entries;
};
} // namespace CyberlibsCore

RTTI_DEFINE_CLASS(CyberlibsCore::GameModuleExportArray,
{
    RTTI_ALIAS("CyberlibsCore.GameModuleExportArray");

    RTTI_PROPERTY(entry);
    RTTI_PROPERTY(ordinal);
    RTTI_PROPERTY(rva);
    RTTI_PROPERTY(forwarderName);
});

RTTI_DEFINE_CLASS(CyberlibsCore::GameModuleImportArray,
{
    RTTI_ALIAS("CyberlibsCore.GameModuleImportArray");

    RTTI_PROPERTY(fileName);
    RTTI_PROPERTY(entries);
});
