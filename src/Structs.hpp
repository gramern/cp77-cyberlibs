#pragma once

#include <RED4ext/RED4ext.hpp>
#include <RedLib.hpp>

namespace CyberlibsCore
{

struct CyberlibsAsyncHelperHashQuery
{
public:
    Red::CString hash;
    Red::CString filePath;
    bool isCalculating;
};

struct CyberlibsAsyncHelperVerifyPathsQuery
{
public:
    bool isValid;
    Red::CString filePath;
    bool isCalculating;
};

struct GameDiagnosticsHashPromise
{
public:
    Red::WeakHandle<Red::IScriptable> target;
    Red::CName onSuccess;
    Red::CName onError;
    Red::CString filePath;

    void Success(const Red::CString& hash) const
    {
        if (target.Expired())
            return;

        Red::CallVirtual(target.Lock(), onSuccess, hash, filePath);
    }

    void Error(const Red::CString& error) const
    {
        if (target.Expired() || onError.IsNone())
            return;

        Red::CallVirtual(target.Lock(), onError, error, filePath);
    }
};

struct GameDiagnosticsPathEntry
{
    Red::CString name;
    Red::CString type;
};

struct GameDiagnosticsVerifyPathsPromise
{
    Red::WeakHandle<Red::IScriptable> target;
    Red::CName onComplete;
    Red::CString filePath;

    void Resolve(bool isValid) const
    {
        if (target.Expired())
            return;

        Red::CallVirtual(target.Lock(), onComplete, isValid, filePath);
    }
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

RTTI_DEFINE_CLASS(CyberlibsCore::CyberlibsAsyncHelperHashQuery, {
    RTTI_ALIAS("CyberlibsCore.CyberlibsAsyncHelperHashQuery");

    RTTI_PROPERTY(hash);
    RTTI_PROPERTY(filePath);
    RTTI_PROPERTY(isCalculating);
});

RTTI_DEFINE_CLASS(CyberlibsCore::CyberlibsAsyncHelperVerifyPathsQuery, {
    RTTI_ALIAS("CyberlibsCore.CyberlibsAsyncHelperVerifyPathsQuery");

    RTTI_PROPERTY(isValid);
    RTTI_PROPERTY(filePath);
    RTTI_PROPERTY(isCalculating);
});

RTTI_DEFINE_CLASS(CyberlibsCore::GameDiagnosticsHashPromise, {
    RTTI_ALIAS("CyberlibsCore.GameDiagnosticsHashPromise");

    RTTI_PROPERTY(target);
    RTTI_PROPERTY(onSuccess, "success");
    RTTI_PROPERTY(onError, "error");
    RTTI_PROPERTY(filePath);
});

RTTI_DEFINE_CLASS(CyberlibsCore::GameDiagnosticsPathEntry, {
    RTTI_ALIAS("CyberlibsCore.GameDiagnosticsPathEntry");

    RTTI_PROPERTY(name);
    RTTI_PROPERTY(type);
});

 RTTI_DEFINE_CLASS(CyberlibsCore::GameDiagnosticsVerifyPathsPromise, {
    RTTI_ALIAS("CyberlibsCore.GameDiagnosticsVerifyPathsPromise");

    RTTI_PROPERTY(target);
    RTTI_PROPERTY(onComplete, "complete");
    RTTI_PROPERTY(filePath);
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
