#include <RED4ext/RED4ext.hpp>
#include <string>
#include <vector>
#include <windows.h>

const RED4ext::Sdk* sdk;
RED4ext::PluginHandle pluginHandle;

void LibInspector_IsLibraryLoaded(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, bool* aOut, int64_t a4) {
    RED4EXT_UNUSED_PARAMETER(aContext);
    RED4EXT_UNUSED_PARAMETER(a4);

    RED4ext::CString libraryName;
    RED4ext::GetParameter(aFrame, &libraryName);
    aFrame->code++;

    std::wstring wLibraryName(libraryName.c_str(), libraryName.c_str() + libraryName.Length());
    HMODULE hLib = GetModuleHandleW(wLibraryName.c_str());

    bool isLoaded = (hLib != NULL);

    if (aOut) *aOut = isLoaded;
}

void LibInspector_GetVersionAsString(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, RED4ext::CString* aOut, int64_t a4)
{
    RED4EXT_UNUSED_PARAMETER(aContext);
    RED4EXT_UNUSED_PARAMETER(aFrame);
    RED4EXT_UNUSED_PARAMETER(a4);

    RED4ext::CString libraryName;
    RED4ext::GetParameter(aFrame, &libraryName);
    aFrame->code++;

    std::wstring wLibraryName(libraryName.c_str(), libraryName.c_str() + libraryName.Length());
    std::string versionStr = "Unknown";

    DWORD verSize = GetFileVersionInfoSizeW(wLibraryName.c_str(), NULL);
    if (verSize != 0)
    {
        std::vector<BYTE> verData(verSize);
        if (GetFileVersionInfoW(wLibraryName.c_str(), 0, verSize, verData.data()))
        {
            UINT size = 0;
            VS_FIXEDFILEINFO* verInfo = nullptr;
            if (VerQueryValueW(verData.data(), L"\\", (VOID FAR * FAR*) & verInfo, &size))
            {
                if (size >= sizeof(VS_FIXEDFILEINFO) && verInfo->dwSignature == 0xfeef04bd)
                {
                    char szVersion[32];
                    sprintf_s(szVersion, "%d.%d.%d.%d",
                        HIWORD(verInfo->dwFileVersionMS),
                        LOWORD(verInfo->dwFileVersionMS),
                        HIWORD(verInfo->dwFileVersionLS),
                        LOWORD(verInfo->dwFileVersionLS));
                    versionStr = szVersion;
                }
            }
        }
    }

    if (aOut)
    {
        *aOut = RED4ext::CString(versionStr.c_str());
    }
}

RED4EXT_C_EXPORT void RED4EXT_CALL RegisterTypes()
{
}

RED4EXT_C_EXPORT void RED4EXT_CALL PostRegisterTypes()
{
    auto rtti = RED4ext::CRTTISystem::Get();

    auto isLibraryLoadedFunc = RED4ext::CGlobalFunction::Create("LibInspector_IsLibraryLoaded", "LibInspector_IsLibraryLoaded", &LibInspector_IsLibraryLoaded);
    isLibraryLoadedFunc->AddParam("String", "libraryName");
    isLibraryLoadedFunc->SetReturnType("Bool");
    rtti->RegisterFunction(isLibraryLoadedFunc);

    auto getVersionStringFunc = RED4ext::CGlobalFunction::Create("LibInspector_GetVersionAsString", "LibInspector_GetVersionAsString", &LibInspector_GetVersionAsString);
    getVersionStringFunc->AddParam("String", "libraryName");
    getVersionStringFunc->SetReturnType("String");
    rtti->RegisterFunction(getVersionStringFunc);
}

RED4EXT_C_EXPORT bool RED4EXT_CALL Main(RED4ext::PluginHandle aHandle, RED4ext::EMainReason aReason, const RED4ext::Sdk* aSdk)
{
    sdk = aSdk;
    pluginHandle = aHandle;

    switch (aReason)
    {
    case RED4ext::EMainReason::Load:
    {
        auto rtti = RED4ext::CRTTISystem::Get();
        rtti->AddRegisterCallback(RegisterTypes);
        rtti->AddPostRegisterCallback(PostRegisterTypes);
        break;
    }
    case RED4ext::EMainReason::Unload:
    {
        break;
    }
    }

    return true;
}

RED4EXT_C_EXPORT void RED4EXT_CALL Query(RED4ext::PluginInfo* aInfo)
{
    aInfo->name = L"LibInspector";
    aInfo->author = L"gramern";
    aInfo->version = RED4EXT_SEMVER(0, 1, 0);
    aInfo->runtime = RED4EXT_RUNTIME_LATEST;
    aInfo->sdk = RED4EXT_SDK_LATEST;
}

RED4EXT_C_EXPORT uint32_t RED4EXT_CALL Supports()
{
    return RED4EXT_API_VERSION_LATEST;
}