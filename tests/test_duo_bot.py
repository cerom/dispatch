import io
import sys
import tempfile
import unittest
import urllib.error
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import duo_bot  # noqa: E402

PART = "MK1G4LL/A"


def store(number, name, city, display, quote="Today at Apple " ):
    return {
        "storeNumber": number,
        "storeName": name,
        "city": city,
        "partsAvailability": {PART: {"pickupDisplay": display, "pickupSearchQuote": f"<b>{quote}</b>"}},
    }


# Shape of Apple's pickup response (body.content.pickupMessage.stores[].partsAvailability).
SAMPLE = {"body": {"content": {"pickupMessage": {"stores": [
    store("R095", "Fifth Avenue", "New York", "available", "Available Today"),
    store("R226", "SoHo", "New York", "unavailable", "Currently unavailable"),
    store("R367", "Williamsburg", "Brooklyn", "available", "Available Today"),
]}}}}


def make_config(tmp: Path, **overrides) -> duo_bot.Config:
    base = dict(
        part=PART, product_name="iPhone Duo 512GB Star White", carrier="UNLOCKED/US",
        zip_code="10022", cities=("New York",), stores=(), buy_url="https://example.com",
        interval=180, jitter=0, ntfy_server="https://ntfy.example", ntfy_topic="t",
        state_path=tmp / "state.json",
    )
    base.update(overrides)
    return duo_bot.Config(**base)


class ParseTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())

    def test_parses_availability_and_strips_html(self):
        stores = duo_bot.parse_stores(SAMPLE, PART)
        self.assertEqual([s.available for s in stores], [True, False, True])
        self.assertEqual(stores[0].quote, "Available Today")

    def test_keeps_only_manhattan_by_default(self):
        cfg = make_config(self.tmp)
        names = [s.name for s in duo_bot.parse_stores(SAMPLE, PART) if duo_bot.in_scope(s, cfg)]
        self.assertEqual(names, ["Fifth Avenue", "SoHo"])

    def test_store_allowlist_overrides_cities(self):
        cfg = make_config(self.tmp, stores=("SoHo",))
        names = [s.name for s in duo_bot.parse_stores(SAMPLE, PART) if duo_bot.in_scope(s, cfg)]
        self.assertEqual(names, ["SoHo"])

    def test_missing_part_counts_as_unavailable(self):
        data = {"body": {"content": {"pickupMessage": {"stores": [{"storeName": "X", "city": "New York"}]}}}}
        self.assertFalse(duo_bot.parse_stores(data, PART)[0].available)

    def test_layout_change_is_reported(self):
        with self.assertRaises(duo_bot.CheckFailed):
            duo_bot.parse_stores({"body": {}}, PART)


class TransitionTests(unittest.TestCase):
    def test_alerts_only_on_change_to_in_stock(self):
        stores = duo_bot.parse_stores(SAMPLE, PART)
        self.assertEqual([s.name for s in duo_bot.newly_available({}, stores)], ["Fifth Avenue", "Williamsburg"])
        seen = {"R095": True, "R367": False}
        self.assertEqual([s.name for s in duo_bot.newly_available(seen, stores)], ["Williamsburg"])


class FetchTests(unittest.TestCase):
    def setUp(self):
        self.cfg = make_config(Path(tempfile.mkdtemp()))

    def test_541_is_reported_as_blocked(self):
        err = urllib.error.HTTPError("u", 541, "blocked", {}, io.BytesIO())
        with mock.patch("urllib.request.urlopen", side_effect=err):
            with self.assertRaisesRegex(duo_bot.CheckFailed, "541"):
                duo_bot.fetch(self.cfg)

    def test_html_page_is_reported(self):
        resp = mock.MagicMock()
        resp.__enter__.return_value.read.return_value = b"<!doctype html><title>Page Not Found</title>"
        with mock.patch("urllib.request.urlopen", return_value=resp):
            with self.assertRaisesRegex(duo_bot.CheckFailed, "web page"):
                duo_bot.fetch(self.cfg)

    def test_request_is_honestly_labelled_and_unlocked(self):
        resp = mock.MagicMock()
        resp.__enter__.return_value.read.return_value = b"{}"
        with mock.patch("urllib.request.urlopen", return_value=resp) as urlopen:
            duo_bot.fetch(self.cfg)
        req = urlopen.call_args.args[0]
        self.assertEqual(req.get_header("User-agent"), duo_bot.USER_AGENT)
        self.assertIn("cppart=UNLOCKED%2FUS", req.full_url)
        self.assertIn("parts.0=MK1G4LL%2FA", req.full_url)


class ConfigTests(unittest.TestCase):
    def test_refuses_placeholder_topic_and_clamps_interval(self):
        tmp = Path(tempfile.mkdtemp())
        path = tmp / "config.toml"
        path.write_text('[ntfy]\ntopic = "duo-bot-change-me"\n')
        with self.assertRaises(SystemExit):
            duo_bot.Config.load(path)
        path.write_text('[check]\ninterval_seconds = 5\n[ntfy]\ntopic = "abc123"\n')
        cfg = duo_bot.Config.load(path)
        self.assertEqual(cfg.interval, duo_bot.MIN_INTERVAL)
        self.assertEqual(cfg.part, PART)

    def test_example_config_parses(self):
        example = Path(__file__).resolve().parent.parent / "config.example.toml"
        tmp = Path(tempfile.mkdtemp()) / "config.toml"
        tmp.write_text(example.read_text().replace("duo-bot-change-me", "my-secret-topic"))
        cfg = duo_bot.Config.load(tmp)
        self.assertEqual((cfg.carrier, cfg.cities), ("UNLOCKED/US", ("New York",)))


if __name__ == "__main__":
    unittest.main()
