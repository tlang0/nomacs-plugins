macro(NMC_POLICY)

endmacro(NMC_POLICY)

# Searches for Qt with the required components
macro(NMC_FINDQT)
  
	set(CMAKE_AUTOMOC ON)
	set(CMAKE_AUTORCC ON)
	set(CMAKE_INCLUDE_CURRENT_DIR ON)
	if(NOT QT_QMAKE_EXECUTABLE)
		find_program(QT_QMAKE_EXECUTABLE NAMES "qmake" "qmake-qt5" "qmake.exe")
	endif()
	if(NOT QT_QMAKE_EXECUTABLE)
		message(FATAL_ERROR "you have to set the path to the Qt5 qmake executable")
	endif()
    message(STATUS "QMake found: path: ${QT_QMAKE_EXECUTABLE}")
    GET_FILENAME_COMPONENT(QT_QMAKE_PATH ${QT_QMAKE_EXECUTABLE} PATH)
    set(QT_ROOT ${QT_QMAKE_PATH}/)
    SET(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${QT_QMAKE_PATH}\\..\\lib\\cmake\\Qt5)
    find_package(Qt5 REQUIRED Widgets Network LinguistTools PrintSupport Concurrent Gui)
	if (NOT Qt5_FOUND)
		message(FATAL_ERROR "Qt5Widgets not found. Check your QT_QMAKE_EXECUTABLE path and set it to the correct location")
	endif()
	add_definitions(-DQT5)
	
endmacro(NMC_FINDQT)

macro(NMC_FIND_OPENCV)
  SET(OpenCV_LIBS "")
  if (PKG_CONFIG_FOUND) # not sure: pkgconfig is needed for old linux  with old old opencv systems
    pkg_check_modules(OpenCV  opencv>=2.1.0)
    SET(OpenCV_LIBS ${OpenCV_LIBRARIES})
  endif(PKG_CONFIG_FOUND)
  IF (OpenCV_LIBS STREQUAL "") 
    find_package(OpenCV REQUIRED core imgproc)
  ENDIF()
  IF (NOT OpenCV_FOUND)
    message(FATAL_ERROR "OpenCV not found. It's mandatory when used with ENABLE_RAW enabled") 
  ELSE()
    add_definitions(-DWITH_OPENCV)
  ENDIF()
endmacro(NMC_FIND_OPENCV)

macro(NMC_PREPARE_PLUGIN)
  
  MARK_AS_ADVANCED(CMAKE_INSTALL_PREFIX)
   
  if(NOT NOMACS_VARS_ALREADY_SET) # is set when building nomacs and plugins at the sime time with linux
		
	find_package(nomacs)
		
    if(NOT NOMACS_FOUND)
      SET(NOMACS_BUILD_DIRECTORY "NOT_SET" CACHE PATH "Path to the nomacs build directory")
      IF (${NOMACS_BUILD_DIRECTORY} STREQUAL "NOT_SET")
        MESSAGE(FATAL_ERROR "You have to set the nomacs build directory")
      ENDIF()
    endif()
    SET(NOMACS_PLUGIN_INSTALL_DIRECTORY ${CMAKE_SOURCE_DIR}/install CACHE PATH "Path to the plugin install directory for deploying")
	
  endif(NOT NOMACS_VARS_ALREADY_SET)
    
  if (CMAKE_BUILD_TYPE STREQUAL "debug" OR CMAKE_BUILD_TYPE STREQUAL "Debug" OR CMAKE_BUILD_TYPE STREQUAL "DEBUG")
      message(STATUS "A debug build. -DDEBUG is defined")
      add_definitions(-DDEBUG)
      ADD_DEFINITIONS(-DQT_NO_DEBUG)
  elseif (NOT MSVC) # debug and release need qt debug outputs on windows
      message(STATUS "A release build (non-debug). Debugging outputs are silently ignored.")
      add_definitions(-DQT_NO_DEBUG_OUTPUT)
  endif ()
  
endmacro(NMC_PREPARE_PLUGIN)

# you can use this NMC_CREATE_TARGETS("myAdditionalDll1.dll" "myAdditionalDll2.dll")
macro(NMC_CREATE_TARGETS)
  set(ADDITIONAL_DLLS ${ARGN})
  list(LENGTH ADDITIONAL_DLLS NUM_ADDITONAL_DLLS) 
  if( ${NUM_ADDITONAL_DLLS} GREATER 0) 
    foreach(DLL ${ADDITIONAL_DLLS})
      message(STATUS "extra_macro_args: ${DLL}")
    endforeach()
  endif()
  
  
IF (MSVC)
	add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD COMMAND ${CMAKE_COMMAND} -E make_directory ${NOMACS_BUILD_DIRECTORY}/$<CONFIGURATION>/plugins/)
	add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${PROJECT_NAME}> ${NOMACS_BUILD_DIRECTORY}/$<CONFIGURATION>/plugins/)
  if(${NUM_ADDITONAL_DLLS} GREATER 0) 
    foreach(DLL ${ADDITIONAL_DLLS})
      add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/bin/${DLL} ${NOMACS_BUILD_DIRECTORY}/$<CONFIGURATION>/plugins/)
    endforeach()
  endif()
  
	# write dll to d.txt (used for automated plugin download)
	if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/d.txt)
		file(READ ${CMAKE_CURRENT_SOURCE_DIR}/d.txt fileContent)	
		if(CMAKE_CL_64)
			string (REGEX MATCHALL "x64" matches ${fileContent})
			if(NOT matches)
				file(APPEND ${CMAKE_CURRENT_SOURCE_DIR}/d.txt "x64 x64/${PROJECT_NAME}.dll\n")
        if(${NUM_ADDITONAL_DLLS} GREATER 0) 
          foreach(DLL ${ADDITIONAL_DLLS})
            file(APPEND ${CMAKE_CURRENT_SOURCE_DIR}/d.txt "x64 x64/${DLL}\n")        
          endforeach()
        endif()
			endif()
		else()
			string (REGEX MATCHALL "x86" matches ${fileContent})		
			if(NOT matches)
				file(APPEND ${CMAKE_CURRENT_SOURCE_DIR}/d.txt "x86 x86/${PROJECT_NAME}.dll\n")
        if(${NUM_ADDITONAL_DLLS} GREATER 0) 
          foreach(DLL ${ADDITIONAL_DLLS})
            file(APPEND ${CMAKE_CURRENT_SOURCE_DIR}/d.txt "x86 x86/${DLL}\n")        
          endforeach()
        endif()
			endif()	
		endif(CMAKE_CL_64)
	else()
		if(CMAKE_CL_64)
      file(APPEND ${CMAKE_CURRENT_SOURCE_DIR}/d.txt "x64 x64/${PROJECT_NAME}.dll\n")
      if(${NUM_ADDITONAL_DLLS} GREATER 0) 
        foreach(DLL ${ADDITIONAL_DLLS})
          file(APPEND ${CMAKE_CURRENT_SOURCE_DIR}/d.txt "x64 x64/${DLL}\n")        
        endforeach()
      endif()

		else()
			file(APPEND ${CMAKE_CURRENT_SOURCE_DIR}/d.txt "x86 x86/${PROJECT_NAME}.dll\n")
      if(${NUM_ADDITONAL_DLLS} GREATER 0) 
        foreach(DLL ${ADDITIONAL_DLLS})
          file(APPEND ${CMAKE_CURRENT_SOURCE_DIR}/d.txt "x86 x86/${DLL}\n")        
        endforeach()
      endif()      
		endif()	
	endif()
	install(FILES ${CMAKE_CURRENT_BINARY_DIR}/Release/${PROJECT_NAME}.dll DESTINATION ${NOMACS_PLUGIN_INSTALL_DIRECTORY}/${PLUGIN_ID}/${PLUGIN_VERSION}/${PLUGIN_ARCHITECTURE}/ CONFIGURATIONS Release)
	install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/d.txt DESTINATION ${NOMACS_PLUGIN_INSTALL_DIRECTORY}/${PLUGIN_ID}/${PLUGIN_VERSION}/ CONFIGURATIONS Release)
  if(${NUM_ADDITONAL_DLLS} GREATER 0) 
    foreach(DLL ${ADDITIONAL_DLLS})
      install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/bin/${DLL} DESTINATION ${NOMACS_PLUGIN_INSTALL_DIRECTORY}/${PLUGIN_ID}/${PLUGIN_VERSION}/${PLUGIN_ARCHITECTURE}/ CONFIGURATIONS Release)
    endforeach()
  endif()      
    
elseif(UNIX)
	install(TARGETS ${PROJECT_NAME} RUNTIME LIBRARY DESTINATION lib/nomacs-plugins)
endif(MSVC)
endmacro(NMC_CREATE_TARGETS)

macro (NMC_EXIV_INCLUDES)

# find_path(EXIV2_INCLUDE_DIRS "exiv2/exiv2.hpp" 
				# PATHS "../exiv2-0.25/include" 
				# DOC "Path to exiv2/exiv2.hpp" NO_DEFAULT_PATH)
# MARK_AS_ADVANCED(EXIV2_INCLUDE_DIRS)

endmacro (NMC_EXIV_INCLUDES)

