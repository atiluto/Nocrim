from pathlib import Path
import sys
import tempfile
import unittest

import numpy as np
from PIL import Image, ImageDraw


PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "tools"))

from alpha_cutout_tool import convert_files, parse_key_color, remove_border_background  # noqa: E402


class AlphaCutoutToolTests(unittest.TestCase):
    def test_removes_magenta_and_small_enclosed_holes_but_preserves_white(self) -> None:
        source = Image.new("RGBA", (140, 120), (255, 0, 255, 255))
        draw = ImageDraw.Draw(source)
        # Shaded white/lavender subject: this must remain opaque.
        draw.rectangle((15, 20, 60, 100), fill=(45, 38, 52, 255))
        draw.rectangle((20, 25, 55, 95), fill=(240, 235, 246, 255))
        draw.rectangle((25, 30, 35, 50), fill="white")
        # Small magenta gap surrounded by dark outline: unlike old white logic,
        # even a four-pixel gap should disappear.
        draw.rectangle((78, 18, 130, 102), fill=(40, 34, 45, 255))
        draw.rectangle((102, 59, 103, 60), fill=(255, 0, 255, 255))

        output = np.asarray(remove_border_background(source))

        self.assertEqual(int(output[0, 0, 3]), 0)
        self.assertEqual(int(output[70, 40, 3]), 255)
        self.assertEqual(tuple(output[70, 40, :3]), (240, 235, 246))
        self.assertEqual(tuple(output[35, 30]), (255, 255, 255, 255))
        self.assertEqual(int(output[60, 103, 3]), 0)
        self.assertGreaterEqual(int(output[18, 78, 3]), 200)

    def test_default_does_not_remove_white_background(self):
        source = Image.new("RGBA", (20, 20), "white")
        self.assertTrue(np.array_equal(np.asarray(source), np.asarray(remove_border_background(source))))

    def test_existing_alpha_and_no_hidden_magenta(self):
        source = Image.new("RGBA", (20, 20), (255, 0, 255, 255))
        source.putpixel((10, 10), (240, 240, 250, 91))
        source.putpixel((11, 10), (10, 20, 30, 0))
        output = np.asarray(remove_border_background(source, feather=0))
        self.assertEqual(tuple(output[10, 10]), (240, 240, 250, 91))
        self.assertEqual(tuple(output[10, 11]), (0, 0, 0, 0))
        self.assertEqual(tuple(output[0, 0]), (0, 0, 0, 0))

    def test_keep_holes_removes_only_exterior(self):
        source = Image.new("RGBA", (30, 30), "magenta")
        ImageDraw.Draw(source).rectangle((5, 5, 25, 25), fill="black")
        source.putpixel((15, 15), (255, 0, 255, 255))
        output = np.asarray(remove_border_background(source, feather=0, remove_enclosed_holes=False))
        self.assertEqual(int(output[0, 0, 3]), 0)
        self.assertEqual(int(output[15, 15, 3]), 255)

    def test_soft_edge_is_partial_and_color_recovery_reduces_magenta(self):
        source = Image.new("RGBA", (15, 15), (230, 25, 230, 255))
        raw = np.asarray(remove_border_background(source, feather=0, decontaminate=False))
        fixed = np.asarray(remove_border_background(source, feather=0, decontaminate=True))
        self.assertTrue(0 < int(fixed[5, 5, 3]) < 255)
        self.assertEqual(int(raw[5, 5, 3]), int(fixed[5, 5, 3]))
        self.assertLess(int(fixed[5, 5, 0]) - int(fixed[5, 5, 1]), int(raw[5, 5, 0]) - int(raw[5, 5, 1]))

    def test_custom_rgb_and_invalid_parameters(self):
        self.assertEqual(parse_key_color("ff00FF"), (255, 0, 255))
        green = Image.new("RGBA", (2, 2), (0, 255, 0, 255))
        self.assertEqual(remove_border_background(green, key_color="#00FF00").getpixel((0, 0))[3], 0)
        for options in ({"key_color":"not hex"}, {"hard_tolerance":80,"soft_tolerance":80}, {"feather":float("nan")}):
            with self.assertRaises(ValueError):
                remove_border_background(green, **options)

    def test_batch_unicode_names_same_name_output_and_original_protection(self):
        with tempfile.TemporaryDirectory() as raw:
            folder = Path(raw)
            source = folder / "무협 캐릭터.png"
            Image.new("RGBA", (20, 20), "magenta").save(source)
            original = source.read_bytes()
            outputs = convert_files([source], output_dir=folder / "결과", suffix="")
            self.assertEqual(outputs[0].name, source.name)
            with Image.open(outputs[0]) as image:
                self.assertEqual(image.mode, "RGBA")
                self.assertEqual(image.getpixel((0, 0))[3], 0)
            with self.assertRaises(ValueError):
                convert_files([source], suffix="", overwrite=True)
            with self.assertRaises(FileExistsError):
                convert_files([source], output_dir=folder / "결과", suffix="")
            self.assertEqual(source.read_bytes(), original)

    def test_batch_rejects_colliding_destinations_before_writes(self):
        with tempfile.TemporaryDirectory() as raw:
            folder = Path(raw)
            paths = []
            for name in ("one", "two"):
                sub = folder / name
                sub.mkdir()
                path = sub / "sprite.png"
                Image.new("RGB", (2, 2), "magenta").save(path)
                paths.append(path)
            with self.assertRaises(ValueError):
                convert_files(paths, output_dir=folder / "out")
            self.assertFalse((folder / "out").exists())


if __name__ == "__main__":
    unittest.main()
