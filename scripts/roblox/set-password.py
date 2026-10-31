#!/usr/bin/env python3
"""Sets the password of the in-game password gate (src/server/AccessGate.server.luau), kept in the "Access" DataStore of
the live experience, so it never appears in the code, the repo or a log.

Usage: scripts/roblox/set-password.py           asks for the new password (typed twice, not shown)
       scripts/roblox/set-password.py --clear   removes it: the game is open to everyone who can join
       scripts/roblox/set-password.py --check   says whether a password is set (never prints it)
Live servers pick up a change within a minute. Uses the Open Cloud key in scripts/roblox/.env (Luau execution)."""
import getpass
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cloud  # noqa: E402

STORE, KEY = "Access", "password"  # Shared.AccessGate StoreName / StoreKey


def luau_bytes(text):
    """The text as a Luau expression of byte values, so no quoting or escaping can break the script."""
    return "string.char(" + ",".join(str(b) for b in text.encode("utf-8")) + ")"


def main(argv):
    key, uni, place = cloud.load_env()
    store = f'game:GetService("DataStoreService"):GetDataStore("{STORE}")'
    if "--check" in argv:
        src = f'local v = {store}:GetAsync("{KEY}")\nreturn if type(v) == "string" and v ~= "" then "set" else "not set"'
        print("password:", cloud.run_luau(key, uni, place, None, src=src, quiet=True))
        return 0
    if "--clear" in argv:
        src = f'{store}:RemoveAsync("{KEY}")\nreturn "cleared"'
    else:
        first = getpass.getpass("New password: ").strip()
        if not first or len(first) > 64:
            sys.exit("The password must be 1 to 64 characters.")
        if getpass.getpass("Again: ").strip() != first:
            sys.exit("The two entries differ; nothing changed.")
        src = f'{store}:SetAsync("{KEY}", {luau_bytes(first)})\nreturn "saved"'
    result = cloud.run_luau(key, uni, place, None, src=src, quiet=True)
    print(result or "failed (no result from the Luau execution task)")
    return 0 if result else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
