"""Type argv[1] into the VM through QEMU's HMP `sendkey`, which needs no guest agent."""

import socket
import sys
import time

PLAIN = {
    " ": "spc", "\n": "ret", "\t": "tab", "-": "minus", "=": "equal",
    "[": "bracket_left", "]": "bracket_right", "\\": "backslash",
    ";": "semicolon", "'": "apostrophe", ",": "comma", ".": "dot",
    "/": "slash", "`": "grave_accent",
}
# US layout; QEMU's VNC/keymap is en-us too.
SHIFTED = {
    "!": "1", "@": "2", "#": "3", "$": "4", "%": "5", "^": "6", "&": "7",
    "*": "8", "(": "9", ")": "0", "_": "minus", "+": "equal",
    "{": "bracket_left", "}": "bracket_right", "|": "backslash",
    ":": "semicolon", '"': "apostrophe", "<": "comma", ">": "dot",
    "?": "slash", "~": "grave_accent",
}


def qcode(c):
    if c.isdigit() or "a" <= c <= "z":
        return c
    if "A" <= c <= "Z":
        return "shift-" + c.lower()
    if c in PLAIN:
        return PLAIN[c]
    if c in SHIFTED:
        return "shift-" + SHIFTED[c]
    raise SystemExit(f"macos-vm type: cannot type {c!r}")


def main():
    keys = [qcode(c) for c in sys.argv[1]]
    s = socket.socket(socket.AF_UNIX)
    s.connect("/run/shm/monitor.sock")
    time.sleep(0.3)
    s.recv(65536)
    for k in keys:
        s.sendall(f"sendkey {k}\n".encode())
        # Faster than this drops or reorders keys in the guest.
        time.sleep(0.06)
    time.sleep(0.3)


if __name__ == "__main__":
    main()
