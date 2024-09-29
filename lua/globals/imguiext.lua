local ImGuiExt = {
  _VERSION = { 0, 2, 0 }
}

function ImGuiExt.SetTooltip(string)
  if ImGui.IsItemHovered() then
    ImGui.BeginTooltip()
    ImGui.PushTextWrapPos(ImGui.GetFontSize() * 30)
    ImGui.TextWrapped(string)
    ImGui.PushTextWrapPos()
    ImGui.EndTooltip()
  end
end

return ImGuiExt