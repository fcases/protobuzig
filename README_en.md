# ProtobuZig

(read the Spanish version in README_es.md)
(read the Esperanto version in README.md)

ProtobuZig is a compiler from Google Protocol Buffers to **Zig 0.15.2**. It
does not need `protoc` installed: it uses its own parser ([mecha](https://github.com/Hejsil/mecha))
and builds its own AST. It is also not only for Zig: C is planned (still in
development), and in the future Vala, Go and maybe Python.

It is a personal tool, built to learn and for k6bus (see below); it does not
pretend to be another `protoc`.

---

## 1. Introduction

What you get: you write a `.proto`, you run `protobuzig`, and it gives you Zig
code for your messages: serialization (protobuf binary, Base64, Protobuf
Text, ZON, JSON), deserialization, text representations and a safe API.

### Limitations (honest ones)

- **Proto2 only**. `proto3` is detected and you get a clear error.
- It does not understand **extensions / extend** (error with line number).
- Only **one level** of nested messages/enums, and references to nested types
  do not resolve (error "type not defined"). Level 2+ is deliberately out of
  scope.
- It is not a **protoc plugin**.
- One `.proto` per run (although `--ws` gives you a full workspace).
- The grammar is permissive: unrecognized lines do not fail, they **warn**
  (and the final validation catches undefined types).

### Future (dreams)

- More binary encodings: **CDR**, **ASN.1-BER**, **ASN.1-DER**.
- Parse **OMG IDL** instead of protobuf (OMG-DDS and CORBA world).
- Port to **Zig 0.16** or later.
- Versions for **Windows** and **BSD**.

---

## 2. Usage

First get and build the tool (needs Zig 0.15.2):

```sh
git clone https://github.com/fcases/protobuzig.git
cd protobuzig
zig build          # creates zig-out/bin/protobuzig
export PATH="$PWD/zig-out/bin:$PATH"   # optional: to use just 'protobuzig'
```

The examples below assume `protobuzig` is on your PATH (or write
`zig-out/bin/protobuzig`). After building, the binary lives in `zig-out/bin/`.

### 2.1. Command line

Options:

| Option | Description |
|---|---|
| `file.proto` | the `.proto` file (positional, one per run) |
| `--proto_dir <dir>` | where to look for the `.proto` (default `.`) |
| `--output_dir <dir>` | where to write the generated `.zig` (default `.`) |
| `--ws <dir>` | creates a self-contained workspace at `<dir>` (ignores `--output_dir`) |
| `--verbose, -v` | parser traces |
| `--help, -h` | help |

Examples:

```sh
# Proto only: generates Msg.zig + Msg_api.zig in the current directory
protobuzig Msg.proto

# With separate directories
protobuzig --proto_dir protos/k6bus --output_dir generated/core Msg.proto

# Workspace: protos/, src/main.zig + tests.zig, src/runtime/, build.zig,
# .vscode (tasks/settings/launch) and .gitignore
protobuzig --ws miws --proto_dir internaltests/protos Ciudad.proto
```

### 2.2. Output files

- **`Xxxx.zig`** — the "raw" generated code: types + serialization/
  deserialization + text formats. It is the internal layer: normally you do
  not touch it.
- **`Xxxx_api.zig`** — the **safe API**: get/set/has/clear/append/At/Count,
  oneofs, clone, formats. Recommended: safer and easier, and its names are in
  English. (The raw layer, with functions and comments in Esperanto, only for
  those initiated in that language 😉.)
- **`encdec.zig`** — serialization support (EncodeBuffer/DecodeBuffer). The
  generated code imports it; the workspace installs it by itself.
- With `--ws` also: **`build.zig`** (exe + check/run/test steps), the
  **`.vscode`** files (tasks/settings/launch) and **`.gitignore`**.

### 2.3. Complete examples

- `examples/prueba1` — a test `--ws` workspace (Ciudad.proto):
  `src/main.zig` with an example (create a message, write to a file, read it
  back, switch format) and `src/tests.zig` with a round-trip test.
- `internaltests/` — the internal test suite: `testo2.zig`, `testo3.zig`
  (round-trips with GPA) and `testo_main.zig` (5 tests). Regeneration is part
  of the daily flow; if you change the generator, regenerate these files.

---

## 3. Link with k6bus

There is another project, **k6bus** (https://github.com/fcases/K6Bus):
pub/sub with domains, transports and encryption, which uses ProtobuZig to
serialize messages, for configuration and for its safe APIs. The project is
independent: ProtobuZig lives alone; k6bus is just one consumer that copies
the generated files.

---

## Status (brief)

Pending items and history: see K6Bus's TODO. The internal tests (GPA, no
memory leaks) are the base of safe work.
