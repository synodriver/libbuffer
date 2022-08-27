# -*- coding: utf-8 -*-
import glob
import os
import re
import sys
from collections import defaultdict

try:
    from Cython.Build import cythonize
except ImportError:
    Cython = None
from setuptools import Extension, find_packages, setup
from setuptools.command.build_ext import build_ext

BUILD_ARGS = defaultdict(lambda: ["-O3", "-g0"])

for compiler, args in [
    ("msvc", ["/EHsc", "/DHUNSPELL_STATIC", "/Oi", "/O2", "/Ot"]),
    ("gcc", ["-O3", "-g0"]),
]:
    BUILD_ARGS[compiler] = args


class build_ext_compiler_check(build_ext):
    def build_extensions(self):
        compiler = self.compiler.compiler_type
        args = BUILD_ARGS[compiler]
        for ext in self.extensions:
            ext.extra_compile_args = args
            if self.compiler.compiler_type == "msvc":
                ext.define_macros.extend([("restrict", "__restrict")])
        super().build_extensions()


c_sources = ["libbuffer/backends/cython/_buffer.pyx", "c-buffer/src/buffer.c"]

extensions = [
    Extension(
        "libbuffer.backends.cython._buffer",
        c_sources,
        include_dirs=["./c-buffer/src"],
        define_macros=[
            ("BUFFER_MALLOC", "PyMem_Malloc"),
            ("BUFFER_REALLOC", "PyMem_Realloc"),
            ("BUFFER_FREE", "PyMem_Free"),
            ("BUFFER_INCLUDE", '"Python.h"'),
        ],
    ),
    Extension(
        "libbuffer.backends.cython._ringbuffer",
        ["libbuffer/backends/cython/_ringbuffer.pyx", "c-buffer/src/ringbuffer.c"],
        include_dirs=["./c-buffer/src"],
        define_macros=[
            ("BUFFER_MALLOC", "PyMem_Malloc"),
            ("BUFFER_REALLOC", "PyMem_Realloc"),
            ("BUFFER_FREE", "PyMem_Free"),
            ("BUFFER_INCLUDE", '"Python.h"'),
        ],
    ),
]
cffi_modules = ["libbuffer/backends/cffi/build.py:ffibuilder"]


def get_dis():
    with open("README.markdown", "r", encoding="utf-8") as f:
        return f.read()


def get_version() -> str:
    path = os.path.join(
        os.path.abspath(os.path.dirname(__file__)), "libbuffer", "__init__.py"
    )
    with open(path, "r", encoding="utf-8") as f:
        data = f.read()
    result = re.findall(r"(?<=__version__ = \")\S+(?=\")", data)
    return result[0]


packages = find_packages(exclude=("test", "tests.*", "test*"))


def has_option(name: str) -> bool:
    if name in sys.argv[1:]:
        sys.argv.remove(name)
        return True
    return False


setup_requires = []
install_requires = []
setup_kw = {}
if has_option("--use-cython"):
    print("building cython")
    setup_requires.append("cython")
    setup_kw["ext_modules"] = cythonize(
        extensions,
        compiler_directives={
            "cdivision": True,
            "embedsignature": True,
            "boundscheck": False,
            "wraparound": False,
        },
    )
if has_option("--use-cffi"):
    print("building cffi")
    setup_requires.append("cffi>=1.0.0")
    install_requires.append("cffi>=1.0.0")
    setup_kw["cffi_modules"] = cffi_modules


def main():
    version: str = get_version()

    dis = get_dis()
    setup(
        name="libbuffer",
        version=version,
        url="https://github.com/synodriver/libbuffer",
        packages=packages,
        keywords=["buffer", "compress", "decompress"],
        description="buffer compress and decompress",
        long_description_content_type="text/markdown",
        long_description=dis,
        author="synodriver",
        author_email="diguohuangjiajinweijun@gmail.com",
        python_requires=">=3.6",
        setup_requires=setup_requires,
        install_requires=install_requires,
        license="BSD",
        classifiers=[
            "Development Status :: 3 - Alpha",
            "Operating System :: OS Independent",
            "License :: OSI Approved :: GNU Lesser General Public License v3 (LGPLv3)",
            "Programming Language :: C",
            "Programming Language :: Cython",
            "Programming Language :: Python",
            "Programming Language :: Python :: 3.6",
            "Programming Language :: Python :: 3.7",
            "Programming Language :: Python :: 3.8",
            "Programming Language :: Python :: 3.9",
            "Programming Language :: Python :: 3.10",
            "Programming Language :: Python :: Implementation :: CPython",
            "Programming Language :: Python :: Implementation :: PyPy",
        ],
        include_package_data=True,
        zip_safe=False,
        cmdclass={"build_ext": build_ext_compiler_check},
        **setup_kw
    )


if __name__ == "__main__":
    main()
