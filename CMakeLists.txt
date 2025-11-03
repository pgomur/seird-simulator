cmake_minimum_required(VERSION 3.12)
project(seird_project LANGUAGES Fortran)

# -------------------------------------------------------------
# General compiler configuration
# -------------------------------------------------------------
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -std=f2023 -Wall -Wextra")

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/obj) 
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)  
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)  

set(CMAKE_Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/mod)

# -------------------------------------------------------------
# List of module source files (dependency order)
# -------------------------------------------------------------
set(MODULE_SOURCES
    src/precision_mod.f90
    src/parameters_mod.f90
    src/numerics_mod.f90
    src/io_mod.f90
    src/visualization_mod.f90
    src/seird_model_mod.f90
)

# -------------------------------------------------------------
# Main program
# -------------------------------------------------------------
add_executable(seird_main 
    ${MODULE_SOURCES}
    src/main.f90
)

target_include_directories(seird_main PRIVATE ${CMAKE_Fortran_MODULE_DIRECTORY})

# -------------------------------------------------------------
# OpenMP
# -------------------------------------------------------------
find_package(OpenMP)
if(OpenMP_Fortran_FOUND)
    message(STATUS "OpenMP found. Enabled.")
    target_link_libraries(seird_main PRIVATE OpenMP::OpenMP_Fortran)
    target_compile_options(seird_main PRIVATE ${OpenMP_Fortran_FLAGS})
else()
    message(WARNING "OpenMP not found. It will be compiled without parallelism.")
endif()

# -------------------------------------------------------------
# Tests with pFUnit (multi-file version)
# -------------------------------------------------------------
enable_testing()
find_package(PFUNIT REQUIRED)

set(PFUNIT_BUILD_DIR ${CMAKE_BINARY_DIR}/test)
file(MAKE_DIRECTORY ${PFUNIT_BUILD_DIR})

file(GLOB PFUNIT_TESTS ${CMAKE_SOURCE_DIR}/test/*.pf)

foreach(test_file ${PFUNIT_TESTS})
    get_filename_component(test_name ${test_file} NAME_WE)
    
    set(tmp_pf ${PFUNIT_BUILD_DIR}/${test_name}.pf)
    configure_file(${test_file} ${tmp_pf} COPYONLY)

    add_pfunit_ctest(${test_name}
        TEST_SOURCES ${tmp_pf}
        OTHER_SOURCES ${MODULE_SOURCES}
    )
endforeach()


# -------------------------------------------------------------
# Informative messages
# -------------------------------------------------------------
message(STATUS "Project: ${PROJECT_NAME}")
message(STATUS "Compilador Fortran: ${CMAKE_Fortran_COMPILER}")
message(STATUS "Flags: ${CMAKE_Fortran_FLAGS}")
message(STATUS "Binaries: ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
message(STATUS "Modules: ${CMAKE_Fortran_MODULE_DIRECTORY}")