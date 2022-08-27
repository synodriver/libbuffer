# -*- coding: utf-8 -*-
from unittest import TestCase

from libbuffer import RingBuffer

class TestAll(TestCase):
    def setUp(self) -> None:
        self.buf = RingBuffer(20)

    def tearDown(self) -> None:
        pass

    def test_append(self):
        self.assertEqual(len(self.buf), 0)
        self.buf.extend(b"1"*10)
        self.assertEqual(len(self.buf), 10)
        with self.assertRaises(ValueError):
            self.buf.extend(b"1"*10)
        self.buf.extend(b"1"*9)
        self.assertEqual(len(self.buf), 19)
        self.assertEqual(self.buf.to_bytes(), b"1" * 19)
        self.assertEqual(self.buf.popleft(19), b"1"*19)

        for i in range(100):
            self.buf.extend(b"123456")
            self.assertEqual(self.buf.popleft(6), b"123456")
            self.assertEqual(len(self.buf), 0)