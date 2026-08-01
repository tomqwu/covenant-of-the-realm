"""Drive a complete two-player cultivation journey over Evennia's Telnet transport."""

from __future__ import annotations

import re
import socket
import time
import uuid

HOST = "127.0.0.1"
PORT = 4000
TIMEOUT = 12.0
PASSWORD = "local-e2e-password-only"
ANSI = re.compile(r"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1b\\))")


def strip_telnet(data: bytes) -> bytes:
    """Remove Telnet option negotiation while retaining ordinary UTF-8 payload bytes."""

    clean = bytearray()
    index = 0
    while index < len(data):
        if data[index] != 255:
            clean.append(data[index])
            index += 1
            continue
        if index + 1 >= len(data):
            break
        command = data[index + 1]
        if command == 255:
            clean.append(255)
            index += 2
        elif command == 250:
            end = data.find(b"\xff\xf0", index + 2)
            index = len(data) if end < 0 else end + 2
        else:
            index += 3
    return bytes(clean)


class Client:
    def __init__(self) -> None:
        self.socket = socket.create_connection((HOST, PORT), timeout=TIMEOUT)
        self.socket.settimeout(0.25)
        self.transcript = ""

    def close(self) -> None:
        self.socket.close()

    def send(self, command: str) -> None:
        self.socket.sendall(command.encode("utf-8") + b"\n")

    def expect(self, needle: str, timeout: float = TIMEOUT) -> str:
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if needle in self.transcript:
                return self.transcript
            try:
                chunk = self.socket.recv(65536)
            except TimeoutError:
                continue
            if not chunk:
                raise AssertionError(f"connection closed before {needle!r}\n{self.transcript}")
            decoded = strip_telnet(chunk).decode("utf-8", errors="replace")
            self.transcript += ANSI.sub("", decoded).replace("\r", "")
        raise AssertionError(f"timed out waiting for {needle!r}\n{self.transcript}")

    def command(self, command: str, expected: str) -> None:
        self.transcript = ""
        self.send(command)
        self.expect(expected)


def create_and_connect(client: Client, username: str) -> None:
    client.expect("connect <username>")
    client.command(f"create {username} {PASSWORD}", "Is this what you intended")
    client.command("yes", "A new account")
    client.command(f"connect {username} {PASSWORD}", f"You become {username}")


def connect_existing(client: Client, username: str) -> None:
    client.expect("connect <username>")
    client.command(f"connect {username} {PASSWORD}", f"You become {username}")


def main() -> None:
    suffix = uuid.uuid4().hex[:10]
    leader_name = f"Reed{suffix}"
    witness_name = f"Stone{suffix}"
    leader = Client()
    witness = Client()
    try:
        create_and_connect(leader, leader_name)
        create_and_connect(witness, witness_name)

        leader.command("east", "Moonleaf Terrace")
        leader.command("forage", "You gather one moonleaf herb")
        leader.command("west", "Zhahe Crossing")
        leader.command("north", "Hidden Spring")
        witness.command("north", "Hidden Spring")

        leader.command("cultivate", "progress is now 2")
        leader.command("prepare", "prepares a resonance formation")
        witness.command("witness", "both cultivators gain two qi and one insight")
        leader.command("status", "引息境一层")

        witness.command("cultivate", "enters 引息境一层")
        witness.command("status", "Lifespan: 88")

        leader.close()
        leader = Client()
        connect_existing(leader, leader_name)
        leader.command("status", "Lifespan: 88")
    finally:
        leader.close()
        witness.close()

    print("Two-player Telnet E2E passed: gather, cultivate, cooperate, advance, persist.")


if __name__ == "__main__":
    main()
