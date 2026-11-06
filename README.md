# duo-bot

Sends a push notification to your phone when an Apple Store in Manhattan has the **iPhone Duo 512GB Star White, unlocked** (`MK1G4LL/A`) in stock for pickup.

It runs on a Raspberry Pi. Every minute (plus up to 15 s of randomness) it asks Apple for the same pickup data the **Check availability** link on apple.com shows. It alerts you only when a store goes from sold out to in stock, and tapping the alert opens the 512GB Star White unlocked page, so you can check out with Apple Pay.

## Playing fair with Apple

This uses an unofficial Apple endpoint, so Apple can block it or change it at any time. The bot labels itself honestly (`duo-bot/1.0` user agent) and never tries to look like a browser. If Apple blocks it (HTTP 541/403/429) or the response changes, the bot:

1. sends you **one** "duo-bot is blocked" alert,
2. slows down (15 min, doubling up to 2 h between tries),
3. sends "working again" if it recovers.

Apple already blocks it from cloud servers. A home internet connection may or may not work: run `check` (step 3 below) to find out.

## Setup on the Raspberry Pi

Needs Python 3.11+ (Raspberry Pi OS Bookworm or newer). No packages to install.

1. **Phone alerts.** Install the free **ntfy** app (iOS/Android) and subscribe to a topic with a long random name, e.g. `duo-bot-7f3k9q2x`. Anyone who knows the name can read your alerts, so keep it secret.
2. **Get the code and set it up:**
   ```sh
   git clone -b duo-bot https://github.com/cerom/dispatch duo-bot && cd duo-bot
   cp config.example.toml config.toml
   nano config.toml        # set topic = "your topic from step 1"
   ```
3. **Test it:**
   ```sh
   python3 duo_bot.py test-alert   # your phone should buzz
   python3 duo_bot.py check        # prints each Manhattan store as IN STOCK or sold out
   ```
   If `check` prints `BLOCKED`, Apple is refusing your connection too. Stop there: the bot can't work from that network.
4. **Run it for good** (starts on boot, restarts if it crashes):
   ```sh
   ./install.sh
   journalctl -u duo-bot -f        # watch the log
   ```
   Stop it with `sudo systemctl disable --now duo-bot`.

## Config

`config.toml` (copied from `config.example.toml`):

| Setting | Default | |
|---|---|---|
| `watch.part` | `MK1G4LL/A` | 512GB Star White. Other US model numbers: 256GB Star White `MK1E4LL/A`, 512GB Night Sky `MK1H4LL/A`, 2TB Star White `MK1Q4LL/A`. |
| `watch.carrier` | `UNLOCKED/US` | Or `ATT_IPHONEDUO`, `TMOBILE_IPHONEDUO`, `VERIZON_IPHONEDUO`. |
| `watch.zip` | `10022` | Apple returns the stores nearest this zip. |
| `watch.cities` | `["New York"]` | Apple lists Manhattan stores with city "New York", so this leaves out Brooklyn and the rest. |
| `watch.stores` | (off) | Only watch these store names, e.g. `["Fifth Avenue", "SoHo"]`. |
| `check.interval_seconds` | `60` | Minimum 60. |

## Tests

```sh
python3 -m unittest discover -s tests
```
