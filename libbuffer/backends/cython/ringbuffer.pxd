# cython: language_level=3
# cython: cdivision=True
from libc.stdint cimport uint8_t


cdef extern from "ringbuffer.h" nogil:
    ctypedef struct ringbuffer_t:
        uint8_t *data
        size_t cap
        size_t head
        size_t tail

    ringbuffer_t *ringbuffer_new(size_t cap)

    void ringbuffer_del(ringbuffer_t **self)
    size_t ringbuffer_get_size(ringbuffer_t *self)
    uint8_t *ringbuffer_get_data(ringbuffer_t *self)
    int ringbuffer_copy_into(ringbuffer_t *self, size_t len, uint8_t *dst)
    int ringbuffer_append(ringbuffer_t *self, uint8_t *str, size_t len)
    int ringbuffer_pop(ringbuffer_t *self, size_t len)