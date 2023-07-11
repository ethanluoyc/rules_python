"""Build rules for pybind11."""

PYBIND_COPTS = select({
    "@pybind11//:msvc_compiler": [],
    "//conditions:default": [
        "-fexceptions",
    ],
})

PYBIND_FEATURES = [
    "-use_header_modules",  # Required for pybind11.
    "-parse_headers",
]

PYBIND_DEPS = [
    "@pybind11",
    "@rules_python//python/cc:current_py_cc_headers",
]

# Builds a Python extension module using pybind11.
# This can be directly used in python with the import statement.
# This adds rules for a .so binary file.
def pybind_extension(
        name,
        copts = [],
        features = [],
        linkopts = [],
        tags = [],
        deps = [],
        **kwargs):
    # Mark common dependencies as required for build_cleaner.
    tags = tags + ["req_dep=%s" % dep for dep in PYBIND_DEPS]

    native.cc_binary(
        name = name + ".so",
        copts = copts + PYBIND_COPTS + select({
            "@pybind11//:msvc_compiler": [],
            "//conditions:default": [
                "-fvisibility=hidden",
            ],
        }),
        features = features + PYBIND_FEATURES,
        linkopts = linkopts + select({
            "@pybind11//:msvc_compiler": [],
            "@pybind11//:osx": [],
            "//conditions:default": ["-Wl,-Bsymbolic"],
        }),
        linkshared = 1,
        tags = tags,
        deps = deps + PYBIND_DEPS,
        **kwargs
    )
