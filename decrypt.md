# Akira Decryption Process Documentation

## Command Syntax
```bash
./decrypt <input_file> <T1> <T2> <T3> <T4>
```

Where:
- `input_file`: The encrypted .akira file to decrypt
- `T1`: First timestamp (from bruteforce match)
- `T2`: Second timestamp (from bruteforce match)
- `T3`: Start timestamp
- `T4`: End timestamp

## Decryption Process Breakdown

### 1. Key Generation Phase

#### ChaCha8 Key Generation
```
T1 = [timestamp1]
chacha8_k8: 32-byte key generated from T1
```
- Uses T1 to generate a 32-byte ChaCha8 key
- Key is displayed in hexadecimal format

#### ChaCha8 Nonce Generation
```
T2 = [timestamp2]
chacha8_nonce: 16-byte nonce generated from T2
```
- Uses T2 to generate a 16-byte nonce
- Nonce is displayed in hexadecimal format

#### KCipher2 Key Generation
```
T3 = [start_timestamp]
kcipher2_key: 16-byte key generated from T3
```
- Uses T3 to generate a 16-byte KCipher2 key
- Key is displayed in hexadecimal format

#### KCipher2 IV Generation
```
T4 = [end_timestamp]
kcipher2_iv: 16-byte initialization vector generated from T4
```
- Uses T4 to generate a 16-byte initialization vector
- IV is displayed in hexadecimal format

### 2. Memory Allocation
```
Allocating: 262144 bytes
```
- Allocates buffer for decryption operations
- Fixed size of 256KB (262,144 bytes)

### 3. Initial KCipher2 Setup
```
IK[4] = 08a71226
IK[7] = e4d7ec16
IK[8] = 241cb2fd
```
- Initializes KCipher2 internal state values
- These values are derived from the key material

### 4. Decryption Process

The decryption alternates between KCipher2 and ChaCha8:

#### KCipher2 Blocks
```
Decrypting with kcipher2: 65535 at offs 0
kcipher size: 65535
requesting 1024 blocks
```
- Processes 65,535-byte blocks
- Shows offset position in file
- Indicates number of blocks requested

#### ChaCha8 Blocks
```
Decrypting with chacha8 65535 offs=65535
Decrypting with chacha8 65535 offs=131070
Decrypting with chacha8 65535 offs=196605
```
- Processes 65,535-byte blocks
- Shows offset position in file
- Multiple blocks processed sequentially

#### Remaining Data
```
remaining: [value]
```
- Shows remaining bytes to process
- Value decreases as decryption progresses

### 5. Completion
```
Decryption done
```
- Indicates successful decryption
- Original file is restored

## Example Usage

### Decrypting ones.vmdk.akira
```bash
./decrypt tests/ones.vmdk.akira 1741841294360506186 1741841294374553498 1741841294358440000 1741841294378440000
```

### Decrypting zeroes.vmdk.akira
```bash
./decrypt tests/zeroes.vmdk.akira 1741841294374553498 1741841294360506186 1741841294358440000 1741841294378440000
```

Note: The decryption process uses a hybrid approach combining both ChaCha8 and KCipher2 algorithms, processing the file in blocks of 65,535 bytes. The process alternates between the two encryption methods to ensure complete and secure decryption of the file.
