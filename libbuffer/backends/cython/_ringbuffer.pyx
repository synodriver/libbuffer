# cython: language_level=3
# cython: cdivision=True
cimport cython
from cpython.bytes cimport PyBytes_AS_STRING, PyBytes_FromStringAndSize
from libc.stdint cimport uint8_t

from libbuffer.backends.cython.ringbuffer cimport (ringbuffer_append,
                                                   ringbuffer_copy_into,
                                                   ringbuffer_del,
                                                   ringbuffer_get_size,
                                                   ringbuffer_new,
                                                   ringbuffer_pop,
                                                   ringbuffer_t)


cdef inline str buf_to_str(RingBuffer buf):
    return f"RingBuffer({buf.to_bytes()})"

@cython.final
@cython.no_gc
@cython.freelist(8)
cdef class RingBuffer:
    cdef ringbuffer_t* buffer

    def __cinit__(self, size_t cap):
        self.buffer = ringbuffer_new(cap)
        if self.buffer == NULL:
            raise MemoryError

    def __dealloc__(self):
        if self.buffer != NULL:
            ringbuffer_del(&self.buffer)

    @property
    def cap(self):
        return self.buffer.cap

    @property
    def head(self):
        return self.buffer.head

    @property
    def tail(self):
        return self.buffer.tail

    cpdef inline object extend(self, const uint8_t[::1] data):
        if ringbuffer_append(self.buffer, <uint8_t*>&data[0], <size_t>data.shape[0]) == -1:
            raise ValueError("data is too long")

    cpdef inline bytes popleft(self, size_t size):
        cdef bytes ret = PyBytes_FromStringAndSize(NULL, <Py_ssize_t>size)
        if not ret:
            raise MemoryError
        cdef char* ptr = PyBytes_AS_STRING(ret)
        if ringbuffer_copy_into(self.buffer, size, <uint8_t*>ptr) == -1:
            raise ValueError("size is too long")
        ringbuffer_pop(self.buffer, size)
        return ret

    cpdef inline object delleft(self, size_t size):
        if ringbuffer_pop(self.buffer, size) == -1:
            raise ValueError("size is too long")

    cpdef inline bytes to_bytes(self):
        cdef size_t size = ringbuffer_get_size(self.buffer)
        cdef bytes ret = PyBytes_FromStringAndSize(NULL, <Py_ssize_t> size)
        if not ret:
            raise MemoryError
        cdef char * ptr = PyBytes_AS_STRING(ret)
        ringbuffer_copy_into(self.buffer, size, <uint8_t *> ptr)
        return ret

    def __len__(self):
        return ringbuffer_get_size(self.buffer)

    def __iter__(self):
        return iter(self.to_bytes())

    def __str__(self):
        return buf_to_str(self)

    def __repr__(self):
        return buf_to_str(self)