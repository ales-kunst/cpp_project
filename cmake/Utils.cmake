#
# Print a message only if the `VERBOSE_OUTPUT` option is on
#

function(verbose_message content)
    if(${PROJECT_NAME}_VERBOSE_OUTPUT)
			message(STATUS ${content})
    endif()
endfunction()

#
# Add a target for formating the project using `clang-format` (i.e: cmake --build build --target clang-format)
#

function(add_clang_format_target)
    if(NOT ${PROJECT_NAME}_CLANG_FORMAT_BINARY)
			find_program(${PROJECT_NAME}_CLANG_FORMAT_BINARY clang-format)
    endif()

    if(${PROJECT_NAME}_CLANG_FORMAT_BINARY)
			if(${PROJECT_NAME}_BUILD_EXECUTABLE)
				add_custom_target(clang-format
						COMMAND ${${PROJECT_NAME}_CLANG_FORMAT_BINARY}
						-i $${CMAKE_CURRENT_LIST_DIR}/${exe_sources} ${CMAKE_CURRENT_LIST_DIR}/${headers})
			elseif(${PROJECT_NAME}_BUILD_HEADERS_ONLY)
				add_custom_target(clang-format
						COMMAND ${${PROJECT_NAME}_CLANG_FORMAT_BINARY}
						-i ${CMAKE_CURRENT_LIST_DIR}/${headers})
			else()
				add_custom_target(clang-format
						COMMAND ${${PROJECT_NAME}_CLANG_FORMAT_BINARY}
						-i ${CMAKE_CURRENT_LIST_DIR}/${sources} ${CMAKE_CURRENT_LIST_DIR}/${headers})
			endif()

			message(STATUS "Format the project using the `clang-format` target (i.e: cmake --build build --target clang-format).\n")
    endif()
endfunction()

#
# Add library to the project
#

function(add_library_to_project LIBRARY_NAME INCLUDE_DIR LIB_DIR)
  message(STATUS "++++ Searching for library: ${LIBRARY_NAME} in folder: ${LIB_DIR} ++++")
  find_library(LIB_R NAMES ${LIBRARY_NAME} PATHS ${DEPS_LIBRARY_DIR} REQUIRED)
  find_library(LIB_D NAMES ${LIBRARY_NAME}d PATHS ${DEPS_LIBRARY_DIR} REQUIRED)
  message(STATUS "++++ Adding library: ${LIBRARY_NAME} to project: ${PROJECT} ++++")
  target_link_libraries(${PROJECT_NAME} PRIVATE debug ${LIB_D} optimized ${LIB_R})
  # this is how you retrn value: set(${REQUIRED_ARG} "From SIMPLE" PARENT_SCOPE)
endfunction()

#
# Add Boost library to the project
#

function(add_boost_to_project BOOST_VER BOOST_INCL_DIR BOOST_LIB_DIR)
  set(BOOST_INCLUDEDIR ${BOOST_INCL_DIR})
  set(BOOST_LIBRARYDIR ${BOOST_LIB_DIR})
  set(Boost_USE_STATIC_LIBS ON)
  find_package(Boost ${BOOST_VER} COMPONENTS ${ARGN} REQUIRED)

  include_directories(${Boost_INCLUDE_DIR})

  foreach(ARG IN ITEMS ${ARGN})
    target_link_libraries(
      ${PROJECT_NAME}
      PRIVATE
        Boost::${ARG}
    )
  endforeach()
endfunction()

#
# Print out all variables
#

function(print_all_variables)
	message("--------------------------------------------------------\n")
	get_cmake_property(_variableNames VARIABLES)
	list (SORT _variableNames)
	foreach (_variableName ${_variableNames})
		message(STATUS "${_variableName}=${${_variableName}}")
	endforeach()
	message("--------------------------------------------------------\n")
endfunction()