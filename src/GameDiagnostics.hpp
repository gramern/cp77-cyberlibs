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
struct GameDiagnostics : Red::IScriptable
{
public:
    static Red::CString GetCurrentTimeDate(Red::Optional<bool> pathFirendly);
    static Red::CString GetGamePath();
    static Red::CString GetTimeDateStamp(const Red::CString& relativeFilePath, Red::Optional<bool> pathFriendly);
    static bool IsFile(const Red::CString& relativeFilePath);
    static bool IsDirectory(const Red::CString& relativePath);
    static Red::DynArray<GameDiagnosticsPathEntry> ListDirectory(const Red::CString& relativePath);
    static Red::CString ReadTextFile(const Red::CString& relativeFilePath);
    static bool VerifyPaths(const Red::CString& relativePathsFilePath);
    static bool WriteToOutput(const Red::CString& relativeFilePath, const Red::CString& content,
                            Red::Optional<bool> append);

    RTTI_IMPL_TYPEINFO(CyberlibsCore::GameDiagnostics);
    RTTI_IMPL_ALLOCATOR();

private:
    static constexpr size_t MAX_INPUT_FILE_SIZE = 6 * 1024 * 1024;
    static constexpr size_t MAX_OUTPUT_FILE_SIZE = 5 * 1024 * 1024;
    static constexpr const char* VALID_TEXT_EXTENSIONS[] = {".txt", ".log", ".md"};

    struct PathValidation
    {
        std::string path;
        bool shouldExist;
    };

    static std::filesystem::path getOutputPath(const Red::CString& relativePath);
    static bool ensureDirectoryExists(const std::filesystem::path& path);
    static bool isPathSafe(const std::filesystem::path& path);
    static bool isTextFile(const std::filesystem::path& path);
    static bool isValidUtf8(const std::string& str);
    static std::string normalizePathString(std::string path);
    inline static std::string normalizePathString(const Red::CString& path)
    {
        return normalizePathString(std::string(path.c_str()));
    }

    static std::vector<PathValidation> readLines(const std::filesystem::path& path);
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
    RTTI_METHOD(VerifyPaths);
    RTTI_METHOD(WriteToOutput);
});
