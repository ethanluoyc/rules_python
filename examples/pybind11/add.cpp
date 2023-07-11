#include <numeric>

#include <iostream>
#include <pybind11/pybind11.h>

#define STRINGIFY(x) #x
#define MACRO_STRINGIFY(x) STRINGIFY(x)

namespace py = pybind11;

int add(int a, int b) {
  return a + b; 
}

namespace py = pybind11;

PYBIND11_MODULE(add, m) {
  m.doc() = R"pbdoc(
        A module to add integers
        -----------------------
    )pbdoc";

  m.def("add", &add, py::arg("a"),
        py::arg("b"));

}
