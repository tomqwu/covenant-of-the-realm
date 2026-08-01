"""Ensure a clean Evennia database has the owner record required by initial setup."""

from __future__ import annotations

import os
import secrets
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "mud"))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "server.conf.settings")

import django  # noqa: E402

django.setup()

from django.contrib.auth import get_user_model  # noqa: E402


def main() -> None:
    account_model = get_user_model()
    if account_model.objects.filter(id=1).exists():
        print("Evennia bootstrap account already exists.")
        return

    username = os.environ.get("COVENANT_BOOTSTRAP_USER", "realmkeeper")
    password = os.environ.get("COVENANT_BOOTSTRAP_PASSWORD", secrets.token_urlsafe(32))
    account_model.objects.create_superuser(
        username=username,
        email="realmkeeper@localhost.invalid",
        password=password,
    )
    print("Created the local Evennia bootstrap account.")


if __name__ == "__main__":
    main()
