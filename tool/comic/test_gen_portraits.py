#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_gen_portraits -v"""
import os
import shutil
import tempfile
import unittest

import gen_portraits_dart as gp


class GenPortraits(unittest.TestCase):
    def setUp(self):
        self.d = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.d)
        self.dir = os.path.join(self.d, "assets")
        os.makedirs(self.dir)
        self.out = os.path.join(self.d, "lib", "x.g.dart")

    def touch(self, *names):
        for n in names:
            open(os.path.join(self.dir, n), "wb").close()

    def test_gen_from_dir(self):
        self.touch("wirtin_fragend_1_quer.jpg", "wirtin_fragend_2_quer.jpg", "wirtin_fragend_1_hoch.jpg")
        src = gp.main(self.dir, self.out)
        self.assertIn("'wirtin_fragend': {'hoch': [1], 'quer': [1, 2]}", src)
        with open(self.out, encoding="utf-8") as f:
            self.assertEqual(f.read(), src)
        self.assertIn("const Map<String, Map<String, List<int>>> cafePortraitFiles = {", src)

    def test_gen_sorted_keys_and_numbers(self):
        self.touch("wirtin_fragend_5_quer.jpg",
                   "wirtin_fragend_2_quer.jpg", "schulkind_abwinkend_1_hoch.jpg")
        src = gp.main(self.dir, self.out)
        self.assertLess(src.index("'schulkind_abwinkend'"), src.index("'wirtin_fragend'"))
        self.assertIn("[2, 5]", src)

    def test_gen_empty_dir(self):
        self.assertIn("cafePortraitFiles = {};", gp.main(self.dir, self.out))

    def test_gen_ignores_gitkeep(self):
        self.touch(".gitkeep")
        self.assertIn("cafePortraitFiles = {};", gp.main(self.dir, self.out))

    def test_gen_rejects_foreign_file(self):
        self.touch("wirtin_fragend_1_quer.png")
        with self.assertRaisesRegex(SystemExit, "wirtin_fragend_1_quer.png"):
            gp.main(self.dir, self.out)

    def test_gen_rejects_bad_name(self):
        self.touch("wirtin_froh_1_quer.jpg")
        with self.assertRaisesRegex(SystemExit, "wirtin_froh_1_quer.jpg"):
            gp.main(self.dir, self.out)


if __name__ == "__main__":
    unittest.main()
