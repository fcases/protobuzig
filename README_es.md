# ProtobuZig

(readme in [english](README_en.md))  
(legu min en la [Esperanta versio](README.md))

ProtobuZig es un compilador de Google Protocol Buffers a **Zig 0.15.2**. No
necesita instalar `protoc`: usa su propio analizador ([mecha](https://github.com/Hejsil/mecha))
y construye su propio AST. Además no es solo para Zig: está previsto también C
(todavía en desarrollo) y en el futuro Vala, Go y quizá Python.

Es una herramienta personal, hecha para aprender y para k6bus (ver más
adelante); no pretende ser otro `protoc`.

---

## 1. Introducción

Qué obtienes: escribes un `.proto`, ejecutas `protobuzig`, y te da código Zig
para tus mensajes: serialización (binario protobuf, Base64, Protobuf Text,
ZON, JSON), deserialización, representaciones de texto y una API segura.

### Limitaciones (honestas)

- **Solo proto2**. `proto3` se detecta y recibes un error claro.
- No entiende **extensions / extend** (error con número de línea).
- Solo **un nivel** de mensajes/enums anidados, y además las referencias a
  tipos anidados no se resuelven (error "tipo no definido"). El nivel 2+ está
  conscientemente fuera.
- No es un **plugin de protoc**.
- Un `.proto` por ejecución (aunque `--ws` te da un workspace completo).
- La gramática es permisiva: las líneas no reconocidas no fallan, **avisan**
  (y la validación final caza tipos no definidos).

### Futuro (sueños)

- Más binarizaciones: **CDR**, **ASN.1-BER**, **ASN.1-DER**.
- Analizar y parsear **OMG IDL** en lugar de protobuf (mundo OMG-DDS y CORBA).
- Traducir a **Zig 0.16** o posterior.
- Versiones para **Windows** y **BSD**.

---

## 2. Modo de uso

Primero obtén y compila la herramienta (necesita Zig 0.15.2):

```sh
git clone https://github.com/fcases/protobuzig.git
cd protobuzig
zig build          # crea zig-out/bin/protobuzig
export PATH="$PWD/zig-out/bin:$PATH"   # opcional: para usar solo 'protobuzig'
```

Los ejemplos de abajo dan por hecho que `protobuzig` está en el PATH (o
escribe `zig-out/bin/protobuzig`). Tras compilar, el binario está en
`zig-out/bin/`.

### 2.1. Línea de comandos

Opciones:

| Opción | Descripción |
|---|---|
| `file.proto` | el fichero `.proto` (posicional, uno por ejecución) |
| `--proto_dir <dir>` | dónde buscar el `.proto` (por defecto `.`) |
| `--output_dir <dir>` | dónde escribir el `.zig` generado (por defecto `.`) |
| `--ws <dir>` | crea un workspace autocontenido en `<dir>` (ignora `--output_dir`) |
| `--verbose, -v` | trazas del analizador |
| `--help, -h` | ayuda |

Ejemplos:

```sh
# Solo proto: genera Msg.zig + Msg_api.zig en el directorio actual
protobuzig Msg.proto

# Con directorios separados
protobuzig --proto_dir protos/k6bus --output_dir generated/core Msg.proto

# Workspace: protos/, src/main.zig + tests.zig, src/runtime/, build.zig,
# .vscode (tasks/settings/launch) y .gitignore
protobuzig --ws miws --proto_dir internaltests/protos Ciudad.proto
```

### 2.2. Ficheros de salida

- **`Xxxx.zig`** — el código "crudo" generado: tipos + serialización/
  deserialización + formatos de texto. Es la capa interna: normalmente no lo
  tocas.
- **`Xxxx_api.zig`** — la **API segura**: get/set/has/clear/append/At/Count,
  oneofs, clone, formatos. Recomendada: es más segura y cómoda, y sus nombres
  están en inglés. (La capa cruda, con funciones y comentarios en esperanto,
  solo para iniciados en esa lengua 😉.)
- **`encdec.zig`** — soporte de serialización (EncodeBuffer/DecodeBuffer). El
  código generado lo importa; el workspace lo instala solo.
- Con `--ws` además: **`build.zig`** (exe + pasos check/run/test), los
  ficheros de **`.vscode`** (tasks/settings/launch) y **`.gitignore`**.

### 2.3. Ejemplos completos

- `examples/prueba1` — workspace `--ws` de prueba (Ciudad.proto):
  `src/main.zig` con ejemplo (crear mensaje, escribir a fichero, releer,
  cambiar de formato) y `src/tests.zig` con round-trip.
- `internaltests/` — la batería interna: `testo2.zig`, `testo3.zig`
  (round-trips con GPA) y `testo_main.zig` (5 tests). La regeneración es
  parte del flujo diario; si cambias el generador, regenera estos ficheros.

---

## 3. Nexo con k6bus

Existe otro proyecto, **k6bus** (https://github.com/fcases/K6Bus): pub/sub
con dominios, transportes y cifrado, que usa ProtobuZig para binarizar
mensajes, para configuración y para sus APIs seguras. El proyecto es
independiente: ProtobuZig vive solo; k6bus es solo un consumidor que copia
los ficheros generados.

---

## Estado (breve)

Pendientes e historial: ver el TODO de K6Bus. Los tests internos (GPA, sin
fugas de memoria) son la base del trabajo seguro.
