// Cyberlibs 0.2.1
module CyberlibsCore

public native class Cyberlibs extends IScriptable {
  // returns Cyberlibs version
  public static native func Version() -> String;

  // public API - CET app required
  public static native func Help(opt number: Int32) -> Void;
  public static native func SetPrintingStyle(isEnabled: Bool) -> Void;
  // returns a module version read from a file OR the mod's lua knowledge base
  public static native func GetVersion(fileNameOrPath: String) -> String;
  public static native func PrintAttribute(fileNameOrPath: String, attribute: String, opt dump: Bool) -> Void;
  public static native func PrintExport(fileNameOrPath: String, opt dump: Bool) -> Void;
  public static native func PrintImport(fileNameOrPath: String, opt dump: Bool) -> Void;
  public static native func PrintIsLoaded(fileNameOrPath: String, opt dump: Bool) -> Void;
  public static native func PrintLoadedModules(opt dump: Bool) -> Void;
  public static native func PrintModuleInfo(fileNameOrPath: String, opt dump: Bool) -> Void;
  public static native func PrintVersion(fileNameOrPath: String, opt dump: Bool) -> Void;
}

public native class CyberlibsAsyncHelper extends IGameSystem {
  private let m_hashes: array<CyberlibsAsyncHelperHashQuery>;
  private let m_maxCachedHashes: Int32 = 32;
  private let m_verifiedPaths: array<CyberlibsAsyncHelperVerifyPathsQuery>;
  private let m_maxCachedVerifyPathsResults: Int32 = 32;

  public native func IsAttached() -> Bool;

  private func OnHashResolved(hash: String, filePath: String) {
    let queryIndex = -1;
    let i = 0;

    while i < ArraySize(this.m_hashes) {
      if Equals(this.m_hashes[i].filePath, filePath) {
        queryIndex = i;
        break;
      }

      i += 1;
    }

    if queryIndex >= 0 {
      this.m_hashes[queryIndex].hash = hash;
      this.m_hashes[queryIndex].isCalculating = false;
    }
  }

  private func CleanUpHashes() {
    while ArraySize(this.m_hashes) > this.m_maxCachedHashes {
      ArrayErase(this.m_hashes, 0);
    }
  }

  public final func GetFileHash(relativeFilePath: String) -> CyberlibsAsyncHelperHashQuery {
    let i = 0;
    
    while i < ArraySize(this.m_hashes) {
      if Equals(this.m_hashes[i].filePath, relativeFilePath) {
        return this.m_hashes[i];
      }

      i += 1;
    }

    let newQuery = CyberlibsAsyncHelperHashQuery.Create(relativeFilePath);
    ArrayPush(this.m_hashes, newQuery);

    let promise = GameDiagnosticsHashPromise.Create(this, n"OnHashResolved", relativeFilePath, n"OnHashResolved");
    GameDiagnosticsAsync.GetFileHash(relativeFilePath, promise);

    this.CleanUpHashes();
    
    return newQuery;
  }

  public final func SetMaxCachedHashes(count: Int32) -> Void {
    this.m_maxCachedHashes = count;
  }

  private func OnVerifyPathsResolved(isValid: Bool, filePath: String) {
    let queryIndex = -1;
    let i = 0;

    while i < ArraySize(this.m_verifiedPaths) {
      if Equals(this.m_verifiedPaths[i].filePath, filePath) {
        queryIndex = i;
        break;
      }

      i += 1;
    }

    if queryIndex >= 0 {
      this.m_verifiedPaths[queryIndex].isValid = isValid;
      this.m_verifiedPaths[queryIndex].isCalculating = false;
    }
  }

  private func CleanUpVerifyPathsResults() {
    while ArraySize(this.m_verifiedPaths) > this.m_maxCachedVerifyPathsResults {
      ArrayErase(this.m_verifiedPaths, 0);
    }
  }

  public final func VerifyPaths(relativePathsFilePath: String) -> CyberlibsAsyncHelperVerifyPathsQuery {
    let i = 0;
    
    while i < ArraySize(this.m_verifiedPaths) {
      if Equals(this.m_verifiedPaths[i].filePath, relativePathsFilePath) {
          return this.m_verifiedPaths[i];
      }

      i += 1;
    }

    let newQuery = CyberlibsAsyncHelperVerifyPathsQuery.Create(relativePathsFilePath);
    ArrayPush(this.m_verifiedPaths, newQuery);

    let promise = GameDiagnosticsVerifyPathsPromise.Create(this, n"OnVerifyPathsResolved", relativePathsFilePath);
    GameDiagnosticsAsync.VerifyPaths(relativePathsFilePath, promise);

    this.CleanUpVerifyPathsResults();

    return newQuery;
  }

  public final func SetMaxCachedVerifyPathsResults(count: Int32) -> Void {
    this.m_maxCachedVerifyPathsResults = count;
  }
}

public native struct CyberlibsAsyncHelperHashQuery {
  native let hash: String;
  native let filePath: String;
  native let isCalculating: Bool;

  public static func Create(filePath: String) -> CyberlibsAsyncHelperHashQuery {
    let self: CyberlibsAsyncHelperHashQuery;

    self.hash = "Calculating...";
    self.filePath = filePath;
    self.isCalculating = true;

    return self;
  }
}

public native struct CyberlibsAsyncHelperVerifyPathsQuery {
  native let isValid: Bool;
  native let filePath: String;
  native let isCalculating: Bool;

  public static func Create(filePath: String) -> CyberlibsAsyncHelperVerifyPathsQuery {
    let self: CyberlibsAsyncHelperVerifyPathsQuery;

    self.isValid = false;
    self.filePath = filePath;
    self.isCalculating = true;

    return self;
  }
}

@addMethod(GameInstance)
public static native func GetCyberlibsAsyncHelper() -> ref<CyberlibsAsyncHelper>;

public native class GameDiagnostics extends IScriptable {
  public static native func GetCurrentTimeDate(opt pathFriendly: Bool) -> String;
  public static native func GetGamePath() -> String;
  public static native func GetFileHash(relativeFilePath: String) -> String;
  public static native func GetTimeDateStamp(relativeFilePath: String, opt pathFriendly: Bool) -> String;
  public static native func IsFile(relativeFilePath: String) -> Bool;
  public static native func IsDirectory(relativePath: String) -> Bool;
  public static native func IsDirectory(relativePath: String) -> array<GameDiagnosticsPathEntry>;
  public static native func VerifyPaths(relativePathsFilePath: String) -> Bool;
  public static native func WriteToOutput(relativeFilePath: String, content: String, opt append: Bool) -> Bool;
}

public native struct GameDiagnosticsPathEntry {
  native let name: String;
  native let type: String;
}

public native class GameDiagnosticsAsync extends IScriptable {
  public static native func GetFileHash(relativeFilePath: String, promise: GameDiagnosticsHashPromise) -> Void;
  public static native func VerifyPaths(relativePathsFilePath: String, promise: GameDiagnosticsVerifyPathsPromise) -> Void;
}

public native struct GameDiagnosticsHashPromise {
  public native let target: wref<IScriptable>;
  public native let success: CName;
  public native let error: CName;
  public native let filePath: String;

  public static func Create(target: wref<IScriptable>, success: CName, filePath: String, opt error: CName) -> GameDiagnosticsHashPromise {
    let self: GameDiagnosticsHashPromise;

    self.target = target;
    self.success = success;
    self.error = error;
    self.filePath = filePath;

    return self;
  }
}

public native struct GameDiagnosticsVerifyPathsPromise {
  public native let target: wref<IScriptable>;
  public native let complete: CName;
  public native let filePath: String;

  public static func Create(target: wref<IScriptable>, complete: CName, filePath: String) -> GameDiagnosticsVerifyPathsPromise {
    let self: GameDiagnosticsVerifyPathsPromise;

    self.target = target;
    self.complete = complete;
    self.filePath = filePath;

    return self;
  }
}

public native class GameModules extends IScriptable {
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
  public static native func GetTimeDateStamp(fileNameOrPath: String, opt pathFriendly: Bool) -> String;
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
