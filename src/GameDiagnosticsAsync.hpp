#pragma once

#include <RED4ext/RED4ext.hpp>
#include <RedLib.hpp>
#include <sha256.h>
#include "GameDiagnostics.hpp"

#include <string>
#include <vector>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <sstream>

namespace CyberlibsCore
{
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

    void Error(const Red::CString& err) const
    {
        if (target.Expired() || onError.IsNone())
            return;

        Red::CallVirtual(target.Lock(), onError, err, filePath);
    }
};

struct GameDiagnosticsVerifyPathsPromise
{
public:
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

struct GameDiagnosticsAsync : Red::IScriptable
{
public:
    void GetFileHash(const Red::CString& relativeFilePath, const GameDiagnosticsHashPromise& promise);
    void VerifyPaths(const Red::CString& relativePathsFilePath,
                                 const GameDiagnosticsVerifyPathsPromise& promise);

    RTTI_IMPL_TYPEINFO(CyberlibsCore::GameDiagnosticsAsync);
    RTTI_IMPL_ALLOCATOR();

private:
    struct LineValidation
    {
        std::string path;
        bool shouldExist;
        std::string expectedHash;
    };

    static constexpr size_t MAX_INPUT_FILE_SIZE = 5 * 1024 * 1024;
    static constexpr size_t MAX_OUTPUT_FILE_SIZE = 5 * 1024 * 1024;
    static constexpr const char* FILE_LOCKED = "File locked";
    static constexpr const char* FILE_READ_FAIL = "Failed to read file";
    static constexpr const char* INVALID_GAME_PATH = "Invalid game path";
    static constexpr const char* UNKNOWN_VALUE = "Unknown";
    static constexpr const char* VALID_TEXT_EXTENSIONS[] = {".txt", ".log", ".md"};

    static bool isPathSafe(const std::filesystem::path& path);
    static bool isValidUtf8(const std::string& str);
    static std::string normalizePathString(std::string path);
    inline static std::string normalizePathString(const Red::CString& path)
    {
        return normalizePathString(std::string(path.c_str()));
    }

    static std::vector<LineValidation> readLines(const std::filesystem::path& path);
};
} // namespace CyberlibsCore

RTTI_DEFINE_CLASS(CyberlibsCore::GameDiagnosticsHashPromise, {
    RTTI_ALIAS("CyberlibsCore.GameDiagnosticsHashPromise");

    RTTI_PROPERTY(target);
    RTTI_PROPERTY(onSuccess, "success");
    RTTI_PROPERTY(onError, "error");
    RTTI_PROPERTY(filePath);
});

RTTI_DEFINE_CLASS(CyberlibsCore::GameDiagnosticsVerifyPathsPromise, {
    RTTI_ALIAS("CyberlibsCore.GameDiagnosticsVerifyPathsPromise");

    RTTI_PROPERTY(target);
    RTTI_PROPERTY(onComplete, "complete");
    RTTI_PROPERTY(filePath);
});

RTTI_DEFINE_CLASS(CyberlibsCore::GameDiagnosticsAsync, {
    RTTI_ALIAS("CyberlibsCore.GameDiagnosticsAsync");

    RTTI_METHOD(GetFileHash);
    RTTI_METHOD(VerifyPaths);
});
