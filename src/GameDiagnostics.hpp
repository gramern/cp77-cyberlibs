#pragma once

#include <RED4ext/RED4ext.hpp>
#include <RedLib.hpp>
#include <Structs.hpp>

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
    static Red::CString GetCurrentTimeDate(Red::Optional<bool> pathFirendly);
    static Red::CString GetGamePath();
    static Red::CString GetTimeDateStamp(const Red::CString& relativeFilePath, Red::Optional<bool> pathFriendly);
    static bool IsFile(const Red::CString& relativeFilePath);
    static bool IsDirectory(const Red::CString& relativePath);
    static Red::DynArray<GameDiagnosticsPathEntry> ListDirectory(const Red::CString& relativePath);
    static Red::CString ReadTextFile(const Red::CString& relativeFilePath);
    static bool WriteToOutput(const Red::CString& relativeFilePath, const Red::CString& content,
                            Red::Optional<bool> append);

    RTTI_IMPL_TYPEINFO(CyberlibsCore::GameDiagnostics);
    RTTI_IMPL_ALLOCATOR();

private:
    static std::filesystem::path getOutputPath(const Red::CString& relativePath);
    static bool ensureDirectoryExists(const std::filesystem::path& path);
    static bool isPathSafe(const std::filesystem::path& path);
    static bool isTextFile(const std::filesystem::path& path);
    static bool isValidUtf8(const std::string& str);
};
} // namespace CyberlibsCore

RTTI_DEFINE_CLASS(CyberlibsCore::GameDiagnostics, {
    RTTI_ALIAS("CyberlibsCore.GameDiagnostics");

    RTTI_METHOD(GetCurrentTimeDate);
    RTTI_METHOD(GetGamePath);
    RTTI_METHOD(GetTimeDateStamp);
    RTTI_METHOD(IsFile);
    RTTI_METHOD(IsDirectory);
    RTTI_METHOD(ListDirectory);
    RTTI_METHOD(ReadTextFile);
    RTTI_METHOD(WriteToOutput);
});
