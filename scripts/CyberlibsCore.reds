// Cyberlibs 0.2.0.0
module CyberlibsCore

public native class GameDiagnostics {
  public static native func GetGamePath() -> String;
  public static native func GetTimestamp(opt pathFriendly: Bool) -> String;
  public static native func IsFile(relativeFilePath: String) -> Bool;
  public static native func IsDirectory(relativePath: String) -> Bool;
  public static native func WriteToOutput(relativeFilePath: String, content: String, opt append: Bool) -> Bool;
}

public native class GameModules {
  public static native func GetCompanyName(fileNameOrPath: String) -> String;
  public static native func GetDescription(fileNameOrPath: String) -> String;
  public static native func GetEntryPoint(fileNameOrPath: String) -> String;
  public static native func GetExport(fileNameOrPath: String) -> array<GameModulesExportArray>;
  public static native func GetFilePath(fileNameOrPath: String) -> String;
  public static native func GetFileSize(fileNameOrPath: String) -> String;
  public static native func GetImport(fileNameOrPath: String) -> array<GameModulesImportArray>;
  public static native func GetLoadAddress(fileNameOrPath: String) -> String;
  public static native func GetLoadedModules() -> array<String>;
  public static native func GetMappedSize(fileNameOrPath: String) -> String;
  public static native func GetTimeDateStamp(fileNameOrPath: String) -> String;
  public static native func GetVersion(fileNameOrPath: String) -> String;
  public static native func IsLoaded(fileNameOrPath: String) -> Bool;
}

public native struct GameModulesExportArray {
  native let entry: String;
  native let ordinal: Int32;
  native let rva: Int32;
  native let forwarderName: String;
}

public native struct GameModulesImportArray {
  native let fileName: String;
  native let entries: array<String>;
}
