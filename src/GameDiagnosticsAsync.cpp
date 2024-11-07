#include "GameDiagnosticsAsync.hpp"

void CyberlibsCore::GameDiagnosticsAsync::GetFileHash(const Red::CString& relativeFilePath,
                                                      const CyberlibsCore::GameDiagnosticsHashPromise& promise)
{
    Red::JobQueue job_queue;

    job_queue.Dispatch(
        [relativeFilePath, promise]() -> void
        {
            try
            {
                auto gamePath = GameDiagnostics::GetGamePath();
                if (gamePath.Length() == 0)
                {
                    promise.Error(INVALID_GAME_PATH);

                    return;
                }

                std::string normalizedPath = normalizePathString(relativeFilePath);
                std::filesystem::path fullPath = std::filesystem::path(gamePath.c_str()) / normalizedPath;
                fullPath = fullPath.lexically_normal();
                if (!isPathSafe(fullPath) || !std::filesystem::exists(fullPath) ||
                    !std::filesystem::is_regular_file(fullPath))
                {
                    promise.Error(UNKNOWN_VALUE);

                    return;
                }

                HANDLE hFile =
                    CreateFileW(fullPath.c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                                NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, NULL);

                if (hFile == INVALID_HANDLE_VALUE)
                {
                    promise.Error(FILE_LOCKED);

                    return;
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
                        promise.Error(FILE_READ_FAIL);

                        return;
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

                promise.Success(Red::CString(hashStr));
            }
            catch (const std::exception& e)
            {
                std::string errorMsg = "Exception: ";
                errorMsg += e.what();
                promise.Error(Red::CString(errorMsg.c_str()));
            }
        });
}

void CyberlibsCore::GameDiagnosticsAsync::VerifyPaths(const Red::CString& relativePathsFilePath,
                                                      const GameDiagnosticsVerifyPathsPromise& promise)
{
    Red::JobQueue job_queue;

    job_queue.Dispatch(
        [relativePathsFilePath, promise]() -> void
        {
            try
            {
                auto gamePath = GameDiagnostics::GetGamePath();
                if (gamePath.Length() == 0)
                {
                    promise.Resolve(false);

                    return;
                }

                std::string normalizedInputPath = relativePathsFilePath.c_str();
                std::replace(normalizedInputPath.begin(), normalizedInputPath.end(), '\\', '/');
                std::filesystem::path inputPath = std::filesystem::path(gamePath.c_str()) / normalizedInputPath;
                inputPath = inputPath.lexically_normal();

                if (!isPathSafe(inputPath) || !std::filesystem::exists(inputPath) ||
                    !std::filesystem::is_regular_file(inputPath))
                {
                    promise.Resolve(false);

                    return;
                }

                auto fileSize = std::filesystem::file_size(inputPath);
                if (fileSize > MAX_INPUT_FILE_SIZE)
                {
                    promise.Resolve(false);
                    return;
                }

                auto extension = inputPath.extension().string();
                std::transform(extension.begin(), extension.end(), extension.begin(), ::tolower);
                if (extension != ".paths")
                {
                    promise.Resolve(false);
                    return;
                }

                std::ifstream file(inputPath, std::ios::binary);
                if (!file.is_open())
                {
                    promise.Resolve(false);
                    return;
                }

                std::string fileContent((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
                file.close();

                if (!isValidUtf8(fileContent))
                {
                    promise.Resolve(false);
                    return;
                }

                auto validations = readLines(inputPath);
                if (validations.empty())
                {
                    promise.Resolve(false);

                    return;
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
                        promise.Resolve(false);

                        return;
                    }

                    bool exists = std::filesystem::exists(pathToCheck);
                    if (validation.shouldExist != exists)
                    {
                        promise.Resolve(false);

                        return;
                    }
                }

                promise.Resolve(true);
            }
            catch (const std::exception&)
            {
                promise.Resolve(false);
            }
        });
}

// Private Helpers

bool CyberlibsCore::GameDiagnosticsAsync::isPathSafe(const std::filesystem::path& path)
{
    try
    {
        auto gamePath = std::filesystem::path(GameDiagnostics::GetGamePath().c_str()).lexically_normal();
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

bool CyberlibsCore::GameDiagnosticsAsync::isValidUtf8(const std::string& str)
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

std::string CyberlibsCore::GameDiagnosticsAsync::normalizePathString(std::string path)
{
    std::replace(path.begin(), path.end(), '\\', '/');
    while (!path.empty() && (path[0] == '/' || path[0] == '\\'))
    {
        path = path.substr(1);
    }

    return path;
}

std::vector<CyberlibsCore::GameDiagnosticsAsync::LineValidation> CyberlibsCore::GameDiagnosticsAsync::readLines(
    const std::filesystem::path& path)
{
    std::vector<LineValidation> lines;
    std::ifstream file(path, std::ios::in | std::ios::binary);
    if (!file.is_open())
    {
        return lines;
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

        LineValidation validation;
        validation.expectedHash = "";
        if (line[0] == '!')
        {
            validation.shouldExist = false;
            line = line.substr(1);
            start = line.find_first_not_of(" \t");
            if (start != std::string::npos)
            {
                end = line.find_last_not_of(" \t");
                line = line.substr(start, end - start + 1);
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

            std::string hash = line.substr(pipePos + 1);
            start = hash.find_first_not_of(" \t");
            if (start != std::string::npos)
            {
                end = hash.find_last_not_of(" \t");
                validation.expectedHash = hash.substr(start, end - start + 1);
            }
        }
        else
        {
            validation.path = line;
        }

        if (!validation.path.empty())
        {
            lines.push_back(validation);
        }
    }

    return lines;
}
