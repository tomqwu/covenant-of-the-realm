r"""
Evennia settings file.

The available options are found in the default settings file found
here:

https://www.evennia.com/docs/latest/Setup/Settings-Default.html

Remember:

Don't copy more from the default file than you actually intend to
change; this will make sure that you don't overload upstream updates
unnecessarily.

When changing a setting requiring a file system path (like
path/to/actual/file.py), use GAME_DIR and EVENNIA_DIR to reference
your game folder and the Evennia library folders respectively. Python
paths (path.to.module) should be given relative to the game's root
folder (typeclasses.foo) whereas paths within the Evennia library
needs to be given explicitly (evennia.foo).

If you want to share your game dir, including its settings, you can
put secret game- or server-specific settings in secret_settings.py.

"""

import contextlib
import os

# Use the defaults from Evennia unless explicitly overridden
from evennia.settings_default import *

######################################################################
# Evennia base server config
######################################################################

# This is the name of your game. Make it catchy!
SERVERNAME = "山河有契"
GAME_SLOGAN = "一方持续生长的多人修仙世界"

# The first slice uses the durable Evennia account/character model. Guest accounts
# would be deleted on disconnect and are therefore intentionally disabled.
GUEST_ENABLED = False
MAX_NR_CHARACTERS = 1

# Preserve Evennia's production-safe default while allowing repeatable loopback E2E
# account creation in an explicitly marked test process.
CREATION_THROTTLE_LIMIT = int(os.environ.get("COVENANT_CREATION_THROTTLE_LIMIT", "2"))

# Keep deterministic game state in the server. The built-in WebSocket web client and
# Telnet interface are both enabled by Evennia's defaults.
TIME_ZONE = "UTC"


######################################################################
# Settings given in secret_settings.py override those in this file.
######################################################################
with contextlib.suppress(ImportError):
    from server.conf.secret_settings import *
