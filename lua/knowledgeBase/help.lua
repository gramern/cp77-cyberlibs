local help = {
    __VERSION = { 0, 2, 0 },
}

local t = nil

local function intializeTable()
    return {
        ["Cyberlibs API"] = {
            ["[ INFO ] public native class Cyberlibs"] =
                [[
                public native class Cyberlibs
                 
                --- Example Lua:    
                if type(Cyberlibs) == "userdata" then
                        print(Cyberlibs.Version())
                else
                        print("Cyberlibs is not installed or loaded")
                end]],
            ["Cyberlibs.Version()"] =
                [[
                --- Returns Cyberlibs version string
                --- 
                ---@return string Cyberlibs version
                Cyberlibs.Version(),
                
                // Redscript:
                public static native func Version() -> String]],
            ["Cyberlibs.SetPrintingStyle(isEnabled)"] =
                [[
                --- Sets the printing style in CET's console (and logs)
                --- 
                ---@param isEnabled boolean Whether to enable the custom printing style
                Cyberlibs.SetPrintingStyle(isEnabled)]],
            ["Cyberlibs.Help(query, forceLog)"] =
                [[
                --- Displays help information for a query in CET's console and to logs (optional)
                --- 
                ---@param query number Query to get help for
                ---@param forceLog boolean Whether to force logging
                Cyberlibs.Help(methodName, forceLog)]],
            ["Cyberlibs.GetVersion(fileNameOrPath)"] =
                [[
                --- Returns a module version. Compared to GameModule.GetVersion(), additionally
                --- checks Cyberlibs' knowledge database to find requested info.
                ---
                ---@return string Cyberlibs version
                Cyberlibs.GetVersion()
                
                // Redscript:
                public static native func GetVersion() -> String]],
            ["Cyberlibs.PrintAttribute(fileNameOrPath, attribute, forceLog)"] =
                [[
                --- Prints a specified attribute of a module in CET's console and to logs (optional)
                --- Available attributes: 'CompanyName', 'Description', 'EntryPoint', 'Export',
                --- 'FilePath', 'FileSize', 'FileType', 'Import', 'LoadAddress', 'MappedSize', 
                --- 'TimeDateStamp', 'Version'
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@param attribute string The attribute to print
                ---@param forceLog boolean Whether to force logging
                Cyberlibs.PrintAttribute(fileNameOrPath, attribute, forceLog)]],
            ["Cyberlibs.PrintExport(fileNameOrPath, forceLog)"] =
                [[
                --- Prints the export information of a module in CET's console and to logs (optional)
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@param forceLog boolean Whether to force logging
                Cyberlibs.PrintExport(fileNameOrPath, forceLog)]],
            ["Cyberlibs.PrintImport(fileNameOrPath, forceLog)"] =
                [[
                --- Prints the import information of a module in CET's console and to logs (optional)
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@param forceLog boolean Whether to force logging
                Cyberlibs.PrintImport(fileNameOrPath, forceLog)]],
            ["Cyberlibs.PrintIsLoaded(fileNameOrPath, forceLog)"] =
                [[
                --- Prints whether a specified module is loaded in CET's console and to logs (optional)
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@param forceLog boolean Whether to force logging
                Cyberlibs.PrintIsLoaded(fileNameOrPath, forceLog)]],
            ["Cyberlibs.PrintLoadedModules(forceLog)"] =
                [[
                --- Prints the list of loaded modules in CET's console and to logs (optional)
                --- 
                ---@param forceLog boolean Whether to force logging
                Cyberlibs.PrintLoadedModules(forceLog)]],
            ["Cyberlibs.PrintVersion(fileNameOrPath, forceLog)"] =
                [[
                --- Prints the version of a specified module in CET's console and to logs (optional)
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@param forceLog boolean Whether to force logging
                Cyberlibs.PrintVersion(fileNameOrPath, forceLog)]]
        },
        ["GameModule Class"] = {
            ["[ INFO ] public native class GameModule"] =
                [[
                public native class GameModule
                 
                --- Example Lua:    
                if type(GameModule) == "userdata" then
                        print(GameModule.GetVersion("libxess.dll"))
                else
                        print("Cyberlibs is not installed or loaded")
                end
                
                // Example Redscript:
                let version: String = GameModule.GetVersion("libxess.dll")]],
            ["GameModule.GetCompanyName(fileNameOrPath)"] =
                [[
                --- Gets the company name associated with the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return string The company name
                GameModule.GetCompanyName(fileNameOrPath)
                
                // Redscript:
                public static native func GetCompanyName(fileNameOrPath: String) -> String]],
            ["GameModule.GetDescription(fileNameOrPath)"] =
                [[
                --- Retrieves the description of the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return string The module description
                GameModule.GetDescription(fileNameOrPath)
                
                // Redscript:
                public static native func GetDescription(fileNameOrPath: String) -> String]],
            ["GameModule.GetEntryPoint(fileNameOrPath)"] =
                [[
                --- Obtains the entry point of the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return string The entry point
                GameModule.GetEntryPoint(fileNameOrPath)
                
                // Redscript:
                public static native func GetEntryPoint(fileNameOrPath: String) -> String]],
            ["GameModule.GetExport(fileNameOrPath)"] =
                [[
                --- Retrieves the export information of the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return table Array of ModuleInfoExportArray containing export information
                GameModule.GetExport(fileNameOrPath)
                
                // Redscript:
                public static native func GetExport(fileNameOrPath: String) -> array<ModuleInfoExportArray>]],
            ["GameModule.GetFilePath(fileNameOrPath)"] =
                [[
                --- Gets the full file path of the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return string The full file path
                GameModule.GetFilePath(fileNameOrPath)
                
                // Redscript:
                public static native func GetFilePath(fileNameOrPath: String) -> String]],
            ["GameModule.GetFileSize(fileNameOrPath)"] =
                [[
                --- Retrieves the file size of the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return string The file size
                GameModule.GetFileSize(fileNameOrPath)
                
                // Redscript:
                public static native func GetFileSize(fileNameOrPath: String) -> String]],
            ["GameModule.GetImport(fileNameOrPath)"] =
                [[
                --- Obtains the import information of the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return table Array of ModuleInfoImportArray containing import information
                GameModule.GetImport(fileNameOrPath)
                
                // Redscript:
                public static native func GetImport(fileNameOrPath: String) -> array<ModuleInfoImportArray>]],
            ["GameModule.GetLoadAddress(fileNameOrPath)"] =
                [[
                --- Retrieves the load address of the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return string The load address
                GameModule.GetLoadAddress(fileNameOrPath)
                
                // Redscript:
                public static native func GetLoadAddress(fileNameOrPath: String) -> String]],
            ["GameModule.GetLoadedModules()"] =
                [[
                --- Gets a list of all loaded modules
                --- 
                ---@return table Array of strings containing the names of loaded modules
                GameModule.GetLoadedModules()
                
                // Redscript:
                public static native func GetLoadedModules() -> array<String>]],
            ["GameModule.GetMappedSize(fileNameOrPath)"] =
                [[
                --- Retrieves the mapped size of the module in memory
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return string The mapped size
                GameModule.GetMappedSize(fileNameOrPath)
                
                // Redscript:
                public static native func GetMappedSize(fileNameOrPath: String) -> String]],
            ["GameModule.GetVersion(fileNameOrPath)"] =
                [[
                --- Gets the version information of the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return string The version
                GameModule.GetVersion(fileNameOrPath)
                
                // Redscript:
                public static native func GetVersion(fileNameOrPath: String) -> String]],

            ["GameModule.IsLoaded(fileNameOrPath)"] =
                [[
                --- Checks if a module is currently loaded
                --- 
                ---@param fileNameOrPath string The file name or path of the module to check
                ---@return boolean Indicating whether the module is loaded
                GameModule.IsLoaded(fileNameOrPath)
                
                // Redscript:
                public static native func IsLoaded(fileNameOrPath: String) -> Bool]]
        },
        ["GameModule Structs"] = {
        ["public native struct GameModuleExportArray"] =
                [[
                public native struct GameModuleExportArray {
                    native let entry: String
                    native let ordinal: Int32
                    native let rva: Int32
                }]],
            ["public native struct GameModuleImportArray"] =
                [[
                public native struct GameModuleImportArray {
                    native let fileName: String
                    native let entries: array<String>
                }]],
        }
    }
end

function help.getTable()
    if t == nil then
        t = intializeTable()
    end

    return t
end

return help