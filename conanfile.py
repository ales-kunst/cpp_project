from conans import ConanFile, CMake

class PocoTimerConan(ConanFile):
   settings = "os", "compiler", "build_type", "arch"
   requires = "spdlog/1.8.0" # "zeromq/4.3.3", "rapidjson/cci.20200410"

   default_options = {
      "spdlog:shared": False,
      "spdlog:header_only": True,
      "spdlog:no_exceptions": False

      # "zeromq:shared": False, 
      # "zeromq:encryption": "libsodium",
      # "libiconv:shared": False

   }
   generators = "cmake"

   #def imports(self):
      # self.copy("*.dll", dst="bin", src="bin") # From bin to bin
      # self.copy("*.dylib*", dst="bin", src="lib") # From lib to bin

   def build(self):
      cmake = CMake(self)
      cmake.configure()
      cmake.build()