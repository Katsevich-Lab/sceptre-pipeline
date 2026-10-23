"""CLI admission must reject ambiguous source/runtime overrides before preparation."""
import pathlib
import subprocess
import sys
import tempfile
import unittest

LAUNCHER = pathlib.Path(__file__).resolve().parents[1] / 'bin' / 'sceptre-pipeline'


class LauncherAdmission(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = pathlib.Path(self.temporary.name)
        self.data = self.root / 'data'
        self.data.mkdir()
        for name in ('input.json', 'analysis.json'):
            (self.data / name).write_text('{}\n')
        self.output = self.root / 'run'
        self.args = [sys.executable, str(LAUNCHER), '--data-root', str(self.data),
                     '--input-json', str(self.data/'input.json'),
                     '--analysis-json', str(self.data/'analysis.json'),
                     '--run-dir', str(self.output)]

    def rejects_before_output(self, extra, message):
        result = subprocess.run(self.args + extra, text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(message, result.stderr)
        self.assertFalse(self.output.exists())

    def test_mutable_image_cannot_prepare_raw_data(self):
        self.rejects_before_output(['--container-image', 'sceptre:latest'], 'immutable image digest')

    def test_explicit_input_cannot_override_prepared_project(self):
        self.rejects_before_output(['--container-image', 'sha256:'+'0'*64,
                                   '--', '--input', '/other/screen'], 'cannot be overridden')

    def test_sif_requires_actual_checksum(self):
        image = self.root/'runtime.sif'
        image.write_bytes(b'invalid image; must never be executed')
        self.rejects_before_output(['--engine', 'apptainer', '--container-image', str(image),
                                   '--container-image-sha256', '0'*64], 'SIF checksum missing or mismatched')


if __name__ == '__main__':
    unittest.main()
