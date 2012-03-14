# - Find intltool (requires Gettext package)
# This module looks for intltool. This module defines the following 
# values:
#  INTLTOOL_MERGE_EXECUTABLE: the full path to the intltool-merge tool.
#  INTLTOOL_UPDATE_EXECUTABLE: the full path to the intltool-update tool.
#  INTLTOOL_FOUND: True if intltool has been found.
#
# Additionally it provides the following macros:
#
# This module is more flexible than the default Makefile created by
# intltool used with autotools. You can have more than one gettext 
# package in one project.
#
# INTLTOOL_DESKTOP_ENTRY ( desktop_in_file, po_dir )
#     This will merge translations in po files with desktop entry file.
#     desktop_in_file: the *.desktop.in file
#     po_dir: the directory containing *.po files
#
# INTLTOOL_CREATE_TRANSLATIONS ( gettext_package )
#     This will create a target "${gettext_package}_update-po" which will
#     convert the given input po files into the binary output mo file.
#
# Author: Hong Jen Yee (PCMan) <pcman.tw@gmail.com>
# Copyright (C) 2011
# License: MIT

if(__FIND_INTLTOOL_INCLUDED)
  return()
endif(__FIND_INTLTOOL_INCLUDED)
set(__FIND_INTLTOOL_INCLUDED TRUE)

cmake_minimum_required (VERSION 2.8.3) # required version of cmake

include (CMakeParseArguments)

find_package(Gettext)
find_program(INTLTOOL_MERGE_EXECUTABLE intltool-merge)
find_program(INTLTOOL_UPDATE_EXECUTABLE intltool-update)

# add a target used to update all po files
# add_custom_target(update-po)

macro (INTLTOOL_DESKTOP_ENTRY _desktop_in_file _po_dir)
    get_filename_component(_desktop_in_file_path ${_desktop_in_file} ABSOLUTE)
    get_filename_component(_desktop_file_name_we ${_desktop_in_file} NAME_WE)
    set (_desktop_file_name "${_desktop_file_name_we}.desktop")

    get_filename_component(_po_dir_path ${_po_dir} ABSOLUTE)

    # FIXME: add correct dependencies rather than using ALL
    add_custom_target(${_desktop_file_name} ALL
        ${INTLTOOL_MERGE_EXECUTABLE} -d
        ${_po_dir_path}
        ${_desktop_in_file_path}
        ${CMAKE_CURRENT_BINARY_DIR}/${_desktop_file_name}
    )

    # TODO: make the installation optional
    install (FILES
        ${CMAKE_CURRENT_BINARY_DIR}/${_desktop_file_name}
        DESTINATION share/applications
    )
endmacro (INTLTOOL_DESKTOP_ENTRY)

macro (INTLTOOL_CREATE_TRANSLATIONS)
	set (options NO_INSTALL)
	set (oneValueArgs GETTEXT_PACKAGE PO_DIRECTORY)
	set(multiValueArgs ALL_LINGUAS)
	cmake_parse_arguments(IT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

	# keep the generated files from "make clean"
	set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY CLEAN_NO_CUSTOM true)

	# set gettext package name
	if(NOT IT_GETTEXT_PACKAGE)
		set (IT_GETTEXT_PACKAGE ${GETTEXT_PACKAGE})
	endif(NOT IT_GETTEXT_PACKAGE)

	# set directory containing the po files
	if(NOT IT_PO_DIRECTORY)
		set (IT_PO_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
	endif(NOT IT_PO_DIRECTORY)
	# get full path of po directory
	get_filename_component(IT_PO_DIRECTORY ${IT_PO_DIRECTORY} ABSOLUTE)

	# for *.pot file
	set (pot_name "${IT_GETTEXT_PACKAGE}.pot")
	set (pot_path "${IT_PO_DIRECTORY}/${pot_name}")

	# check if ALL_LINGUAS is set
	if (NOT IT_ALL_LINGUAS)
		# if its not set, read from po/LINGUAS file
		set (linguas_file_path  "${IT_PO_DIRECTORY}/LINGUAS")
		if (EXISTS ${linguas_file_path})
			# read LINGUAS and build a list of po files according to its content
			file(STRINGS ${linguas_file_path} IT_ALL_LINGUAS)
		endif (EXISTS ${linguas_file_path})
	endif (NOT IT_ALL_LINGUAS)

	if (IT_ALL_LINGUAS)
		# generate po filenames with language list
		set (po_file_names "")
		foreach(lang ${IT_ALL_LINGUAS})
			list(APPEND po_file_names "${lang}.po")
		endforeach(lang)
	else (IT_ALL_LINGUAS)
		# generate language list by looking for *.po files
		file(GLOB po_file_names RELATIVE ${IT_PO_DIRECTORY} "${IT_PO_DIRECTORY}/*.po")
		set (IT_ALL_LINGUAS "")
		foreach(po_file_name ${po_file_names})
			get_filename_component(lang ${po_file_name} NAME_WE)
			list (APPEND IT_ALL_LINGUAS ${lang})
		endforeach(po_file_name)
	endif (IT_ALL_LINGUAS)

	# load POTFILES.in file and store its content in list pot_src_files.
    set (pot_src_files "")
    set (potfiles_in_path  "${IT_PO_DIRECTORY}/POTFILES.in")
    if (EXISTS ${potfiles_in_path})
        # read POTFILES.in file
        file(STRINGS ${potfiles_in_path} potfiles_in_lines)
        foreach (line ${potfiles_in_lines})
            # omit lines starts with #
            if (NOT ${line} MATCHES "^#.*")
                # need to remove things like [type: gettext/glade]
                # regexp for it: \s*\[type:[^]]*\]\s*
                string (REGEX REPLACE "[ \\t]*\\[type:[^]]*\\][ \\t]*" "" pot_src_file ${line})
                list (APPEND pot_src_files "${CMAKE_SOURCE_DIR}/${pot_src_file}")
            endif (NOT ${line} MATCHES "^#.*")
        endforeach (line)
    endif (EXISTS ${potfiles_in_path})
message(STATUS ${pot_path})
	# generate command to build the pot file from files listed in POTFILES.in
    add_custom_command(
        OUTPUT ${pot_path}
        COMMAND ${INTLTOOL_UPDATE_EXECUTABLE} --pot --gettext-package ${IT_GETTEXT_PACKAGE}
        WORKING_DIRECTORY ${IT_PO_DIRECTORY}
        DEPENDS ${potfiles_in_path} ${pot_src_files}
    )

	# generate build rules to compile po files to gmo files
	# due to some limitations of CMake gettext module, we did not
	# use its GETTEXT_CREATE_TRANSLATIONS macro but made our own.
	set (gmo_paths "")
	foreach (po_name ${po_file_names})
		set (po_path "${IT_PO_DIRECTORY}/${po_name}")
		get_filename_component(lang ${po_name} NAME_WE)
        set (gmo_path "${CMAKE_CURRENT_BINARY_DIR}/${lang}.gmo")

		# rebuild po files depending on the pot file.
        add_custom_command(
            OUTPUT ${po_path}
            COMMAND ${INTLTOOL_UPDATE_EXECUTABLE} --dist ${lang} --gettext-package ${IT_GETTEXT_PACKAGE}
            WORKING_DIRECTORY ${IT_PO_DIRECTORY}
            DEPENDS ${pot_path}
        )

		# build gmo files from po files
        add_custom_command(
            OUTPUT ${gmo_path}
            # COMMAND ${INTLTOOL_UPDATE_EXECUTABLE} --dist ${lang} --gettext-package ${IT_GETTEXT_PACKAGE}
            COMMAND ${GETTEXT_MSGFMT_EXECUTABLE} -o ${gmo_path} ${po_path}
            DEPENDS ${po_path}
        )
        list (APPEND gmo_paths "${gmo_path}")

		if (NOT IT_NO_INSTALL)
			install (FILES "${gmo_path}"
				DESTINATION "share/locale/${lang}/LC_MESSAGES"
				RENAME "${IT_GETTEXT_PACKAGE}.mo"
			)
		endif (NOT IT_NO_INSTALL)

	endforeach (po_name)

	# this target only compiles po files to mo files and install them.
	# it does not sync po files with pot.
	# to update all po files and the pot file, use make update-po
    add_custom_target (${IT_GETTEXT_PACKAGE}_translations ALL
        DEPENDS ${pot_path} ${gmo_paths}
    )

endmacro (INTLTOOL_CREATE_TRANSLATIONS)


# FIXME: use standard stuff instead
# include(FindPackageHandleStandardArgs)
# find_package_handle_standard_args(LibXml2  DEFAULT_MSG
#                                  LIBXML2_LIBRARY LIBXML2_INCLUDE_DIR)
# handle the QUIETLY and REQUIRED arguments and set LIBXML2_FOUND to TRUE
# if all listed variables are TRUE

if (NOT GETTEXT_FOUND)
   if (Intltool_REQUIRED)
      MESSAGE(FATAL_ERROR "Gettext not found")
   endif (Intltool_REQUIRED)
endif (NOT GETTEXT_FOUND)

if (INTLTOOL_MERGE_EXECUTABLE AND INTLTOOL_UPDATE_EXECUTABLE)
   set(INTLTOOL_FOUND TRUE)
else (INTLTOOL_MERGE_EXECUTABLE AND INTLTOOL_UPDATE_EXECUTABLE)
   set(INTLTOOL_FOUND FALSE)
   if (Intltool_REQUIRED)
      MESSAGE(FATAL_ERROR "Intltool not found")
   endif (Intltool_REQUIRED)
endif (INTLTOOL_MERGE_EXECUTABLE AND INTLTOOL_UPDATE_EXECUTABLE)
