#!/usr/bin/env python3
"""The classic PlantUML URL encoding (raw deflate + custom base64) of a file: prints the {enc} of GET {base}/svg/{enc}."""
import sys
import zlib

ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"


def encode(data: bytes) -> str:
    packer = zlib.compressobj(9, zlib.DEFLATED, -15)
    raw = packer.compress(data) + packer.flush()
    raw += b"\0" * (-len(raw) % 3)
    out = []
    for i in range(0, len(raw), 3):
        b1, b2, b3 = raw[i], raw[i + 1], raw[i + 2]
        out.append(ALPHABET[b1 >> 2])
        out.append(ALPHABET[((b1 & 3) << 4) | (b2 >> 4)])
        out.append(ALPHABET[((b2 & 15) << 2) | (b3 >> 6)])
        out.append(ALPHABET[b3 & 63])
    return "".join(out)


if __name__ == "__main__":
    with open(sys.argv[1], "rb") as handle:
        sys.stdout.write(encode(handle.read()))
