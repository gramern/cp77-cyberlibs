// Cyberlibs 0.2.0.0
module CyberlibsCore

public native class Cyberlibs {
  // returns Cyberlibs version
  public static native func Version() -> String;

  // returns a module version from file OR the mod's lua knowledge base
  public static native func GetVersion(fileNameOrPath: String) -> String;

  public static native func SetPrintingStyle(isEnabled: Bool) -> Void;
  public static native func Help(opt number: Int32, opt forceLog: Bool) -> Void;
  public static native func PrintAttribute(fileNameOrPath: String, attribute: String, opt forceLog: Bool) -> Void;
  public static native func PrintExport(fileNameOrPath: String, opt forceLog: Bool) -> Void;
  public static native func PrintImport(fileNameOrPath: String, opt forceLog: Bool) -> Void;
  public static native func PrintIsLoaded(fileNameOrPath: String, opt forceLog: Bool) -> Void;
  public static native func PrintLoadedModules(opt forceLog: Bool) -> Void;
  public static native func PrintVersion(fileNameOrPath: String, opt forceLog: Bool) -> Void;
}

public native class GameModule {
  public static native func GetCompanyName(fileNameOrPath: String) -> String;
  public static native func GetDescription(fileNameOrPath: String) -> String;
  public static native func GetEntryPoint(fileNameOrPath: String) -> String;
  public static native func GetExport(fileNameOrPath: String) -> array<GameModuleExportArray>;
  public static native func GetFilePath(fileNameOrPath: String) -> String;
  public static native func GetFileSize(fileNameOrPath: String) -> String;
  public static native func GetImport(fileNameOrPath: String) -> array<GameModuleImportArray>;
  public static native func GetLoadAddress(fileNameOrPath: String) -> String;
  public static native func GetLoadedModules() -> array<String>;
  public static native func GetMappedSize(fileNameOrPath: String) -> String;
  public static native func GetTimeDateStamp(fileNameOrPath: String) -> String;
  public static native func GetVersion(fileNameOrPath: String) -> String;
  public static native func IsLoaded(fileNameOrPath: String) -> Bool;
}

public native struct GameModuleExportArray {
  native let entry: String;
  native let ordinal: Int32;
  native let rva: Int32;
  native let forwarderName: String;
}

public native struct GameModuleImportArray {
  native let fileName: String;
  native let entries: array<String>;
}
