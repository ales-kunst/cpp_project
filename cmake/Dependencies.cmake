#
# Dependency settings
#

set(DEPS_INCLUDE_DIR "deps/include")
set(DEPS_LIBRARY_DIR "deps/lib")

# Currently only for Windows
if (WIN32)

#[[ 
  add_library_to_project(cares ${DEPS_LIBRARY_DIR})
  add_library_to_project(cryptlib ${DEPS_LIBRARY_DIR})
  add_library_to_project(curlcpp ${DEPS_LIBRARY_DIR})
  add_library_to_project(libcrypto ${DEPS_LIBRARY_DIR})
  add_library_to_project(libcurl_a ${DEPS_LIBRARY_DIR})
  add_library_to_project(libssh2 ${DEPS_LIBRARY_DIR})
  add_library_to_project(libssl ${DEPS_LIBRARY_DIR})
  add_library_to_project(libuSockets ${DEPS_LIBRARY_DIR})
  add_library_to_project(nghttp2 ${DEPS_LIBRARY_DIR})
  add_library_to_project(uv_a ${DEPS_LIBRARY_DIR})
  add_library_to_project(zlibstatic ${DEPS_LIBRARY_DIR})
]]

  target_include_directories(
    ${PROJECT_NAME}
    PRIVATE
      ${DEPS_INCLUDE_DIR}
  )

  target_link_libraries(
    ${PROJECT_NAME}
    PRIVATE
      crypt32
      wldap32
      normaliz
  )

endif()

# add_boost_to_project(1.74.0 ${DEPS_INCLUDE_DIR} ${DEPS_LIBRARY_DIR} system coroutine regex date_time)

target_link_libraries(
    ${PROJECT_NAME}
    PRIVATE
      CONAN_PKG::spdlog
)
