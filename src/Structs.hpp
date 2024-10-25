#pragma once

#include <RED4ext/RED4ext.hpp>
#include <RedLib.hpp>

namespace CyberlibsCore
{

struct GameModulesExportArray
{
    Red::CString entry;
    int32_t ordinal;
    int32_t rva;
    Red::CString forwarderName;
};

struct GameModulesImportArray
{
    Red::CString fileName;
    Red::DynArray<Red::CString> entries;
};
} // namespace CyberlibsCore

RTTI_DEFINE_CLASS(CyberlibsCore::GameModulesExportArray,
{
    RTTI_ALIAS("CyberlibsCore.GameModulesExportArray");

    RTTI_PROPERTY(entry);
    RTTI_PROPERTY(ordinal);
    RTTI_PROPERTY(rva);
    RTTI_PROPERTY(forwarderName);
});

RTTI_DEFINE_CLASS(CyberlibsCore::GameModulesImportArray,
{
    RTTI_ALIAS("CyberlibsCore.GameModulesImportArray");

    RTTI_PROPERTY(fileName);
    RTTI_PROPERTY(entries);
});
