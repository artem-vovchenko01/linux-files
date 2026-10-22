#!/usr/bin/env python3
"""Minimal RFB probe: connect, handshake, time to first full frame."""
import socket, struct, sys, time
def rx(s, n):
    b = b''
    while len(b) < n:
        c = s.recv(n - len(b))
        if not c: raise EOFError
        b += c
    return b
def probe(port):
    t0 = time.time()
    s = socket.create_connection(('127.0.0.1', port), 5)
    s.settimeout(10)
    rx(s, 12); s.sendall(b'RFB 003.008\n')
    n = rx(s, 1)[0]; types = rx(s, n)
    if 1 not in types: raise SystemExit(f'no None auth: {list(types)}')
    s.sendall(b'\x01'); rx(s, 4)
    s.sendall(b'\x01')                      # shared
    w, h = struct.unpack('>HH', rx(s, 4)); bpp = rx(s, 16)[0]
    rx(s, struct.unpack('>I', rx(s, 4))[0])
    s.sendall(struct.pack('>BxHi', 2, 1, 0))  # Raw only
    t1 = time.time()
    s.sendall(struct.pack('>BBHHHH', 3, 0, 0, 0, w, h))
    rx(s, 4); total = 0
    nrect = struct.unpack('>xxH', b'\0\0' + b'')[0] if False else None
    hdr = rx(s, 0)
    # first byte already consumed: type(1) pad(1) nrects(2)
    return s, t0, t1, w, h, bpp
if __name__ == '__main__':
    port = int(sys.argv[1]); runs = int(sys.argv[2]) if len(sys.argv) > 2 else 5
    for i in range(runs):
        t0 = time.time()
        s = socket.create_connection(('127.0.0.1', port), 5); s.settimeout(15)
        rx(s, 12); s.sendall(b'RFB 003.008\n')
        n = rx(s, 1)[0]; rx(s, n); s.sendall(b'\x01'); rx(s, 4)
        s.sendall(b'\x01'); w, h = struct.unpack('>HH', rx(s, 4))
        bpp = rx(s, 16)[0]; rx(s, struct.unpack('>I', rx(s, 4))[0])
        s.sendall(struct.pack('>BxHi', 2, 1, 0))
        t1 = time.time()
        s.sendall(struct.pack('>BBHHHH', 3, 0, 0, 0, w, h))
        _, nr = struct.unpack('>BxH', rx(s, 4)); px = 0
        for _ in range(nr):
            x, y, rw, rh, enc = struct.unpack('>HHHHi', rx(s, 12))
            if enc == 0: rx(s, rw * rh * bpp // 8); px += rw * rh
        t2 = time.time()
        s.close()  # abrupt client drop
        print(f'run{i+1} {w}x{h} handshake={1000*(t1-t0):.0f}ms '
              f'first_frame={1000*(t2-t0):.0f}ms px={px}')
