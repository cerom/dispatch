#!/usr/bin/env python3
"""duo-bot: push an alert when a Manhattan Apple Store has an iPhone in stock for pickup.

Polls Apple's in-store pickup availability (the same data behind "Check availability"
on apple.com) with a plain, honestly labelled request. If Apple blocks or changes the
response, the bot backs off, tells you once, and never tries to disguise itself.

Commands:
  run         check forever and send alerts (what the systemd service runs)
  check       one check, print every store, send nothing
  test-alert  send a test notification to your phone

Standard library only. Needs Python 3.11+ (Raspberry Pi OS Bookworm or newer).
"""
from __future__ import annotations

import argparse
import json
import logging
import random
import re
import sys
import time
import tomllib
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path

API_URL = "https://www.apple.com/shop/fulfillment-messages"
USER_AGENT = "duo-bot/1.0 (personal stock alert)"
BLOCKED_STATUSES = {403, 429, 503, 541}  # 541 is Apple's "automated traffic" response
MIN_INTERVAL = 60
MIN_BACKOFF, MAX_BACKOFF = 15 * 60, 2 * 60 * 60

log = logging.getLogger("duo-bot")


class CheckFailed(Exception):
    """Apple blocked the request or answered with something we can't read."""


@dataclass(frozen=True)
class Config:
    part: str
    product_name: str
    carrier: str
    zip_code: str
    cities: tuple[str, ...]
    stores: tuple[str, ...]
    buy_url: str
    interval: float
    jitter: float
    ntfy_server: str
    ntfy_topic: str
    state_path: Path

    @classmethod
    def load(cls, path: Path) -> Config:
        with path.open("rb") as f:
            raw = tomllib.load(f)
        watch, check, ntfy = raw.get("watch", {}), raw.get("check", {}), raw.get("ntfy", {})
        topic = ntfy.get("topic", "")
        if not topic or "change-me" in topic:
            raise SystemExit(f"Set a private ntfy topic in {path} (see README).")
        return cls(
            part=watch.get("part", "MK1G4LL/A"),
            product_name=watch.get("name", "iPhone Duo 512GB Star White"),
            carrier=watch.get("carrier", "UNLOCKED/US"),
            zip_code=str(watch.get("zip", "10022")),
            cities=tuple(watch.get("cities", ["New York"])),
            stores=tuple(watch.get("stores", [])),
            buy_url=watch.get("buy_url", "https://www.apple.com/shop/buy-iphone/iphone-duo"),
            interval=max(float(check.get("interval_seconds", 180)), MIN_INTERVAL),
            jitter=float(check.get("jitter_seconds", 60)),
            ntfy_server=ntfy.get("server", "https://ntfy.sh").rstrip("/"),
            ntfy_topic=topic,
            state_path=path.with_name("state.json"),
        )


@dataclass(frozen=True)
class Store:
    number: str
    name: str
    city: str
    available: bool
    quote: str


# --- Apple -------------------------------------------------------------------------------

def fetch(cfg: Config) -> dict:
    params = {
        "fae": "true",
        "pl": "true",
        "mts.0": "regular",
        "cppart": cfg.carrier,
        "parts.0": cfg.part,
        "location": cfg.zip_code,
    }
    url = f"{API_URL}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            body = resp.read()
    except urllib.error.HTTPError as e:
        if e.code in BLOCKED_STATUSES:
            raise CheckFailed(f"Apple blocked the request (HTTP {e.code})") from e
        raise CheckFailed(f"Apple returned HTTP {e.code}") from e
    try:
        return json.loads(body)
    except json.JSONDecodeError as e:
        raise CheckFailed("Apple returned a web page instead of stock data") from e


def _clean(text: str) -> str:
    return re.sub(r"<[^>]+>", "", text or "").strip()


def parse_stores(data: dict, part: str) -> list[Store]:
    try:
        stores = data["body"]["content"]["pickupMessage"]["stores"]
    except (KeyError, TypeError) as e:
        raise CheckFailed("Apple's response layout changed (no store list)") from e
    result = []
    for s in stores:
        avail = (s.get("partsAvailability") or {}).get(part) or {}
        result.append(Store(
            number=str(s.get("storeNumber", "")),
            name=s.get("storeName", "?"),
            city=s.get("city", ""),
            available=avail.get("pickupDisplay") == "available",
            quote=_clean(avail.get("pickupSearchQuote") or avail.get("storePickupQuote") or ""),
        ))
    return result


def in_scope(store: Store, cfg: Config) -> bool:
    if cfg.stores:
        return store.name in cfg.stores
    return store.city in cfg.cities  # Apple lists Manhattan stores with city "New York"


def newly_available(previous: dict[str, bool], stores: list[Store]) -> list[Store]:
    return [s for s in stores if s.available and not previous.get(s.number, False)]


# --- Alerts & state ----------------------------------------------------------------------

def notify(cfg: Config, title: str, message: str, *, priority: str = "default",
           tags: str = "", click: str | None = None) -> None:
    headers = {"Title": title, "Priority": priority}
    if tags:
        headers["Tags"] = tags
    if click:
        headers["Click"] = click
    req = urllib.request.Request(
        f"{cfg.ntfy_server}/{cfg.ntfy_topic}", data=message.encode(), headers=headers, method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=15):
            pass
    except (urllib.error.URLError, TimeoutError) as e:
        log.error("could not send alert: %s", e)


def load_state(path: Path) -> dict[str, bool]:
    try:
        return json.loads(path.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def save_state(path: Path, stores: list[Store]) -> None:
    path.write_text(json.dumps({s.number: s.available for s in stores}, indent=2))


# --- Commands ----------------------------------------------------------------------------

def check_once(cfg: Config) -> list[Store]:
    return [s for s in parse_stores(fetch(cfg), cfg.part) if in_scope(s, cfg)]


def cmd_check(cfg: Config) -> int:
    try:
        stores = check_once(cfg)
    except CheckFailed as e:
        print(f"BLOCKED: {e}")
        return 2
    if not stores:
        print(f"No stores matched {cfg.stores or cfg.cities} near {cfg.zip_code}.")
        return 1
    for s in stores:
        print(f"{'IN STOCK ' if s.available else 'sold out '} {s.name:<22} {s.quote}")
    return 0


def cmd_run(cfg: Config) -> int:
    state = load_state(cfg.state_path)
    backoff = 0.0
    failing = False
    log.info("watching %s (%s) near %s every ~%ds",
             cfg.product_name, cfg.carrier, cfg.zip_code, cfg.interval)
    while True:
        try:
            stores = check_once(cfg)
            for s in newly_available(state, stores):
                log.info("IN STOCK at %s", s.name)
                notify(cfg, f"In stock at Apple {s.name}",
                       f"{cfg.product_name} is available for pickup at {s.name}. {s.quote}",
                       priority="urgent", tags="iphone,rotating_light", click=cfg.buy_url)
            if failing:
                notify(cfg, "duo-bot is working again", "Stock checks are back to normal.", tags="white_check_mark")
                failing = False
            state = {s.number: s.available for s in stores}
            save_state(cfg.state_path, stores)
            backoff = 0
            in_stock = [s.name for s in stores if s.available]
            log.info("checked %d stores; in stock: %s", len(stores), ", ".join(in_stock) or "none")
            delay = cfg.interval + random.uniform(-cfg.jitter, cfg.jitter)
        except CheckFailed as e:
            backoff = min(max(backoff * 2, MIN_BACKOFF), MAX_BACKOFF)
            log.warning("%s; retrying in %d min", e, backoff // 60)
            if not failing:
                notify(cfg, "duo-bot is blocked",
                       f"{e}. It will keep retrying slowly (every {int(backoff // 60)}+ min) and won't try to get around it.",
                       tags="warning")
                failing = True
            delay = backoff
        except (urllib.error.URLError, TimeoutError, OSError) as e:
            log.warning("network problem: %s", e)
            delay = cfg.interval
        time.sleep(max(delay, MIN_INTERVAL))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=["run", "check", "test-alert"])
    parser.add_argument("--config", type=Path, default=Path(__file__).with_name("config.toml"))
    args = parser.parse_args(argv)
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

    cfg = Config.load(args.config)
    if args.command == "check":
        return cmd_check(cfg)
    if args.command == "test-alert":
        notify(cfg, "duo-bot test", f"Alerts work. Watching {cfg.product_name}.",
               tags="iphone", click=cfg.buy_url)
        print("Sent. Check your phone.")
        return 0
    return cmd_run(cfg)


if __name__ == "__main__":
    sys.exit(main())
