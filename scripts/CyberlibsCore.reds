// Cyberlibs 0.2.0
module CyberlibsCore

public native class Cyberlibs {
  // returns Cyberlibs version
  public static native func Version() -> String;

  // public API - CET app required
  public static native func Help(opt number: Int32) -> Void;
  public static native func SetPrintingStyle(isEnabled: Bool) -> Void;
  // returns a module version from file OR the mod's lua knowledge base
  public static native func GetVersion(fileNameOrPath: String) -> String;
  public static native func PrintAttribute(fileNameOrPath: String, attribute: String, opt dump: Bool) -> Void;
  public static native func PrintExport(fileNameOrPath: String, opt dump: Bool) -> Void;
  public static native func PrintImport(fileNameOrPath: String, opt dump: Bool) -> Void;
  public static native func PrintIsLoaded(fileNameOrPath: String, opt dump: Bool) -> Void;
  public static native func PrintLoadedModules(opt dump: Bool) -> Void;
  public static native func PrintVersion(fileNameOrPath: String, opt dump: Bool) -> Void;
}

public native class GameDiagnostics {
  public static native func GetGamePath() -> String;
  public static native func GetTimeDateStamp(opt pathFriendly: Bool) -> String;
  public static native func IsFile(relativeFilePath: String) -> Bool;
  public static native func IsDirectory(relativePath: String) -> Bool;
  public static native func WriteToOutput(relativeFilePath: String, content: String, opt append: Bool) -> Bool;
}

public native struct GameDiagnosticsPathEntry {
  native let name: String;
  native let type: String;
}

public native class GameModules {
  public static native func GetCompanyName(fileNameOrPath: String) -> String;
  public static native func GetDescription(fileNameOrPath: String) -> String;
  public static native func GetEntryPoint(fileNameOrPath: String) -> String;
  public static native func GetExport(fileNameOrPath: String) -> array<GameModulesExportEntry>;
  public static native func GetFilePath(fileNameOrPath: String) -> String;
  public static native func GetFileSize(fileNameOrPath: String) -> String;
  public static native func GetImport(fileNameOrPath: String) -> array<GameModulesImportEntry>;
  public static native func GetLoadAddress(fileNameOrPath: String) -> String;
  public static native func GetLoadedModules() -> array<String>;
  public static native func GetMappedSize(fileNameOrPath: String) -> String;
  public static native func GetTimeDateStamp(fileNameOrPath: String) -> String;
  public static native func GetVersion(fileNameOrPath: String) -> String;
  public static native func IsLoaded(fileNameOrPath: String) -> Bool;
}

public native struct GameModulesExportEntry {
  native let entry: String;
  native let ordinal: Int32;
  native let rva: Int32;
  native let forwarderName: String;
}

public native struct GameModulesImportEntry {
  native let fileName: String;
  native let entries: array<String>;
}
