local help = {}

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
                --- Returns a module version. Compared to GameModules.GetVersion(), additionally
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
        ["GameModules Class"] = {
            ["[ INFO ] public native class GameModules"] =
                [[
                public native class GameModules
                 
                --- Example Lua:    
                if type(GameModules) == "userdata" then
                        print(GameModules.GetVersion("libxess.dll"))
                else
                        print("Cyberlibs is not installed or loaded")
                end
                
                // Example Redscript:
                let version: String = GameModules.GetVersion("libxess.dll")]],
            ["GameModules.GetCompanyName(fileNameOrPath)"] =
                [[
                --- Gets the company name associated with the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return string The company name
                GameModules.GetCompanyName(fileNameOrPath)
                
                // Redscript:
                public static native func GetCompanyName(fileNameOrPath: String) -> String]],
            ["GameModules.GetDescription(fileNameOrPath)"] =
                [[
                --- Retrieves the description of the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return string The module description
                GameModules.GetDescription(fileNameOrPath)
                
                // Redscript:
                public static native func GetDescription(fileNameOrPath: String) -> String]],
            ["GameModules.GetEntryPoint(fileNameOrPath)"] =
                [[
                --- Obtains the entry point of the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return string The entry point
                GameModules.GetEntryPoint(fileNameOrPath)
                
                // Redscript:
                public static native func GetEntryPoint(fileNameOrPath: String) -> String]],
            ["GameModules.GetExport(fileNameOrPath)"] =
                [[
                --- Retrieves the export information of the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return table Array of ModuleInfoExportArray containing export information
                GameModules.GetExport(fileNameOrPath)
                
                // Redscript:
                public static native func GetExport(fileNameOrPath: String) -> array<ModuleInfoExportArray>]],
            ["GameModules.GetFilePath(fileNameOrPath)"] =
                [[
                --- Gets the full file path of the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return string The full file path
                GameModules.GetFilePath(fileNameOrPath)
                
                // Redscript:
                public static native func GetFilePath(fileNameOrPath: String) -> String]],
            ["GameModules.GetFileSize(fileNameOrPath)"] =
                [[
                --- Retrieves the file size of the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return string The file size
                GameModules.GetFileSize(fileNameOrPath)
                
                // Redscript:
                public static native func GetFileSize(fileNameOrPath: String) -> String]],
            ["GameModules.GetImport(fileNameOrPath)"] =
                [[
                --- Obtains the import information of the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return table Array of ModuleInfoImportArray containing import information
                GameModules.GetImport(fileNameOrPath)
                
                // Redscript:
                public static native func GetImport(fileNameOrPath: String) -> array<ModuleInfoImportArray>]],
            ["GameModules.GetLoadAddress(fileNameOrPath)"] =
                [[
                --- Retrieves the load address of the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return string The load address
                GameModules.GetLoadAddress(fileNameOrPath)
                
                // Redscript:
                public static native func GetLoadAddress(fileNameOrPath: String) -> String]],
            ["GameModules.GetLoadedModules()"] =
                [[
                --- Gets a list of all loaded modules
                --- 
                ---@return table Array of strings containing the names of loaded modules
                GameModules.GetLoadedModules()
                
                // Redscript:
                public static native func GetLoadedModules() -> array<String>]],
            ["GameModules.GetMappedSize(fileNameOrPath)"] =
                [[
                --- Retrieves the mapped size of the module in memory
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return string The mapped size
                GameModules.GetMappedSize(fileNameOrPath)
                
                // Redscript:
                public static native func GetMappedSize(fileNameOrPath: String) -> String]],
            ["GameModules.GetVersion(fileNameOrPath)"] =
                [[
                --- Gets the version information of the module
                --- 
                ---@param fileNameOrPath string The file name or path of the module
                ---@return string The version
                GameModules.GetVersion(fileNameOrPath)
                
                // Redscript:
                public static native func GetVersion(fileNameOrPath: String) -> String]],

            ["GameModules.IsLoaded(fileNameOrPath)"] =
                [[
                --- Checks if a module is currently loaded
                --- 
                ---@param fileNameOrPath string The file name or path of the module to check
                ---@return boolean Indicating whether the module is loaded
                GameModules.IsLoaded(fileNameOrPath)
                
                // Redscript:
                public static native func IsLoaded(fileNameOrPath: String) -> Bool]]
        },
        ["GameModules Structs"] = {
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