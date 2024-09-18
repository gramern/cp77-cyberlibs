#pragma once

#include <RED4ext/RED4ext.hpp>

void LibInspector_IsLibraryLoaded(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, bool* aOut, int64_t a4);
void LibInspector_GetVersionAsString(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, RED4ext::CString* aOut, int64_t a4);
