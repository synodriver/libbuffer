# -*- coding: utf-8 -*-
from time import time
from libbuffer import RingBuffer

start = time()
bt = bytearray()
for i in range(100):
    bt.extend(b"1234"*1000000)
    del bt[:4000000]
print(f"bytearray {time() - start}")

start = time()
bt = RingBuffer(5000000)
for i in range(100):
    bt.extend(b"1234"*1000000)
    bt.delleft(4000000)
print(f"RingBuffer {time() - start}")
