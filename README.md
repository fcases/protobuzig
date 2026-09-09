# ProtobuZig

(leeme en [español](README_es.md))  
(read me in [english](README_en.md))

ProtobuZig estas kompililo de Google Protocol Buffers al Zig 0.15.2. Ne
bezonas instali protoc: ĝi uzas sian propran analizilon ([mecha](https://github.com/Hejsil/mecha))
kaj konstruas sian propran AST. Krome ĝi ne estas nur por Zig: planita estas
ankaŭ C (ankoraŭ en disvolvo) kaj estonte Vala, Go kaj eble Python.

Estas laborilo persona, farita por lerni kaj por k6bus (vidu pli sube); ĝi ne
pretendas esti alia `protoc`.

---

## 1. Enkonduko

Kion vi ricevas: vi skribas dosieron `.proto`, vi rulas `protobuzig`, kaj ĝi
donas al vi Zig-kodon por viaj mesaĝoj: seriaĵo (protobuf-binary, Base64,
Protobuf Text, ZON, JSON), deseriaĵo, tekstaj reprezentoj kaj sekura API.

### Limigoj (honestaj)

- **Proto2** nur. `proto3` estas detektata kaj vi ricevas klaran eraron.
- Ne komprenas **extensions / extend** (eraro kun linia numero).
- Nur **unu nivelo** de nestitaj mesaĝoj/enumoj, kaj krome la referencoj al
  nestitaj tipoj ne solviĝas (eraro "tipo ne difinita"). Nivelo 2+ estas
  konscie ne subtenata.
- Ne estas **`protoc`-aldonaĵo (plugin)**.
- Unu `.proto` por rulo (kvankam `--ws` donas al vi kompletan laborspacon).
- La gramatiko estas permesema: linioj ne rekonataj ne malsukcesigas, ili
  **avertas** (kaj la fina validado kaptas tipojn ne difinitajn).

### Estonteco (sonĝoj)

- Pliaj binarigoj: **CDR**, **ASN.1-BER**, **ASN.1-DER**.
- Analizi kaj parse **OMG IDL** anstataŭ protobuf (mondo OMG-DDS kaj CORBA).
- Traduki al **Zig 0.16** aŭ posta.
- Versioj por **Windows** kaj **BSD**.

---

## 2. Uzado

Unue akiru kaj kompilu la ilon (bezonas Zig 0.15.2):

```sh
git clone https://github.com/fcases/protobuzig.git
cd protobuzig
zig build          # kreas zig-out/bin/protobuzig
export PATH="$PWD/zig-out/bin:$PATH"   # nedeviga: por uzi nur 'protobuzig'
```

La ekzemploj sube supozas ke `protobuzig` estas en la PATH (aŭ vi skribas
`zig-out/bin/protobuzig`). Post kompilo la dosiero estas ĉe `zig-out/bin/`.

### 2.1. Komandlinio

Opcioj:

| Opcio | Priskribo |
|---|---|
| `file.proto` | la `.proto`-dosiero (pozicia, unu po rulo) |
| `--proto_dir <dir>` | kie oni serĉas la `.proto` (aprior: `.`) |
| `--output_dir <dir>` | kie oni skribas la generitan `.zig` (aprior: `.`) |
| `--ws <dir>` | kreas memstaran laborspacon ĉe `<dir>` (ignoras `--output_dir`) |
| `--verbose, -v` | spurspuroj de la analizilo |
| `--help, -h` | helpo |

Ekzemploj:

```sh
# Nura proto: generas Msg.zig + Msg_api.zig en la nuna dosierujo
protobuzig Msg.proto

# Kun apartaj dosierujoj
protobuzig --proto_dir protos/k6bus --output_dir generated/core Msg.proto

# Laborspaco: protos/, src/main.zig + tests.zig, src/runtime/, build.zig,
# .vscode (tasks/settings/launch) kaj .gitignore
protobuzig --ws miws --proto_dir internaltests/protos Ciudad.proto
```

### 2.2. Eliraj dosieroj

- **`Xxxx.zig`** — la "kruda" generita kodo: tipoj + seriaĵo/deseriaĵo +
  tekstaj formatoj. Ĝi estas interna tavolo: vi normale ne tuŝas ĝin.
- **`Xxxx_api.zig`** — la **sekura API**: get/set/has/clear/append/At/Count,
  oneof-oj, clone, formatoj. Rekomendita: ĝi estas pli sekura kaj facile
  uzebla, kaj la nomoj estas en la angla. (La kruda tavolo, kun funkcioj kaj
  komentoj en Esperanto, nur por tiuj iniciitaj en tiu lingvo 😉.)
- **`encdec.zig`** — subteno de seriaĵo (EncodeBuffer/DecodeBuffer). La
  generita kodo importas ĝin; la laborspaco ĝin instalas mem.
- Kun `--ws` ankaŭ: **`build.zig`** (exe + pasoj check/run/test), la dosieroj
  de **`.vscode`** (tasks/settings/launch) kaj **`.gitignore`**.

### 2.3. Plenaj ekzemploj

- `examples/prueba1` — laborspaco `--ws` de prova (Ciudad.proto): `src/main.zig`
  kun ekzemplo (krei mesaĝon, skribi al dosiero, relegi, ŝanĝi formaton) kaj
  `src/tests.zig` kun rondvoja testo.
- `internaltests/` — la interna testaro: `testo2.zig`, `testo3.zig` (rondvojoj
  kun GPA) kaj `testo_main.zig` (5 testoj). Regenerado estas parto de la
  ĉiutaga fluo; se vi ŝanĝas la generatoron, regeneru ĉi tiujn dosierojn.

---

## 3. Ligo kun k6bus

Ekzistas alia projekto, **k6bus** (https://github.com/fcases/K6Bus): publikigo/
subskribo (pub/sub) kun domajnoj, transportoj kaj ĉifrado, kiu uzas ProtobuZig
por binarigi mesaĝojn, por agordo kaj por sekuraj API-oj. Tiu projekto estas
sendependa: ProtobuZig vivas sola; k6bus estas nur unu konsumanto kiu kopias
la generitajn dosierojn.

---

## Stato (mallonge)

Pendaj aferoj kaj historio: vidu la TODO de K6Bus. La internaj testoj (GPA,
sen memorfugoj) estas la bazo de la certa laboro.
