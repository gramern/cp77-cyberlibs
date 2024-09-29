cmake_minimum_required(VERSION 3.28)
project(cp77-cyberlibs LANGUAGES CXX)
set_property(GLOBAL PROPERTY USE_FOLDERS ON)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED YES)

# RED4ext.SDK
add_subdirectory(dependencies/RED4ext.SDK)
set_target_properties(RED4ext.SDK PROPERTIES FOLDER "dependencies")
mark_as_advanced(RED4EXT_BUILD_EXAMPLES RED4EXT_HEADER_ONLY)

# Red Lib
add_compile_definitions(NOMINMAX)
add_subdirectory(dependencies/cp2077-red-lib)
set_target_properties(RedLib PROPERTIES FOLDER "dependencies")

# Define resources
set(INC_FILES
  include/resource.h
  include/VersionInfo.rc
)

# Define source
file(GLOB_RECURSE SRC_FILES
  "src/*"
)

# Define libpe
set(LIBPE_FILES
 dependencies/libpe/libpe/libpe.ixx
)

# Define scripts
file(GLOB_RECURSE REDS_FILES
  "scripts/*"
)

# Define lua
file(GLOB_RECURSE LUA_FILES
  "lua/*"
)

# Define docs
set(DOCS_FILES
  README.md
  docs/methods.md
)

# Libpe is a module interface file
set_property(SOURCE dependencies/libpe/libpe/libpe.ixx PROPERTY CPLUSPLUS_INCLUDE_FILE TRUE)

# Library target
add_library(cp77-cyberlibs SHARED ${INC_FILES} ${SRC_FILES} ${LIBPE_FILES} ${REDS_FILES} ${LUA_FILES} ${DOCS_FILES})

# Output name
set_target_properties(cp77-cyberlibs PROPERTIES OUTPUT_NAME "Cyberlibs")

# Include directories
target_include_directories(cp77-cyberlibs PUBLIC include/ src/)

# Link libraries
target_link_libraries(cp77-cyberlibs PRIVATE RED4ext.SDK RedLib Version.lib)

# Source group
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${INC_FILES} ${SRC_FILES} ${REDS_FILES} ${LUA_FILES})
source_group("libpe" FILES ${LIBPE_FILES})
source_group("docs" FILES ${DOCS_FILES})
