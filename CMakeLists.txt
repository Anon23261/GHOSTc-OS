cmake_minimum_required(VERSION 3.12)
project(GhostOS VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Raspberry Pi Zero W specific optimizations
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard -O2 -fPIE -fstack-protector-strong")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard -O2 -fPIE -fstack-protector-strong")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-z,relro,-z,now -pie")

# Security features
add_definitions(-D_FORTIFY_SOURCE=2)
add_definitions(-DGHOSTC_SECURE_MODE)
add_definitions(-DSTEALTH_MODE_ENABLED)

# Required packages for GhostC environment
find_package(Boost REQUIRED COMPONENTS 
    system 
    thread 
    program_options
)
find_package(Curses REQUIRED)  # For terminal UI
find_package(OpenSSL REQUIRED) # For encryption
find_package(SQLite3 REQUIRED) # For command history and config

# Add subdirectories
add_subdirectory(src/ghost)
add_subdirectory(src/ghostc)
add_subdirectory(src/terminal)
add_subdirectory(src/ide)

# Main executables
add_executable(ghostc src/ghostc/main.cpp)
add_executable(ghost_terminal src/terminal/main.cpp)
add_executable(ghost_ide src/ide/main.cpp)

# Include directories
target_include_directories(ghostc PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/ghost/include
    ${CMAKE_CURRENT_SOURCE_DIR}/src/ghostc/include
    ${Boost_INCLUDE_DIRS}
    ${CURSES_INCLUDE_DIR}
    ${OPENSSL_INCLUDE_DIR}
    ${SQLite3_INCLUDE_DIRS}
)

# Link GhostC
target_link_libraries(ghostc PRIVATE
    ghost_core
    ghost_crypto
    ghost_net
    ${Boost_LIBRARIES}
    ${CURSES_LIBRARIES}
    ${OPENSSL_LIBRARIES}
    ${SQLite3_LIBRARIES}
    pthread
    dl
)

# Link Terminal
target_link_libraries(ghost_terminal PRIVATE
    ghost_core
    ghost_terminal_core
    ghost_crypto
    ${Boost_LIBRARIES}
    ${CURSES_LIBRARIES}
    ${OPENSSL_LIBRARIES}
    pthread
)

# Link IDE
target_link_libraries(ghost_ide PRIVATE
    ghost_core
    ghost_ide_core
    ghost_crypto
    ${Boost_LIBRARIES}
    ${CURSES_LIBRARIES}
    ${OPENSSL_LIBRARIES}
    pthread
)

# Installation
install(TARGETS ghostc ghost_terminal ghost_ide
    RUNTIME DESTINATION bin
)

# Install configuration
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/config/
    DESTINATION etc/ghost
    FILES_MATCHING 
    PATTERN "*.conf"
    PATTERN "*.json"
    PATTERN "*.key" EXCLUDE  # Don't install encryption keys
)

# Install GhostC tools and scripts
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/tools/
    DESTINATION share/ghost/tools
    USE_SOURCE_PERMISSIONS
    FILES_MATCHING 
    PATTERN "*.sh"
    PATTERN "*.py"
    PATTERN "*.rb"
)

# Security measures for installed files
install(CODE "execute_process(COMMAND chmod 700 \${CMAKE_INSTALL_PREFIX}/bin/ghostc)")
install(CODE "execute_process(COMMAND chmod 600 \${CMAKE_INSTALL_PREFIX}/etc/ghost/*.conf)")
