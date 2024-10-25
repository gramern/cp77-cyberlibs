#include "GameDiagnostics.hpp"

bool CyberlibsCore::GameDiagnostics::CreateDiagnosticsDir(const Red::CString& relativePath)
{
    try
    {
        auto path = getOutputPath(relativePath);
        if (path.empty())
        {
            return false;
        }
        return ensureDirectoryExists(path);
    }
    catch (const std::exception&)
    {
        return false;
    }
}

Red::CString CyberlibsCore::GameDiagnostics::GetGamePath()
{
    wchar_t path[MAX_PATH];
    if (GetModuleFileNameW(NULL, path, MAX_PATH) != 0)
    {
        std::filesystem::path gamePath = path;
        gamePath = gamePath.parent_path().parent_path().parent_path();
        return Red::CString(gamePath.string().c_str());
    }
    return Red::CString("");
}

Red::CString CyberlibsCore::GameDiagnostics::GetTimestamp(Red::Optional<bool> pathFriendly)
{
    auto now = std::chrono::system_clock::now();
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;
    auto time = std::chrono::system_clock::to_time_t(now);
    std::stringstream ss;

    if (!pathFriendly)
    {
        ss << std::put_time(std::localtime(&time), "%Y-%m-%d %H:%M:%S");
        ss << "." << std::setfill('0') << std::setw(3) << ms.count();
    }
    else
    {
        ss << std::put_time(std::localtime(&time), "%Y-%m-%d-%H-%M-%S");
    }

    return Red::CString(ss.str().c_str());
}

bool CyberlibsCore::GameDiagnostics::IsGameFile(const Red::CString& relativeFilePath)
{
    try
    {
        auto gamePath = GetGamePath();
        if (gamePath.Length() == 0)
        {
            return false;
        }

        std::filesystem::path fullPath = std::filesystem::path(gamePath.c_str()) / relativeFilePath.c_str();
        return std::filesystem::exists(fullPath) && std::filesystem::is_regular_file(fullPath);
    }
    catch (const std::exception&)
    {
        return false;
    }
}

bool CyberlibsCore::GameDiagnostics::IsGameDir(const Red::CString& relativePath)
{
    try
    {
        auto gamePath = GetGamePath();
        if (gamePath.Length() == 0)
        {
            return false;
        }

        std::filesystem::path fullPath = std::filesystem::path(gamePath.c_str()) / relativePath.c_str();
        return std::filesystem::exists(fullPath) && std::filesystem::is_directory(fullPath);
    }
    catch (const std::exception&)
    {
        return false;
    }
}

bool CyberlibsCore::GameDiagnostics::WriteToOutput(const Red::CString& relativeFilePath, const Red::CString& content,
                                                   Red::Optional<bool> append)
{
    constexpr size_t MAX_FILE_SIZE = 100 * 1024 * 1024; // 100MB limit

    try
    {
        std::filesystem::path fullPath = getOutputPath(relativeFilePath);
        if (fullPath.empty())
        {
            return false;
        }

        if (append && std::filesystem::exists(fullPath))
        {
            std::error_code ec;
            auto fileSize = std::filesystem::file_size(fullPath, ec);
            if (!ec && fileSize + content.Length() > MAX_FILE_SIZE)
            {
                return false;
            }
        }

        auto parentPath = fullPath.parent_path();
        if (!parentPath.empty() && !ensureDirectoryExists(parentPath))
        {
            return false;
        }

        std::ios_base::openmode mode = std::ios::out | std::ios::binary;
        if (append)
        {
            mode |= std::ios::app;
        }

        std::ofstream file(fullPath, mode);
        if (!file.is_open())
        {
            return false;
        }

        file.exceptions(std::ios::badbit | std::ios::failbit);
        file.write(content.c_str(), content.Length());

        return !file.fail();
    }
    catch (const std::exception&)
    {
        return false;
    }
}

// Private Helpers

bool CyberlibsCore::GameDiagnostics::ensureDirectoryExists(const std::filesystem::path& path)
{
    try
    {
        if (!std::filesystem::exists(path))
        {
            return std::filesystem::create_directories(path);
        }
        return std::filesystem::is_directory(path);
    }
    catch (const std::exception&)
    {
        return false;
    }
}

std::filesystem::path CyberlibsCore::GameDiagnostics::getOutputPath(const Red::CString& relativePath)
{
    try
    {
        auto gamePath = GetGamePath();
        if (gamePath.Length() == 0)
        {
            return std::filesystem::path();
        }

        std::string cleanPath = relativePath.c_str();
        if (cleanPath.empty())
        {
            return std::filesystem::path();
        }

        while (!cleanPath.empty() && (cleanPath[0] == '/' || cleanPath[0] == '\\' || cleanPath[0] == '.'))
        {
            cleanPath = cleanPath.substr(1);
        }

        if (cleanPath.empty())
        {
            return std::filesystem::path();
        }

        std::filesystem::path basePath = std::filesystem::path(gamePath.c_str()) / "_DIAGNOSTICS";
        std::filesystem::path fullPath = basePath / cleanPath;
        std::filesystem::path normalizedPath = fullPath.lexically_normal();
        std::string basePathStr = basePath.lexically_normal().string();

        if (normalizedPath.string().substr(0, basePathStr.length()) != basePathStr)
        {
            return std::filesystem::path();
        }

        return normalizedPath;
    }
    catch (const std::exception&)
    {
        return std::filesystem::path();
    }
}

bool CyberlibsCore::GameDiagnostics::isPathSafe(const std::filesystem::path& path)
{
    try
    {
        auto gamePath = std::filesystem::path(GetGamePath().c_str()).lexically_normal();
        auto normalizedPath = path.lexically_normal();
        auto gamePathStr = gamePath.string();
        auto normalizedPathStr = normalizedPath.string();

        return normalizedPathStr.substr(0, gamePathStr.length()) == gamePathStr;
    }
    catch (const std::exception&)
    {
        return false;
    }
}
