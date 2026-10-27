"""PRINCE golden model (Borghoff et al., ASIACRYPT 2012, ePrint 2012/529).

Conventions (must match RTL):
  * 64-bit state, nibble 0 = most-significant nibble (bits 63..60).
  * Within a nibble, bit 0 = most-significant bit.
  * M' matrix row/col index 0 = state bit 63 (MSB).
"""
import random, sys

S    = [0xB,0xF,0x3,0x2,0xA,0xC,0x9,0x1,0x6,0x7,0x8,0x0,0xE,0x5,0xD,0x4]
SINV = [S.index(i) for i in range(16)]
SR   = [0,5,10,15,4,9,14,3,8,13,2,7,12,1,6,11]   # out nibble i <- in nibble SR[i]
RC = [0x0000000000000000, 0x13198a2e03707344, 0xa4093822299f31d0,
      0x082efa98ec4e6c89, 0x452821e638d01377, 0xbe5466cf34e90c6c,
      0x7ef84f78fd955cb1, 0x85840851f1ac43aa, 0xc882d32f25323c54,
      0x64a51195e0e3610d, 0xd3b5a399ca0c2399, 0xc0ac29b7c97c50dd]
ALPHA = RC[11]
MASK = (1 << 64) - 1

def nib(x, i):      return (x >> (60 - 4*i)) & 0xF
def from_nibs(ns):
    v = 0
    for n in ns: v = (v << 4) | n
    return v

def s_layer(x, inv=False):
    t = SINV if inv else S
    return from_nibs([t[nib(x, i)] for i in range(16)])

def sr(x, inv=False):
    ns = [nib(x, i) for i in range(16)]
    if not inv:
        return from_nibs([ns[SR[i]] for i in range(16)])
    out = [0]*16
    for i in range(16): out[SR[i]] = ns[i]
    return from_nibs(out)

def bit(x, r):      return (x >> (63 - r)) & 1          # r = 0 is MSB

def mprime(x):
    """out(chunk b, nibble j, bit t) = XOR_k in(b, k, t) for (j+k+off)%4 != t."""
    out = 0
    for b in range(4):
        off = 0 if b in (0, 3) else 1                   # M^(0) / M^(1)
        for j in range(4):
            for t in range(4):
                v = 0
                for k in range(4):
                    if (j + k + off) % 4 != t:
                        v ^= bit(x, 16*b + 4*k + t)
                out |= v << (63 - (16*b + 4*j + t))
    return out

def m_fwd(x):  return sr(mprime(x))
def m_inv(x):  return mprime(sr(x, inv=True))

def core(x, k1):
    x ^= k1 ^ RC[0]
    for i in range(1, 6):  x = m_fwd(s_layer(x)) ^ RC[i] ^ k1
    x = s_layer(mprime(s_layer(x)), inv=True)
    for i in range(6, 11): x = s_layer(m_inv(x ^ k1 ^ RC[i]), inv=True)
    return x ^ k1 ^ RC[11]

def k0_prime(k0):   return ((k0 >> 1) | ((k0 & 1) << 63)) ^ (k0 >> 63)

def prince(x, k0, k1, decrypt=False):
    kp = k0_prime(k0)
    wa, wb, kc = (kp, k0, k1 ^ ALPHA) if decrypt else (k0, kp, k1)
    return core(x ^ wa, kc) ^ wb

# Appendix A test vectors: (plaintext, k0, k1, ciphertext)
KAT = [(0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x818665aa0d02dfda),
       (0xffffffffffffffff, 0x0000000000000000, 0x0000000000000000, 0x604ae6ca03c20ada),
       (0x0000000000000000, 0xffffffffffffffff, 0x0000000000000000, 0x9fb51935fc3df524),
       (0x0000000000000000, 0x0000000000000000, 0xffffffffffffffff, 0x78a54cbe737bb7ef),
       (0x0123456789abcdef, 0x0000000000000000, 0xfedcba9876543210, 0xae25ad3ca8fa9ccf)]

if __name__ == "__main__":
    ok = True
    for p, k0, k1, c in KAT:
        e, d = prince(p, k0, k1), prince(c, k0, k1, decrypt=True)
        ok &= (e == c and d == p)
        print(f"pt={p:016x} k0={k0:016x} k1={k1:016x} -> {e:016x} "
              f"{'OK' if e == c else 'FAIL'} | dec {'OK' if d == p else 'FAIL'}")
    rng = random.Random(1)
    for _ in range(2000):
        x = rng.getrandbits(64)
        ok &= mprime(mprime(x)) == x and m_inv(m_fwd(x)) == x
    print("M' involution and M^-1(M(x)) = x on 2000 random states:", ok)
    # usage: python model/prince_ref.py sim/vectors_rand.mem 256
    # extra regression vectors for the RTL testbench (generated, NOT from the paper)
    if len(sys.argv) > 1:
        with open(sys.argv[1], "w") as f:
            for _ in range(int(sys.argv[2]) if len(sys.argv) > 2 else 256):
                p, k0, k1 = (rng.getrandbits(64) for _ in range(3))
                f.write(f"{p:016x}{k0:016x}{k1:016x}{prince(p, k0, k1):016x}\n")
    sys.exit(0 if ok else 1)
