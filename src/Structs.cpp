#include <Structs.hpp>

void CyberlibsCore::GameDiagnosticsHashPromise::Resolve(const Red::CString& hash) const
{
    if (target.Expired())
        return;

    if (data.size == 0)
    {
        Red::CallVirtual(target.Lock(), onSuccess, hash);
    }
    else
    {
        Red::CallVirtual(target.Lock(), onSuccess, hash, data);
    }
}

void CyberlibsCore::GameDiagnosticsHashPromise::Reject(const Red::CString& error) const
{
    if (target.Expired() || onError.IsNone())
        return;

    if (data.size == 0)
    {
        Red::CallVirtual(target.Lock(), onError, error);
    }
    else
    {
        Red::CallVirtual(target.Lock(), onError, error, data);
    }
}
