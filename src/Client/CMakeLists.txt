add_library(JEVTIP SHARED dllmain.cpp Globals.cpp McBopomofoTIP.cpp Register.cpp EditSession.cpp StateEditSession.cpp TsfUiElement.cpp DisplayAttributeInfo.cpp LangBarButton.cpp McBopomofoTIP.rc)
set_target_properties(JEVTIP PROPERTIES OUTPUT_NAME "JEVTIP")
target_include_directories(JEVTIP PRIVATE ${CMAKE_SOURCE_DIR}/src/Server/Engine ${CMAKE_SOURCE_DIR}/src/Server ${WINMCBOPOMOFO_GENERATED_DIR})
target_link_libraries(JEVTIP PRIVATE Common Ole32 OleAut32 Uuid Advapi32 d2d1 dwrite)
target_compile_definitions(JEVTIP PRIVATE _USRDLL)

# Generate a .def file to export COM functions
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/McBopomofoTIP.def "LIBRARY JEVTIP\nEXPORTS\n  DllGetClassObject PRIVATE\n  DllCanUnloadNow PRIVATE\n  DllRegisterServer PRIVATE\n  DllUnregisterServer PRIVATE\n")

target_sources(JEVTIP PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/McBopomofoTIP.def)
