#pragma once

#include <RED4ext/RED4ext.hpp>
#include <RedLib.hpp>

#include <string>
#include <vector>
#include <windows.h>
#include <psapi.h>

Red::DynArray<Red::CString> GetModules(DWORD flags);
Red::DynArray<Red::CString> GetModules64();
Red::DynArray<Red::CString> GetModules32();
bool IsValidPath(const std::wstring& modulePath);
std::wstring ResolvePath(const Red::CString& moduleFileOrPath);
std::vector<BYTE> GetVersionInfo(const std::wstring& modulePath);
Red::CString GetVersionInfoString(const std::vector<BYTE>& verData, const wchar_t* key);
Red::CString WideCharToRedString(const std::wstring& wide);
