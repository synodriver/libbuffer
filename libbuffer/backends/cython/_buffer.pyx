# cython: language_level=3
# cython: cdivision=True
cimport cython
from cpython.long cimport PyLong_FromLong
from libc.stdint cimport uint8_t

from libbuffer.backends.cython.buffer cimport (buffer_append_right,
                                               buffer_as_string, buffer_del,
                                               buffer_get_size, buffer_new,
                                               buffer_new_from_string_and_size,
                                               buffer_pop_left, buffer_t)


@cython.freelist(8)
@cython.no_gc
@cython.final
@cython.internal
cdef class BufferIter:
    cdef:
        Buffer buffer
        Py_ssize_t index

    def __cinit__(self, Buffer buffer):
        self.buffer = buffer
        self.index = 0

    def __iter__(self):
        return self

    def __next__(self):
        cdef:
            uint8_t* ptr = buffer_as_string(self.buffer.buffer)
            uint8_t ret
        if self.index < <Py_ssize_t>buffer_get_size(self.buffer.buffer):
            ret = ptr[self.index]
            self.index+=1
            return ret
        else:
            raise StopIteration


@cython.freelist(8)
@cython.no_gc
@cython.final
cdef class Buffer:
    cdef:
        buffer_t* buffer
        Py_ssize_t view_count
        Py_ssize_t shape[1]
        Py_ssize_t strides[1]

    def __cinit__(self, const uint8_t[::1] data = None):
        if data is not None:
            self.buffer = buffer_new_from_string_and_size(<uint8_t*>&data[0], <size_t>data.shape[0])
        else:
            self.buffer = buffer_new(10)
        if self.buffer == NULL:
            raise MemoryError
        self.view_count = 0
        self.strides[0] = 1

    def __dealloc__(self):
        if self.buffer!=NULL:
            buffer_del(&self.buffer)

    cpdef inline void extend(self, const uint8_t[::1] data):
        if self.view_count>0:
            raise ValueError("can't change inner buffer while being viewed")
        if buffer_append_right(self.buffer, <uint8_t*>&data[0], <size_t>data.shape[0])==-1:
            raise MemoryError

    cpdef inline void append(self, uint8_t c):
        if self.view_count>0:
            raise ValueError("can't change inner buffer while being viewed")
        if buffer_append_right(self.buffer, &c, 1)==-1:
            raise MemoryError

    cpdef inline void popleft(self, size_t size):
        if self.view_count>0:
            raise ValueError("can't change inner buffer while being viewed")
        if buffer_pop_left(self.buffer, size)==-1:
            raise MemoryError

    def __len__(self):
        return buffer_get_size(self.buffer)

    def __iter__(self):
        return BufferIter(self)

    def __getbuffer__(self, Py_buffer* buffer, int flags):
        self.view_count+=1
        self.shape[0] = <Py_ssize_t>buffer_get_size(self.buffer)
        cdef size_t itemsize = sizeof(uint8_t)
        buffer.buf = buffer_as_string(self.buffer)
        buffer.obj = self
        buffer.len = self.shape[0]*itemsize
        buffer.readonly = 0
        buffer.itemsize = <Py_ssize_t>itemsize
        buffer.format = "B"
        buffer.ndim = 1
        buffer.shape = self.shape
        buffer.strides = self.strides
        buffer.suboffsets = NULL

    def __releasebuffer__(self, Py_buffer* buffer):
        self.view_count -= 1

    def __getitem__(self, object item):
        cdef:
            uint8_t* ptr = buffer_as_string(self.buffer)
            int i
        if isinstance(item, int):
            return ptr[item] # todo: slice?
        elif isinstance(item, slice):
            ret = Buffer()
            for i in range(item.start, item.stop, item.step):
                ret.append(ptr[i])
            return ret
        else:
            raise ValueError("invalid item")

    def __str__(self):
        return f"Buffer({bytes(self)})"

    def __repr__(self):
        return f"Buffer({bytes(self)})"
