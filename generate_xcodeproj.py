#!/usr/bin/env python3
"""Generate Zenith.xcodeproj/project.pbxproj and asset catalog JSON files."""

import uuid
import json
import os

BASE = "/Users/shahmeer/Desktop/projects/zenith"

def uid():
    return uuid.uuid4().hex[:24].upper()

swift_files = [
    "ContentView.swift",
    "ZenithApp.swift",
    "Models/FoodEntry.swift",
    "Models/FoodItem.swift",
    "Models/UserSettings.swift",
    "Networking/APIClient.swift",
    "Networking/DTOs/FoodRecognitionRequest.swift",
    "Networking/DTOs/FoodRecognitionResponse.swift",
    "Networking/DTOs/SyncDownloadRequest.swift",
    "Networking/DTOs/SyncDownloadResponse.swift",
    "Networking/DTOs/SyncUploadRequest.swift",
    "Networking/DTOs/SyncUploadResponse.swift",
    "Networking/LiveAPIClient.swift",
    "Networking/MockAPIClient.swift",
    "Services/PhotoRecognitionService.swift",
    "Services/SyncService.swift",
    "Utilities/Color+Theme.swift",
    "Utilities/Date+Extensions.swift",
    "Views/AddEntry/AddEntryView.swift",
    "Views/AddEntry/FoodSearchView.swift",
    "Views/AddEntry/PhotoCaptureView.swift",
    "Views/Dashboard/CalorieRingView.swift",
    "Views/Dashboard/DashboardView.swift",
    "Views/Dashboard/MacroSummaryView.swift",
    "Views/Dashboard/RecentEntriesListView.swift",
    "Views/FoodLibrary/FoodItemDetailView.swift",
    "Views/FoodLibrary/FoodLibraryView.swift",
    "Views/History/DayDetailView.swift",
    "Views/History/HistoryView.swift",
    "Views/Settings/SettingsView.swift",
    "Views/Shared/MacroLabel.swift",
    "Views/Shared/NutritionFormFields.swift",
]

file_refs = {}
build_files = {}
for f in swift_files:
    file_refs[f] = uid()
    build_files[f] = uid()

assets_ref = uid()
assets_build = uid()

group_names = [
    "Zenith",
    "Models",
    "Networking",
    "Networking/DTOs",
    "Services",
    "Utilities",
    "Views",
    "Views/AddEntry",
    "Views/Dashboard",
    "Views/FoodLibrary",
    "Views/History",
    "Views/Settings",
    "Views/Shared",
]
group_uuids = {}
for g in group_names:
    group_uuids[g] = uid()

main_group_id = uid()
products_group_id = uid()
project_id = uid()
target_id = uid()
config_list_project = uid()
config_list_target = uid()
config_debug_project = uid()
config_release_project = uid()
config_debug_target = uid()
config_release_target = uid()
sources_phase = uid()
resources_phase = uid()
frameworks_phase = uid()
product_ref = uid()

def group_children(group_key):
    children = []
    for g in group_names:
        if g == group_key:
            continue
        parts = g.rsplit("/", 1)
        parent = parts[0] if len(parts) == 2 else "Zenith"
        if g == "Zenith":
            continue
        if parent == group_key:
            children.append((group_uuids[g], True, g.rsplit("/", 1)[-1]))
    for f in swift_files:
        parts = f.rsplit("/", 1)
        parent = parts[0] if len(parts) == 2 else "Zenith"
        if parent == group_key:
            children.append((file_refs[f], False, parts[-1] if len(parts) == 2 else f))
    if group_key == "Zenith":
        children.append((assets_ref, False, "Assets.xcassets"))
    return children

def pbx_build_file_section():
    lines = ["/* Begin PBXBuildFile section */"]
    for f in swift_files:
        name = os.path.basename(f)
        lines.append(f"\t\t{build_files[f]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {name} */; }};")
    lines.append(f"\t\t{assets_build} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_ref} /* Assets.xcassets */; }};")
    lines.append("/* End PBXBuildFile section */")
    return "\n".join(lines)

def pbx_file_reference_section():
    lines = ["/* Begin PBXFileReference section */"]
    for f in swift_files:
        name = os.path.basename(f)
        lines.append(f'\t\t{file_refs[f]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{name}"; sourceTree = "<group>"; }};')
    lines.append(f'\t\t{assets_ref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};')
    lines.append(f'\t\t{product_ref} /* Zenith.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Zenith.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    lines.append("/* End PBXFileReference section */")
    return "\n".join(lines)

def format_group(uid_val, name, children_list, path=None, is_main=False):
    kids = "\n".join([f"\t\t\t\t{c[0]} /* {c[2]} */," for c in children_list])
    if is_main:
        return (
            f"\t\t{uid_val} = {{\n"
            f"\t\t\tisa = PBXGroup;\n"
            f"\t\t\tchildren = (\n{kids}\n\t\t\t);\n"
            f'\t\t\tsourceTree = "<group>";\n'
            f"\t\t}};"
        )
    p = path if path else name
    return (
        f"\t\t{uid_val} /* {name} */ = {{\n"
        f"\t\t\tisa = PBXGroup;\n"
        f"\t\t\tchildren = (\n{kids}\n\t\t\t);\n"
        f'\t\t\tpath = "{p}";\n'
        f'\t\t\tsourceTree = "<group>";\n'
        f"\t\t}};"
    )

def pbx_group_section():
    lines = ["/* Begin PBXGroup section */"]
    main_children = [
        (group_uuids["Zenith"], True, "Zenith"),
        (products_group_id, True, "Products"),
    ]
    lines.append(format_group(main_group_id, "__main__", main_children, is_main=True))
    prod_children = [(product_ref, False, "Zenith.app")]
    lines.append(
        f"\t\t{products_group_id} /* Products */ = {{\n"
        f"\t\t\tisa = PBXGroup;\n"
        f"\t\t\tchildren = (\n\t\t\t\t{product_ref} /* Zenith.app */,\n\t\t\t);\n"
        f"\t\t\tname = Products;\n"
        f'\t\t\tsourceTree = "<group>";\n'
        f"\t\t}};"
    )
    for g in group_names:
        children = group_children(g)
        name = g.rsplit("/", 1)[-1] if "/" in g else g
        lines.append(format_group(group_uuids[g], name, children, path=name))
    lines.append("/* End PBXGroup section */")
    return "\n".join(lines)

def pbx_sources_build_phase():
    lines = ["/* Begin PBXSourcesBuildPhase section */"]
    file_lines = "\n".join([f"\t\t\t\t{build_files[f]} /* {os.path.basename(f)} in Sources */," for f in swift_files])
    lines.append(
        f"\t\t{sources_phase} /* Sources */ = {{\n"
        f"\t\t\tisa = PBXSourcesBuildPhase;\n"
        f"\t\t\tbuildActionMask = 2147483647;\n"
        f"\t\t\tfiles = (\n{file_lines}\n\t\t\t);\n"
        f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        f"\t\t}};"
    )
    lines.append("/* End PBXSourcesBuildPhase section */")
    return "\n".join(lines)

def pbx_resources_build_phase():
    lines = ["/* Begin PBXResourcesBuildPhase section */"]
    lines.append(
        f"\t\t{resources_phase} /* Resources */ = {{\n"
        f"\t\t\tisa = PBXResourcesBuildPhase;\n"
        f"\t\t\tbuildActionMask = 2147483647;\n"
        f"\t\t\tfiles = (\n"
        f"\t\t\t\t{assets_build} /* Assets.xcassets in Resources */,\n"
        f"\t\t\t);\n"
        f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        f"\t\t}};"
    )
    lines.append("/* End PBXResourcesBuildPhase section */")
    return "\n".join(lines)

def pbx_frameworks_build_phase():
    lines = ["/* Begin PBXFrameworksBuildPhase section */"]
    lines.append(
        f"\t\t{frameworks_phase} /* Frameworks */ = {{\n"
        f"\t\t\tisa = PBXFrameworksBuildPhase;\n"
        f"\t\t\tbuildActionMask = 2147483647;\n"
        f"\t\t\tfiles = (\n\t\t\t);\n"
        f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        f"\t\t}};"
    )
    lines.append("/* End PBXFrameworksBuildPhase section */")
    return "\n".join(lines)

def pbx_native_target():
    lines = ["/* Begin PBXNativeTarget section */"]
    lines.append(
        f"\t\t{target_id} /* Zenith */ = {{\n"
        f"\t\t\tisa = PBXNativeTarget;\n"
        f"\t\t\tbuildConfigurationList = {config_list_target} /* Build configuration list for PBXNativeTarget \"Zenith\" */;\n"
        f"\t\t\tbuildPhases = (\n"
        f"\t\t\t\t{sources_phase} /* Sources */,\n"
        f"\t\t\t\t{frameworks_phase} /* Frameworks */,\n"
        f"\t\t\t\t{resources_phase} /* Resources */,\n"
        f"\t\t\t);\n"
        f"\t\t\tbuildRules = (\n\t\t\t);\n"
        f"\t\t\tdependencies = (\n\t\t\t);\n"
        f"\t\t\tname = Zenith;\n"
        f"\t\t\tproductName = Zenith;\n"
        f"\t\t\tproductReference = {product_ref} /* Zenith.app */;\n"
        f'\t\t\tproductType = "com.apple.product-type.application";\n'
        f"\t\t}};"
    )
    lines.append("/* End PBXNativeTarget section */")
    return "\n".join(lines)

def pbx_project():
    lines = ["/* Begin PBXProject section */"]
    lines.append(
        f"\t\t{project_id} /* Project object */ = {{\n"
        f"\t\t\tisa = PBXProject;\n"
        f"\t\t\tattributes = {{\n"
        f"\t\t\t\tBuildIndependentTargetsInParallel = 1;\n"
        f"\t\t\t\tLastSwiftUpdateCheck = 1600;\n"
        f"\t\t\t\tLastUpgradeCheck = 1600;\n"
        f"\t\t\t}};\n"
        f"\t\t\tbuildConfigurationList = {config_list_project} /* Build configuration list for PBXProject \"Zenith\" */;\n"
        f'\t\t\tcompatibilityVersion = "Xcode 15.0";\n'
        f"\t\t\tdevelopmentRegion = en;\n"
        f"\t\t\thasScannedForEncodings = 0;\n"
        f"\t\t\tknownRegions = (\n"
        f"\t\t\t\ten,\n"
        f"\t\t\t\tBase,\n"
        f"\t\t\t);\n"
        f"\t\t\tmainGroup = {main_group_id};\n"
        f"\t\t\tproductRefGroup = {products_group_id} /* Products */;\n"
        f'\t\t\tprojectDirPath = "";\n'
        f'\t\t\tprojectRoot = "";\n'
        f"\t\t\ttargets = (\n"
        f"\t\t\t\t{target_id} /* Zenith */,\n"
        f"\t\t\t);\n"
        f"\t\t}};"
    )
    lines.append("/* End PBXProject section */")
    return "\n".join(lines)

def xc_build_configuration():
    lines = ["/* Begin XCBuildConfiguration section */"]

    # Project Debug
    lines.append(
        f'\t\t{config_debug_project} /* Debug */ = {{\n'
        f'\t\t\tisa = XCBuildConfiguration;\n'
        f'\t\t\tbuildSettings = {{\n'
        f'\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;\n'
        f'\t\t\t\tCLANG_ANALYZER_NONNULL = YES;\n'
        f'\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;\n'
        f'\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";\n'
        f'\t\t\t\tCLANG_ENABLE_MODULES = YES;\n'
        f'\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;\n'
        f'\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;\n'
        f'\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;\n'
        f'\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;\n'
        f'\t\t\t\tCLANG_WARN_COMMA = YES;\n'
        f'\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;\n'
        f'\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;\n'
        f'\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;\n'
        f'\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;\n'
        f'\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;\n'
        f'\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;\n'
        f'\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;\n'
        f'\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;\n'
        f'\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;\n'
        f'\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;\n'
        f'\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;\n'
        f'\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;\n'
        f'\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;\n'
        f'\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;\n'
        f'\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;\n'
        f'\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;\n'
        f'\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;\n'
        f'\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;\n'
        f'\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;\n'
        f'\t\t\t\tCOPY_PHASE_STRIP = NO;\n'
        f'\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;\n'
        f'\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;\n'
        f'\t\t\t\tENABLE_TESTABILITY = YES;\n'
        f'\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;\n'
        f'\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;\n'
        f'\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;\n'
        f'\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;\n'
        f'\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;\n'
        f'\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (\n'
        f'\t\t\t\t\t"DEBUG=1",\n'
        f'\t\t\t\t\t"$(inherited)",\n'
        f'\t\t\t\t);\n'
        f'\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;\n'
        f'\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;\n'
        f'\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;\n'
        f'\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;\n'
        f'\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;\n'
        f'\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;\n'
        f'\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;\n'
        f'\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;\n'
        f'\t\t\t\tMTL_FAST_MATH = YES;\n'
        f'\t\t\t\tONLY_ACTIVE_ARCH = YES;\n'
        f'\t\t\t\tSDKROOT = iphoneos;\n'
        f'\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";\n'
        f'\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";\n'
        f'\t\t\t}};\n'
        f'\t\t\tname = Debug;\n'
        f'\t\t}};'
    )

    # Project Release
    lines.append(
        f'\t\t{config_release_project} /* Release */ = {{\n'
        f'\t\t\tisa = XCBuildConfiguration;\n'
        f'\t\t\tbuildSettings = {{\n'
        f'\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;\n'
        f'\t\t\t\tCLANG_ANALYZER_NONNULL = YES;\n'
        f'\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;\n'
        f'\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";\n'
        f'\t\t\t\tCLANG_ENABLE_MODULES = YES;\n'
        f'\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;\n'
        f'\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;\n'
        f'\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;\n'
        f'\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;\n'
        f'\t\t\t\tCLANG_WARN_COMMA = YES;\n'
        f'\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;\n'
        f'\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;\n'
        f'\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;\n'
        f'\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;\n'
        f'\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;\n'
        f'\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;\n'
        f'\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;\n'
        f'\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;\n'
        f'\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;\n'
        f'\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;\n'
        f'\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;\n'
        f'\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;\n'
        f'\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;\n'
        f'\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;\n'
        f'\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;\n'
        f'\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;\n'
        f'\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;\n'
        f'\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;\n'
        f'\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;\n'
        f'\t\t\t\tCOPY_PHASE_STRIP = NO;\n'
        f'\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";\n'
        f'\t\t\t\tENABLE_NS_ASSERTIONS = NO;\n'
        f'\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;\n'
        f'\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;\n'
        f'\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;\n'
        f'\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;\n'
        f'\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;\n'
        f'\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;\n'
        f'\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;\n'
        f'\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;\n'
        f'\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;\n'
        f'\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;\n'
        f'\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;\n'
        f'\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;\n'
        f'\t\t\t\tMTL_FAST_MATH = YES;\n'
        f'\t\t\t\tSDKROOT = iphoneos;\n'
        f'\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;\n'
        f'\t\t\t\tVALIDATE_PRODUCT = YES;\n'
        f'\t\t\t}};\n'
        f'\t\t\tname = Release;\n'
        f'\t\t}};'
    )

    # Target Debug
    lines.append(
        f'\t\t{config_debug_target} /* Debug */ = {{\n'
        f'\t\t\tisa = XCBuildConfiguration;\n'
        f'\t\t\tbuildSettings = {{\n'
        f'\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;\n'
        f'\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;\n'
        f'\t\t\t\tCODE_SIGN_STYLE = Automatic;\n'
        f'\t\t\t\tCURRENT_PROJECT_VERSION = 1;\n'
        f'\t\t\t\tDEVELOPMENT_ASSET_PATHS = "";\n'
        f'\t\t\t\tENABLE_PREVIEWS = YES;\n'
        f'\t\t\t\tGENERATE_INFOPLIST_FILE = YES;\n'
        f'\t\t\t\tINFOPLIST_KEY_NSCameraUsageDescription = "Zenith needs camera access to recognize food from photos.";\n'
        f'\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;\n'
        f'\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;\n'
        f'\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;\n'
        f'\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";\n'
        f'\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";\n'
        f'\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;\n'
        f'\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\n'
        f'\t\t\t\t\t"$(inherited)",\n'
        f'\t\t\t\t\t"@executable_path/Frameworks",\n'
        f'\t\t\t\t);\n'
        f'\t\t\t\tMARKETING_VERSION = 1.0;\n'
        f'\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.zenith.app;\n'
        f'\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";\n'
        f'\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;\n'
        f'\t\t\t\tSWIFT_VERSION = 5.0;\n'
        f'\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";\n'
        f'\t\t\t}};\n'
        f'\t\t\tname = Debug;\n'
        f'\t\t}};'
    )

    # Target Release
    lines.append(
        f'\t\t{config_release_target} /* Release */ = {{\n'
        f'\t\t\tisa = XCBuildConfiguration;\n'
        f'\t\t\tbuildSettings = {{\n'
        f'\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;\n'
        f'\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;\n'
        f'\t\t\t\tCODE_SIGN_STYLE = Automatic;\n'
        f'\t\t\t\tCURRENT_PROJECT_VERSION = 1;\n'
        f'\t\t\t\tDEVELOPMENT_ASSET_PATHS = "";\n'
        f'\t\t\t\tENABLE_PREVIEWS = YES;\n'
        f'\t\t\t\tGENERATE_INFOPLIST_FILE = YES;\n'
        f'\t\t\t\tINFOPLIST_KEY_NSCameraUsageDescription = "Zenith needs camera access to recognize food from photos.";\n'
        f'\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;\n'
        f'\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;\n'
        f'\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;\n'
        f'\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";\n'
        f'\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";\n'
        f'\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;\n'
        f'\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\n'
        f'\t\t\t\t\t"$(inherited)",\n'
        f'\t\t\t\t\t"@executable_path/Frameworks",\n'
        f'\t\t\t\t);\n'
        f'\t\t\t\tMARKETING_VERSION = 1.0;\n'
        f'\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.zenith.app;\n'
        f'\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";\n'
        f'\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;\n'
        f'\t\t\t\tSWIFT_VERSION = 5.0;\n'
        f'\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";\n'
        f'\t\t\t}};\n'
        f'\t\t\tname = Release;\n'
        f'\t\t}};'
    )

    lines.append("/* End XCBuildConfiguration section */")
    return "\n".join(lines)

def xc_configuration_list():
    lines = ["/* Begin XCConfigurationList section */"]
    lines.append(
        f'\t\t{config_list_project} /* Build configuration list for PBXProject "Zenith" */ = {{\n'
        f'\t\t\tisa = XCConfigurationList;\n'
        f'\t\t\tbuildConfigurations = (\n'
        f'\t\t\t\t{config_debug_project} /* Debug */,\n'
        f'\t\t\t\t{config_release_project} /* Release */,\n'
        f'\t\t\t);\n'
        f'\t\t\tdefaultConfigurationIsVisible = 0;\n'
        f'\t\t\tdefaultConfigurationName = Release;\n'
        f'\t\t}};'
    )
    lines.append(
        f'\t\t{config_list_target} /* Build configuration list for PBXNativeTarget "Zenith" */ = {{\n'
        f'\t\t\tisa = XCConfigurationList;\n'
        f'\t\t\tbuildConfigurations = (\n'
        f'\t\t\t\t{config_debug_target} /* Debug */,\n'
        f'\t\t\t\t{config_release_target} /* Release */,\n'
        f'\t\t\t);\n'
        f'\t\t\tdefaultConfigurationIsVisible = 0;\n'
        f'\t\t\tdefaultConfigurationName = Release;\n'
        f'\t\t}};'
    )
    lines.append("/* End XCConfigurationList section */")
    return "\n".join(lines)

def generate_pbxproj():
    return (
        "// !$*UTF8*$!\n"
        "{\n"
        "\tarchiveVersion = 1;\n"
        "\tclasses = {\n"
        "\t};\n"
        "\tobjectVersion = 56;\n"
        "\tobjects = {\n"
        "\n"
        f"{pbx_build_file_section()}\n"
        "\n"
        f"{pbx_file_reference_section()}\n"
        "\n"
        f"{pbx_frameworks_build_phase()}\n"
        "\n"
        f"{pbx_group_section()}\n"
        "\n"
        f"{pbx_native_target()}\n"
        "\n"
        f"{pbx_project()}\n"
        "\n"
        f"{pbx_resources_build_phase()}\n"
        "\n"
        f"{pbx_sources_build_phase()}\n"
        "\n"
        f"{xc_build_configuration()}\n"
        "\n"
        f"{xc_configuration_list()}\n"
        "\n"
        "\t};\n"
        f"\trootObject = {project_id} /* Project object */;\n"
        "}\n"
    )

def write_asset_catalogs():
    contents = {"info": {"author": "xcode", "version": 1}}
    accent = {
        "colors": [{"idiom": "universal"}],
        "info": {"author": "xcode", "version": 1}
    }
    appicon = {
        "images": [{"idiom": "universal", "platform": "ios", "size": "1024x1024"}],
        "info": {"author": "xcode", "version": 1}
    }
    paths = {
        os.path.join(BASE, "Zenith/Assets.xcassets/Contents.json"): contents,
        os.path.join(BASE, "Zenith/Assets.xcassets/AccentColor.colorset/Contents.json"): accent,
        os.path.join(BASE, "Zenith/Assets.xcassets/AppIcon.appiconset/Contents.json"): appicon,
    }
    for path, data in paths.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            json.dump(data, f, indent=2)
            f.write("\n")
        print(f"  Written: {path}")

if __name__ == "__main__":
    pbxproj_path = os.path.join(BASE, "Zenith.xcodeproj/project.pbxproj")
    os.makedirs(os.path.dirname(pbxproj_path), exist_ok=True)
    with open(pbxproj_path, "w") as f:
        f.write(generate_pbxproj())
    print(f"  Written: {pbxproj_path}")
    write_asset_catalogs()
    print("\nDone! Xcode project generated successfully.")
