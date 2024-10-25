#pragma once

#include <RED4ext/RED4ext.hpp>
#include <RedLib.hpp>

#include <chrono>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <sstream>
#include <string>

namespace CyberlibsCore
{
class GameDiagnostics : Red::IScriptable
{
public:
    static Red::CString GetGamePath();
    static Red::CString GetTimestamp(Red::Optional<bool> pathFirendly);
    static bool CreateDiagnosticsDir(const Red::CString& relativePath);
    static bool IsGameFile(const Red::CString& relativeFilePath);
    static bool IsGameDir(const Red::CString& relativePath);
    static bool WriteToOutput(const Red::CString& relativeFilePath, const Red::CString& content,
                            Red::Optional<bool> append);

    RTTI_IMPL_TYPEINFO(CyberlibsCore::GameDiagnostics);
    RTTI_IMPL_ALLOCATOR();

private:
    static std::filesystem::path getOutputPath(const Red::CString& relativePath);
    static bool ensureDirectoryExists(const std::filesystem::path& path);
    static bool isPathSafe(const std::filesystem::path& path);
};
} // namespace CyberlibsCore

RTTI_DEFINE_CLASS(CyberlibsCore::GameDiagnostics, {
    RTTI_ALIAS("CyberlibsCore.GameDiagnostics");

    RTTI_METHOD(CreateDiagnosticsDir);
    RTTI_METHOD(GetGamePath);
    RTTI_METHOD(GetTimestamp);
    RTTI_METHOD(IsGameFile);
    RTTI_METHOD(IsGameDir);
    RTTI_METHOD(WriteToOutput);
});
