#include "GameDiagnostics.hpp"

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

bool CyberlibsCore::GameDiagnostics::IsFile(const Red::CString& relativeFilePath)
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

bool CyberlibsCore::GameDiagnostics::IsDirectory(const Red::CString& relativePath)
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

Red::DynArray<CyberlibsCore::GameDiagnosticsPathEntry> CyberlibsCore::GameDiagnostics::ListDirectory(
    const Red::CString& relativePath)
{
    Red::DynArray<GameDiagnosticsPathEntry> result;

    try
    {
        auto gamePath = GetGamePath();
        if (gamePath.Length() == 0)
        {
            return result;
        }

        std::filesystem::path fullPath = std::filesystem::path(gamePath.c_str()) / relativePath.c_str();
        fullPath = fullPath.lexically_normal();
        if (!isPathSafe(fullPath) || !std::filesystem::exists(fullPath) || !std::filesystem::is_directory(fullPath))
        {
            return result;
        }

        for (const auto& entry : std::filesystem::directory_iterator(fullPath))
        {
            GameDiagnosticsPathEntry dirEntry;
            dirEntry.name = Red::CString(entry.path().filename().string().c_str());
            dirEntry.type = entry.is_directory() ? Red::CString("dir") : Red::CString("file");
            result.PushBack(dirEntry);
        }
    }
    catch (const std::exception&)
    {
        result.Clear();
    }

    return result;
}

Red::CString CyberlibsCore::GameDiagnostics::ReadTextFile(const Red::CString& relativeFilePath)
{
    try
    {
        auto gamePath = GetGamePath();
        if (gamePath.Length() == 0)
        {
            return Red::CString("");
        }

        std::filesystem::path fullPath = std::filesystem::path(gamePath.c_str()) / relativeFilePath.c_str();
        fullPath = fullPath.lexically_normal();

        if (!isPathSafe(fullPath) || !std::filesystem::exists(fullPath) || !std::filesystem::is_regular_file(fullPath))
        {
            return Red::CString("");
        }

        if (!isTextFile(fullPath))
        {
            return Red::CString("");
        }

        const size_t MAX_FILE_SIZE = 10 * 1024 * 1024; //100MB limit
        auto fileSize = std::filesystem::file_size(fullPath);
        if (fileSize > MAX_FILE_SIZE)
        {
            return Red::CString("Requested file exceeds 100MB file size limit.");
        }

        std::ifstream file(fullPath, std::ios::in | std::ios::binary);
        if (!file.is_open())
        {
            return Red::CString("");
        }

        std::stringstream buffer;
        buffer << file.rdbuf();
        std::string content = buffer.str();
        bool isValidUtf8 = true;
        for (size_t i = 0; i < content.length();)
        {
            if ((content[i] & 0x80) == 0)
            {
                i++;
            }
            else if ((content[i] & 0xE0) == 0xC0)
            {
                if (i + 1 >= content.length() || (content[i + 1] & 0xC0) != 0x80)
                {
                    isValidUtf8 = false;
                    break;
                }
                i += 2;
            }
            else if ((content[i] & 0xF0) == 0xE0)
            {
                if (i + 2 >= content.length() || (content[i + 1] & 0xC0) != 0x80 || (content[i + 2] & 0xC0) != 0x80)
                {
                    isValidUtf8 = false;
                    break;
                }
                i += 3;
            }
            else if ((content[i] & 0xF8) == 0xF0)
            {
                if (i + 3 >= content.length() || (content[i + 1] & 0xC0) != 0x80 || (content[i + 2] & 0xC0) != 0x80 ||
                    (content[i + 3] & 0xC0) != 0x80)
                {
                    isValidUtf8 = false;
                    break;
                }
                i += 4;
            }
            else
            {
                isValidUtf8 = false;
                break;
            }
        }

        if (!isValidUtf8)
        {
            return Red::CString("");
        }

        return Red::CString(content.c_str());
    }
    catch (const std::exception&)
    {
        return Red::CString("");
    }
}

bool CyberlibsCore::GameDiagnostics::WriteToOutput(const Red::CString& relativeFilePath, const Red::CString& content,
                                                   Red::Optional<bool> append)
{
    constexpr size_t MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB limit

    try
    {
        const std::string_view path(relativeFilePath.c_str());
        if (path.find('/') == std::string_view::npos && path.find('\\') == std::string_view::npos)
        {
            return false;
        }


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

bool CyberlibsCore::GameDiagnostics::isTextFile(const std::filesystem::path& path)
{
    std::string extension = path.extension().string();
    std::transform(extension.begin(), extension.end(), extension.begin(), ::tolower);
    return extension == ".txt" || extension == ".log" || extension == ".md";
}


