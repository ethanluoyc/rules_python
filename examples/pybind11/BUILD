load("@rules_python//python:defs.bzl", "py_binary")
load("//:build_defs.bzl", "pybind_extension")


pybind_extension(
    name = "add",
    srcs = ["add.cpp"]
)

py_binary(
    name = "main",
    srcs = ["main.py"],
    data = [":add.so"]
)
