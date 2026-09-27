"""Where the player's Factorio is installed: the one setting read by every tool and test that needs
vanilla's own graphics or locale files. Override with the FACTORIO_DIR environment variable if the
game moves; the default below is this machine's Steam install."""
import os

FACTORIO_DIR = os.environ.get("FACTORIO_DIR", r"C:\Program Files (x86)\Steam\steamapps\common\Factorio")
GAME = os.path.join(FACTORIO_DIR, "data")  # base/, core/, locale/, graphics/
