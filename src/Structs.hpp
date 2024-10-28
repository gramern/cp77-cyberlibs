#pragma once

#include <RED4ext/RED4ext.hpp>
#include <RedLib.hpp>

namespace CyberlibsCore
{

struct GameDiagnosticsPathEntry
{
    Red::CString name;
    Red::CString type;
};

struct GameModulesExportEntry
{
    Red::CString entry;
    int32_t ordinal;
    int32_t rva;
    Red::CString forwarderName;
};

struct GameModulesImportEntry
{
    Red::CString fileName;
    Red::DynArray<Red::CString> entries;
};
} // namespace CyberlibsCore

RTTI_DEFINE_CLASS(CyberlibsCore::GameDiagnosticsPathEntry, {
    RTTI_ALIAS("CyberlibsCore.GameDiagnosticsPathEntry");

    RTTI_PROPERTY(name);
    RTTI_PROPERTY(type);
});

RTTI_DEFINE_CLASS(CyberlibsCore::GameModulesExportEntry,
{
    RTTI_ALIAS("CyberlibsCore.GameModulesExportEntry");

    RTTI_PROPERTY(entry);
    RTTI_PROPERTY(ordinal);
    RTTI_PROPERTY(rva);
    RTTI_PROPERTY(forwarderName);
});

RTTI_DEFINE_CLASS(CyberlibsCore::GameModulesImportEntry,
{
    RTTI_ALIAS("CyberlibsCore.GameModulesImportEntry");

    RTTI_PROPERTY(fileName);
    RTTI_PROPERTY(entries);
});
