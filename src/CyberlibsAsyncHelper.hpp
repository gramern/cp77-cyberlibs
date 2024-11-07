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

class CyberlibsAsyncHelper : public Red::IGameSystem
{
public:
    struct HashQuery
    {
    public:
        Red::CString hash;
        Red::CString filePath;
        bool isCalculating;
    };

    struct VerifyPathsQuery
    {
    public:
        bool isValid;
        Red::CString filePath;
        bool isCalculating;
    };

    bool IsAttached() const
    {
        return attached;
    }

private:
    void OnWorldAttached(Red::world::RuntimeScene* scene) override
    {
        attached = true;
    }

    void OnWorldDetached(Red::world::RuntimeScene* scene) override
    {
        attached = false;
    }

    bool attached{};

    RTTI_IMPL_TYPEINFO(CyberlibsCore::CyberlibsAsyncHelper);
    RTTI_IMPL_ALLOCATOR();
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

RTTI_DEFINE_CLASS(CyberlibsCore::CyberlibsAsyncHelper, {
    RTTI_ALIAS("CyberlibsCore.CyberlibsAsyncHelper");

    RTTI_METHOD(IsAttached);
});
