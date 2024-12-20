#include "GameDiagnostics.hpp"

Red::CString CyberlibsCore::GameDiagnostics::GetCurrentTimeDate(Red::Optional<bool> pathFriendly)
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

Red::CString CyberlibsCore::GameDiagnostics::GetFileHash(const Red::CString& relativeFilePath)
{
    try
    {
        auto gamePath = GetGamePath();
        if (gamePath.Length() == 0)
        {
            return INVALID_GAME_PATH;
        }

        std::string normalizedPath = normalizePathString(relativeFilePath);
        std::filesystem::path fullPath = std::filesystem::path(gamePath.c_str()) / normalizedPath;
        fullPath = fullPath.lexically_normal();
        if (!isPathSafe(fullPath) || !std::filesystem::exists(fullPath) || !std::filesystem::is_regular_file(fullPath))
        {
            return UNKNOWN_VALUE;
        }

        HANDLE hFile = CreateFileW(fullPath.c_str(), GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING,
                                   FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, NULL);

        if (hFile == INVALID_HANDLE_VALUE)
        {
            return FILE_LOCKED;
        }

        std::unique_ptr<void, decltype(&CloseHandle)> fileGuard(hFile, CloseHandle);
        struct sha256_buff sha_buff;
        sha256_init(&sha_buff);
        uint8_t buffer[8192];
        DWORD bytesRead = 0;

        while (true)
        {
            if (!ReadFile(hFile, buffer, sizeof(buffer), &bytesRead, NULL))
            {
                return FILE_READ_FAIL;
            }

            if (bytesRead == 0)
            {
                break;
            }

            sha256_update(&sha_buff, buffer, bytesRead);
        }

        sha256_finalize(&sha_buff);
        char hashStr[65] = {0};
        sha256_read_hex(&sha_buff, hashStr);

        return Red::CString(hashStr);
    }
    catch (const std::exception& e)
    {
        std::string errorMsg = "Exception: ";
        errorMsg += e.what();
        return Red::CString(errorMsg.c_str());
    }
}

Red::CString CyberlibsCore::GameDiagnostics::GetGamePath()
{
    try
    {
        wchar_t path[32768];
        DWORD length = GetModuleFileNameW(NULL, path, sizeof(path) / sizeof(wchar_t));
        if (length == 0 || length >= sizeof(path) / sizeof(wchar_t))
        {
            return INVALID_GAME_PATH;
        }

        std::filesystem::path gamePath = std::filesystem::path(path).lexically_normal();
        gamePath = gamePath.parent_path().parent_path().parent_path();

        return Red::CString(gamePath.string().c_str());
    }
    catch (const std::exception& e)
    {
        std::string errorMsg = "Exception: ";
        errorMsg += e.what();
        return Red::CString(errorMsg.c_str());
    }
}

Red::CString CyberlibsCore::GameDiagnostics::GetTimeDateStamp(const Red::CString& relativeFilePath,
                                                              Red::Optional<bool> pathFriendly)
{
    try
    {
        auto gamePath = GetGamePath();
        if (gamePath.Length() == 0)
        {
            return INVALID_GAME_PATH;
        }

        std::string normalizedPath = normalizePathString(relativeFilePath);
        std::filesystem::path fullPath = std::filesystem::path(gamePath.c_str()) / normalizedPath;
        fullPath = fullPath.lexically_normal();
        if (!isPathSafe(fullPath))
        {
            return UNKNOWN_VALUE;
        }

        WIN32_FILE_ATTRIBUTE_DATA fileInfo;
        if (!GetFileAttributesExW(fullPath.c_str(), GetFileExInfoStandard, &fileInfo))
        {
            return UNKNOWN_VALUE;
        }

        if ((fileInfo.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) ||
            (fileInfo.dwFileAttributes & FILE_ATTRIBUTE_DEVICE))
        {
            return UNKNOWN_VALUE;
        }

        SYSTEMTIME systemTime;
        FILETIME localFileTime;
        FileTimeToLocalFileTime(&fileInfo.ftLastWriteTime, &localFileTime);
        FileTimeToSystemTime(&localFileTime, &systemTime);

        char buffer[32];
        if (!pathFriendly)
        {
            snprintf(buffer, sizeof(buffer), "%04d-%02d-%02d %02d:%02d:%02d", systemTime.wYear, systemTime.wMonth,
                     systemTime.wDay, systemTime.wHour, systemTime.wMinute, systemTime.wSecond);
        }
        else
        {
            snprintf(buffer, sizeof(buffer), "%04d-%02d-%02d-%02d-%02d-%02d", systemTime.wYear, systemTime.wMonth,
                     systemTime.wDay, systemTime.wHour, systemTime.wMinute, systemTime.wSecond);
        }

        return Red::CString(buffer);
    }
    catch (const std::exception& e)
    {
        std::string errorMsg = "Exception: ";
        errorMsg += e.what();
        return Red::CString(errorMsg.c_str());
    }
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

        std::string normalizedPath = normalizePathString(relativeFilePath);
        std::filesystem::path fullPath = std::filesystem::path(gamePath.c_str()) / normalizedPath;
        fullPath = fullPath.lexically_normal();

        return isPathSafe(fullPath) && std::filesystem::exists(fullPath) && std::filesystem::is_regular_file(fullPath);
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

        std::string normalizedPath = normalizePathString(relativePath);
        std::filesystem::path fullPath = std::filesystem::path(gamePath.c_str()) / normalizedPath;
        fullPath = fullPath.lexically_normal();

        return isPathSafe(fullPath) && std::filesystem::exists(fullPath) && std::filesystem::is_directory(fullPath);
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

        std::string normalizedPath = normalizePathString(relativePath);
        std::filesystem::path fullPath = std::filesystem::path(gamePath.c_str()) / normalizedPath;
        fullPath = fullPath.lexically_normal();
        if (!isPathSafe(fullPath) || !std::filesystem::exists(fullPath) || !std::filesystem::is_directory(fullPath))
        {
            return result;
        }

        for (const auto& entry : std::filesystem::directory_iterator(fullPath))
        {
            GameDiagnosticsPathEntry dirEntry;
            std::string entryPath = entry.path().filename().string();
            std::replace(entryPath.begin(), entryPath.end(), '\\', '/');
            dirEntry.name = Red::CString(entryPath.c_str());
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
            return INVALID_GAME_PATH;
        }

        std::string normalizedPath = normalizePathString(relativeFilePath);
        std::filesystem::path fullPath = std::filesystem::path(gamePath.c_str()) / normalizedPath;
        fullPath = fullPath.lexically_normal();
        if (!isPathSafe(fullPath) || !std::filesystem::exists(fullPath) ||
            !std::filesystem::is_regular_file(fullPath) || !isTextFile(fullPath))
        {
            return UNKNOWN_VALUE;
        }

        HANDLE hFile = CreateFileW(fullPath.c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL,
                                   OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, NULL);

        if (hFile == INVALID_HANDLE_VALUE)
        {
            return FILE_LOCKED;
        }

        std::unique_ptr<void, decltype(&CloseHandle)> fileGuard(hFile, CloseHandle);

        LARGE_INTEGER fileSize;
        if (!GetFileSizeEx(hFile, &fileSize) || fileSize.QuadPart > MAX_OUTPUT_FILE_SIZE)
        {
            return FILE_READ_FAIL;
        }

        std::string content;
        content.resize(static_cast<size_t>(fileSize.QuadPart));
        DWORD bytesRead = 0;
        if (!ReadFile(hFile, content.data(), static_cast<DWORD>(content.size()), &bytesRead, NULL) ||
            bytesRead != content.size())
        {
            return FILE_READ_FAIL;
        }

        fileGuard.reset();

        if (!isValidUtf8(content))
        {
            return FILE_READ_FAIL;
        }

        return Red::CString(content.c_str());
    }
    catch (const std::exception& e)
    {
        std::string errorMsg = "Exception: ";
        errorMsg += e.what();
        return Red::CString(errorMsg.c_str());
    }
}

bool CyberlibsCore::GameDiagnostics::VerifyPaths(const Red::CString& relativePathsFilePath)
{
    try
    {
        auto gamePath = GetGamePath();
        if (gamePath.Length() == 0)
        {
            return false;
        }

        std::string normalizedInputPath = relativePathsFilePath.c_str();
        std::replace(normalizedInputPath.begin(), normalizedInputPath.end(), '\\', '/');
        std::filesystem::path inputPath = std::filesystem::path(gamePath.c_str()) / normalizedInputPath;
        inputPath = inputPath.lexically_normal();
        if (!isPathSafe(inputPath) || !std::filesystem::exists(inputPath) ||
            !std::filesystem::is_regular_file(inputPath))
        {
            return false;
        }

        auto fileSize = std::filesystem::file_size(inputPath);
        if (fileSize > MAX_INPUT_FILE_SIZE)
        {
            return false;
        }

        auto extension = inputPath.extension().string();
        std::transform(extension.begin(), extension.end(), extension.begin(), ::tolower);
        if (extension != ".paths")
        {
            return false;
        }

        std::ifstream file(inputPath, std::ios::binary);
        if (!file.is_open())
        {
            return false;
        }

        std::string fileContent((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
        file.close();

        if (!isValidUtf8(fileContent))
        {
            return false;
        }

        auto validations = readPaths(inputPath);
        if (validations.empty())
        {
            return false;
        }

        const std::filesystem::path gameRoot = std::filesystem::path(gamePath.c_str()).lexically_normal();

        for (const auto& validation : validations)
        {
            std::string cleanPath = validation.path;
            std::replace(cleanPath.begin(), cleanPath.end(), '\\', '/');
            if (cleanPath.empty() || cleanPath[0] == '#')
            {
                continue;
            }

            while (!cleanPath.empty() && (cleanPath[0] == '/' || cleanPath[0] == '\\'))
            {
                cleanPath = cleanPath.substr(1);
            }

            std::filesystem::path pathToCheck = gameRoot / cleanPath;
            pathToCheck = pathToCheck.lexically_normal();
            if (!isPathSafe(pathToCheck))
            {
                return false;
            }

            bool exists = std::filesystem::exists(pathToCheck);
            if (validation.shouldExist != exists)
            {
                return false;
            }
        }

        return true;
    }
    catch (const std::exception&)
    {
        return false;
    }
}

bool CyberlibsCore::GameDiagnostics::WriteToOutput(const Red::CString& relativeFilePath, const Red::CString& content,
                                                   Red::Optional<bool> append)
{
    try
    {
        std::string normalizedPath = normalizePathString(relativeFilePath);
        if (normalizedPath.find('/') == std::string::npos)
        {
            return false;
        }

        std::filesystem::path fullPath = getOutputPath(Red::CString(normalizedPath.c_str()));
        if (fullPath.empty())
        {
            return false;
        }

        if (append && std::filesystem::exists(fullPath))
        {
            std::error_code ec;
            auto fileSize = std::filesystem::file_size(fullPath, ec);
            if (!ec && fileSize + content.Length() > MAX_INPUT_FILE_SIZE)
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

    return std::any_of(
        std::begin(VALID_TEXT_EXTENSIONS),
        std::end(VALID_TEXT_EXTENSIONS),
        [&extension](const char* valid_ext) { return extension == valid_ext; }
    );
}

bool CyberlibsCore::GameDiagnostics::isValidUtf8(const std::string& str)
{
    const unsigned char* bytes = reinterpret_cast<const unsigned char*>(str.c_str());
    const size_t len = str.length();

    for (size_t i = 0; i < len;)
    {
        if (bytes[i] <= 0x7F)
        {
            i++;
            continue;
        }

        if (bytes[i] >= 0xC2 && bytes[i] <= 0xDF)
        {
            if (i + 1 >= len || (bytes[i + 1] & 0xC0) != 0x80)
                return false;
            i += 2;
            continue;
        }

        if (bytes[i] >= 0xE0 && bytes[i] <= 0xEF)
        {
            if (i + 2 >= len || (bytes[i + 1] & 0xC0) != 0x80 || (bytes[i + 2] & 0xC0) != 0x80)
                return false;

            if (bytes[i] == 0xE0 && (bytes[i + 1] < 0xA0))
                return false;
            if (bytes[i] == 0xED && (bytes[i + 1] >= 0xA0))
                return false;

            i += 3;
            continue;
        }

        if (bytes[i] >= 0xF0 && bytes[i] <= 0xF4)
        {
            if (i + 3 >= len || (bytes[i + 1] & 0xC0) != 0x80 || (bytes[i + 2] & 0xC0) != 0x80 ||
                (bytes[i + 3] & 0xC0) != 0x80)
                return false;

            if (bytes[i] == 0xF0 && (bytes[i + 1] < 0x90))
                return false;
            if (bytes[i] == 0xF4 && (bytes[i + 1] >= 0x90))
                return false;

            i += 4;
            continue;
        }

        return false;
    }

    return true;
}

std::string CyberlibsCore::GameDiagnostics::normalizePathString(std::string path)
{
    std::replace(path.begin(), path.end(), '\\', '/');
    while (!path.empty() && (path[0] == '/' || path[0] == '\\'))
    {
        path = path.substr(1);
    }

    return path;
}

std::vector<CyberlibsCore::GameDiagnostics::PathValidation> CyberlibsCore::GameDiagnostics::readPaths(
    const std::filesystem::path& path)
{
    std::vector<PathValidation> paths;
    std::ifstream file(path, std::ios::in | std::ios::binary);
    if (!file.is_open())
    {
        return paths;
    }

    std::string line;

    while (std::getline(file, line))
    {
        if (!line.empty() && line.back() == '\r')
        {
            line.pop_back();
        }

        if (line.empty() || line[0] == '#')
        {
            continue;
        }

        size_t start = line.find_first_not_of(" \t");
        if (start == std::string::npos)
        {
            continue;
        }

        size_t end = line.find_last_not_of(" \t");
        line = line.substr(start, end - start + 1);

        PathValidation validation;

        if (line[0] == '!')
        {
            validation.shouldExist = false;
            validation.path = line.substr(1);
            start = validation.path.find_first_not_of(" \t");
            if (start != std::string::npos)
            {
                end = validation.path.find_last_not_of(" \t");
                validation.path = validation.path.substr(start, end - start + 1);
            }
        }
        else
        {
            validation.shouldExist = true;
        }

        size_t pipePos = line.find('|');
        if (pipePos != std::string::npos)
        {
            validation.path = line.substr(0, pipePos);
            end = validation.path.find_last_not_of(" \t");
            validation.path = validation.path.substr(0, end + 1);
        }
        else
        {
            validation.path = line;
        }

        if (!validation.path.empty())
        {
            paths.push_back(validation);
        }
    }

    return paths;
}
