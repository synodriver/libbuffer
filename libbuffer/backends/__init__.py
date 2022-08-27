"""
Copyright (c) 2008-2021 synodriver <synodriver@gmail.com>
"""
import os
import platform

impl = platform.python_implementation()


def _should_use_cffi() -> bool:
    ev = os.getenv("BZ3_USE_CFFI")
    if ev is not None:
        return True
    if impl == "CPython":
        return False
    else:
        return True


if not _should_use_cffi():
    from libbuffer.backends.cython import Buffer, RingBuffer
else:
    from libbuffer.backends.cffi import Buffer, RingBuffer
