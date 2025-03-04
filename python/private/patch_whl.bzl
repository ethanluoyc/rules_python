# Copyright 2023 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""A small utility to patch a file in the repository context and repackage it using a Python interpreter

Note, because we are patching a wheel file and we need a new RECORD file, this
function will print a diff of the RECORD and will ask the user to include a
RECORD patch in their patches that they maintain. This is to ensure that we can
satisfy the following usecases:
* Patch an invalid RECORD file.
* Patch files within a wheel.

If we were silently regenerating the RECORD file, we may be vulnerable to supply chain
attacks (it is a very small chance) and keeping the RECORD patches next to the
other patches ensures that the users have overview on exactly what has changed
within the wheel.
"""

load("//python/private:parse_whl_name.bzl", "parse_whl_name")

_rules_python_root = Label("//:BUILD.bazel")

def patch_whl(rctx, *, python_interpreter, whl_path, patches, **kwargs):
    """Patch a whl file and repack it to ensure that the RECORD metadata stays correct.

    Args:
        rctx: repository_ctx
        python_interpreter: the python interpreter to use.
        whl_path: The whl file name to be patched.
        patches: a label-keyed-int dict that has the patch files as keys and
            the patch_strip as the value.
        **kwargs: extras passed to rctx.execute.

    Returns:
        value of the repackaging action.
    """

    # extract files into the current directory for patching as rctx.patch
    # does not support patching in another directory.
    whl_input = rctx.path(whl_path)

    # symlink to a zip file to use bazel's extract so that we can use bazel's
    # repository_ctx patch implementation. The whl file may be in a different
    # external repository.
    whl_file_zip = whl_input.basename + ".zip"
    rctx.symlink(whl_input, whl_file_zip)
    rctx.extract(whl_file_zip)
    if not rctx.delete(whl_file_zip):
        fail("Failed to remove the symlink after extracting")

    for patch_file, patch_strip in patches.items():
        rctx.patch(patch_file, strip = patch_strip)

    # Generate an output filename, which we will be returning
    parsed_whl = parse_whl_name(whl_input.basename)
    whl_patched = "{}.whl".format("-".join([
        parsed_whl.distribution,
        parsed_whl.version,
        (parsed_whl.build_tag or "") + "patched",
        parsed_whl.python_tag,
        parsed_whl.abi_tag,
        parsed_whl.platform_tag,
    ]))

    result = rctx.execute(
        [
            python_interpreter,
            "-m",
            "python.private.repack_whl",
            whl_input,
            whl_patched,
        ],
        environment = {
            "PYTHONPATH": str(rctx.path(_rules_python_root).dirname),
        },
        **kwargs
    )

    if result.return_code:
        fail(
            "repackaging .whl {whl} failed: with exit code '{return_code}':\n{stdout}\n\nstderr:\n{stderr}".format(
                whl = whl_input.basename,
                stdout = result.stdout,
                stderr = result.stderr,
                return_code = result.return_code,
            ),
        )

    return rctx.path(whl_patched)
