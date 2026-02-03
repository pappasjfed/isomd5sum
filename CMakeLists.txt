cmake_minimum_required(VERSION 3.12)
project(isomd5sum VERSION 1.2.5 LANGUAGES C)

# Set C standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Platform-specific settings
if(WIN32)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
    add_definitions(-D_FILE_OFFSET_BITS=64)
    add_definitions(-D_LARGEFILE_SOURCE=1)
    add_definitions(-D_LARGEFILE64_SOURCE=1)
    # For Windows, we need to handle getpagesize and other POSIX functions
else()
    add_definitions(-D_GNU_SOURCE=1)
    add_definitions(-D_FILE_OFFSET_BITS=64)
    add_definitions(-D_LARGEFILE_SOURCE=1)
    add_definitions(-D_LARGEFILE64_SOURCE=1)
endif()

# Compiler flags
if(MSVC)
    add_compile_options(/W4)
else()
    add_compile_options(-Wall -fPIC)
endif()

# Source files for libraries
set(MD5_SOURCES md5.c utilities.c)
set(LIBIMPLANTISOMD5_SOURCES libimplantisomd5.c ${MD5_SOURCES})
set(LIBCHECKISOMD5_SOURCES libcheckisomd5.c ${MD5_SOURCES})

# Create static libraries
add_library(implantisomd5_static STATIC ${LIBIMPLANTISOMD5_SOURCES})
add_library(checkisomd5_static STATIC ${LIBCHECKISOMD5_SOURCES})

# Set library output names
set_target_properties(implantisomd5_static PROPERTIES OUTPUT_NAME implantisomd5)
set_target_properties(checkisomd5_static PROPERTIES OUTPUT_NAME checkisomd5)

# Find or build popt
if(WIN32)
    # For Windows, we'll use a minimal popt implementation
    # For now, we'll handle command line parsing differently
    set(POPT_FOUND FALSE)
else()
    find_package(PkgConfig)
    if(PkgConfig_FOUND)
        pkg_check_modules(POPT popt)
    endif()
    if(NOT POPT_FOUND)
        find_library(POPT_LIBRARY NAMES popt)
        if(POPT_LIBRARY)
            set(POPT_FOUND TRUE)
        endif()
    endif()
endif()

# Create executables
add_executable(implantisomd5 implantisomd5.c)
target_link_libraries(implantisomd5 implantisomd5_static)

add_executable(checkisomd5 checkisomd5.c)
target_link_libraries(checkisomd5 checkisomd5_static)

# Link Windows-specific libraries
if(WIN32)
    target_link_libraries(implantisomd5 ws2_32)
    target_link_libraries(checkisomd5 ws2_32)
endif()

# Link popt if available
if(POPT_FOUND)
    if(POPT_LINK_LIBRARIES)
        target_link_libraries(implantisomd5 ${POPT_LINK_LIBRARIES})
        target_link_libraries(checkisomd5 ${POPT_LINK_LIBRARIES})
    elseif(POPT_LIBRARY)
        target_link_libraries(implantisomd5 ${POPT_LIBRARY})
        target_link_libraries(checkisomd5 ${POPT_LIBRARY})
    else()
        target_link_libraries(implantisomd5 popt)
        target_link_libraries(checkisomd5 popt)
    endif()
endif()

# Installation rules
install(TARGETS implantisomd5 checkisomd5
        RUNTIME DESTINATION bin)

install(TARGETS implantisomd5_static checkisomd5_static
        ARCHIVE DESTINATION lib)

install(FILES libimplantisomd5.h libcheckisomd5.h
        DESTINATION include)

if(NOT WIN32)
    install(FILES implantisomd5.1 checkisomd5.1
            DESTINATION share/man/man1)
endif()

# Install documentation files
install(FILES README COPYING WINDOWS_BUILD.md
        DESTINATION doc)

# CPack configuration for Windows installer
if(WIN32)
    set(CPACK_GENERATOR "NSIS")
    set(CPACK_PACKAGE_NAME "isomd5sum")
    set(CPACK_PACKAGE_VENDOR "isomd5sum Project")
    set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "MD5 checksum tools for ISO images")
    set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
    set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
    set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
    set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})
    set(CPACK_PACKAGE_INSTALL_DIRECTORY "isomd5sum")
    set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/COPYING")
    set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README")
    
    # NSIS-specific settings
    set(CPACK_NSIS_DISPLAY_NAME "isomd5sum ${PROJECT_VERSION}")
    set(CPACK_NSIS_PACKAGE_NAME "isomd5sum")
    set(CPACK_NSIS_HELP_LINK "https://github.com/rhinstaller/isomd5sum")
    set(CPACK_NSIS_URL_INFO_ABOUT "https://github.com/rhinstaller/isomd5sum")
    set(CPACK_NSIS_CONTACT "anaconda-devel-list@redhat.com")
    set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)
    set(CPACK_NSIS_MODIFY_PATH ON)
    
    # Create Start Menu shortcuts
    set(CPACK_PACKAGE_EXECUTABLES "checkisomd5;Check ISO MD5" "implantisomd5;Implant ISO MD5")
    set(CPACK_NSIS_MENU_LINKS
        "doc/README" "Read Me"
        "doc/WINDOWS_BUILD.md" "Windows Build Instructions"
        "https://github.com/rhinstaller/isomd5sum" "isomd5sum on GitHub")
    
    include(CPack)
endif()
