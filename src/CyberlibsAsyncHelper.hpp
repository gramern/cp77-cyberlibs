#pragma once

#include <RED4ext/RED4ext.hpp>
#include <RedLib.hpp>

namespace CyberlibsCore
{
class CyberlibsAsyncHelper : public Red::IGameSystem
{
public:
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

RTTI_DEFINE_CLASS(CyberlibsCore::CyberlibsAsyncHelper, {
    RTTI_ALIAS("CyberlibsCore.CyberlibsAsyncHelper");

    RTTI_METHOD(IsAttached);
});
