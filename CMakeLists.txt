cmake_minimum_required(VERSION 3.28)
project(ParserExample)

find_package(BISON REQUIRED)
find_package(FLEX REQUIRED)

set(CMAKE_C_COMPILER "/usr/bin/clang")
set(CMAKE_CXX_COMPILER "/usr/bin/clang++")

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++20 -O2")

BISON_TARGET(
    MyParser
    ${CMAKE_SOURCE_DIR}/parser.y
    ${CMAKE_SOURCE_DIR}/parser.cpp
    COMPILE_FLAGS
    DEFINES_FILE
    ${CMAKE_SOURCE_DIR}/parser.hh
)

FLEX_TARGET(
    MyScanner
    ${CMAKE_SOURCE_DIR}/scanner.l
    ${CMAKE_SOURCE_DIR}/scanner.cpp
)

ADD_FLEX_BISON_DEPENDENCY(MyScanner MyParser)

add_executable(
    interpreter
    main.cpp
    driver.cpp
    ${BISON_MyParser_OUTPUTS}
    ${FLEX_MyScanner_OUTPUTS}
)

target_include_directories(interpreter PRIVATE ${CMAKE_SOURCE_DIR})

add_custom_target(clear
    COMMAND ${CMAKE_COMMAND} -E remove ${CMAKE_BINARY_DIR}/CMakeCache.txt
    COMMENT "Clearing CMake cache"
)

add_custom_target(clear_all
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}
    COMMENT "Removing entire build directory"
)

add_custom_target(run_tests
    COMMAND ${CMAKE_COMMAND} -E echo "Running Python tests..."
    COMMAND ${CMAKE_COMMAND} -E chdir ${CMAKE_SOURCE_DIR} python3 tests.py
    DEPENDS interpreter
    COMMENT "Executing tests.py"
)

