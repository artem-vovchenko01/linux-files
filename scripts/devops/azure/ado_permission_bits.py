#!/usr/bin/env python
bits = int(input("Specify INT value that represents set of perm bits from AccessControlEntry: "))
print("Binary repr:")
bin = str(bin(bits))
print(bin)
print("====================")
print("BITS SET")
for i in range(len(bin) - 2):
    bit = bin[2+i]
    if bit == "1":
        pow = len(bin) - 2 - 1 - i
        print(2 ** pow)

print("====================")
print("BITS NOT SET")
for i in range(len(bin) - 2):
    bit = bin[2+i]
    if bit == "0":
        pow = len(bin) - 2 - 1 - i
        print(2 ** pow)
