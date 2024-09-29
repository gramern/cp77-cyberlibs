#include "Cyberlibs.hpp"
#include "GameModule.hpp"

Red::CString CyberlibsCore::Cyberlibs::Version()
{
    return GameModule::GetVersion("Cyberlibs.dll");
}

Red::CString CyberlibsCore::Cyberlibs::GetVersion(const Red::CString& fileNameOrPath)
{
    return GameModule::GetVersion(fileNameOrPath);
}
