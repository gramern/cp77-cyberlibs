// Cyberlibs 0.2.0.0
module CyberlibsAPI

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
