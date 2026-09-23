#!/usr/bin/env python3
"""Verdrahtungs-Tests der ComfyUI-Graphen (ohne Box). Aufruf: cd tool/comic && python3 -m unittest test_graphs"""
import unittest

import comfy_client as cc


def _node(graph, class_type):
    hits = [k for k, v in graph.items() if v["class_type"] == class_type]
    assert len(hits) == 1, "%s: %d Treffer" % (class_type, len(hits))
    return hits[0]


class MangaGraph(unittest.TestCase):
    def test_depth_default_wiring(self):
        g = cc.manga_graph("gate_P03.png", "core", "neg", 555, "m_P03")
        ks = g[_node(g, "KSampler")]["inputs"]
        ca = _node(g, "ControlNetApplyAdvanced")
        self.assertEqual(ks["positive"], [ca, 0])
        self.assertEqual(ks["negative"], [ca, 1])
        self.assertAlmostEqual(ks["denoise"], 0.7)
        self.assertEqual(ks["seed"], 555)
        self.assertEqual(ks["latent_image"], [_node(g, "VAEEncode"), 0])
        self.assertIn("DepthAnythingV2Preprocessor", [v["class_type"] for v in g.values()])
        self.assertNotIn("CannyEdgePreprocessor", [v["class_type"] for v in g.values()])
        apply = g[ca]["inputs"]
        self.assertAlmostEqual(apply["strength"], 0.7)
        self.assertAlmostEqual(apply["end_percent"], 0.8)
        self.assertEqual(apply["vae"], [_node(g, "VAELoader"), 0])
        lora = g[_node(g, "LoraLoaderModelOnly")]["inputs"]
        self.assertAlmostEqual(lora["strength_model"], 1.5)
        self.assertEqual(g[_node(g, "LoadImage")]["inputs"]["image"], "gate_P03.png")

    def test_canny_fallback(self):
        g = cc.manga_graph("x.png", "core", "neg", 1, "p", control="canny", strength=0.6)
        self.assertIn("CannyEdgePreprocessor", [v["class_type"] for v in g.values()])
        pre = g[_node(g, "CannyEdgePreprocessor")]["inputs"]
        self.assertEqual((pre["low_threshold"], pre["high_threshold"]), (100, 200))
        self.assertAlmostEqual(g[_node(g, "ControlNetApplyAdvanced")]["inputs"]["strength"], 0.6)

    def test_prompt_carries_content(self):
        g = cc.manga_graph("x.png", "an elderly man in his seventies", "neg", 1, "p")
        texts = [v["inputs"]["text"] for v in g.values() if v["class_type"] == "CLIPTextEncode"]
        self.assertTrue(any("elderly man" in t and "shotengai_style" in t for t in texts))
        self.assertIn("neg", texts)

    def test_unknown_control_rejected(self):
        with self.assertRaises(ValueError):
            cc.manga_graph("x.png", "c", "n", 1, "p", control="pose")


class UpscaleGraph(unittest.TestCase):
    def test_sizes_and_model(self):
        g = cc.upscale_graph("in.png", "up", 1920, 1072)
        sc = g[_node(g, "ImageScale")]["inputs"]
        self.assertEqual((sc["width"], sc["height"]), (1920, 1072))
        self.assertEqual(sc["upscale_method"], "lanczos")
        self.assertEqual(g[_node(g, "UpscaleModelLoader")]["inputs"]["model_name"], "4x-UltraSharp.pth")
        self.assertEqual(g[_node(g, "LoadImage")]["inputs"]["image"], "in.png")


class T2IGraph(unittest.TestCase):
    def test_custom_size(self):
        g = cc.t2i_graph("core", "neg", 701, "p", 0.3, 928, 1664)
        lat = g[_node(g, "EmptySD3LatentImage")]["inputs"]
        self.assertEqual((lat["width"], lat["height"]), (928, 1664))


if __name__ == "__main__":
    unittest.main()
