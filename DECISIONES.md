# PROTOBUZIG - DECISIONES DE DISENO (registro vivo)

Fecha de inicio: 2026-09-08.
Este registro acumula las decisiones operativas/diseño ya cerradas del
ecosistema ProtobuZig. Cuando el concepto operativo quede completo, este
material alimentara el documento conops de K6Bus (no se toca conops hasta
entonces).

-------------------------------------------------------------------------------
1. protobuzig vive independiente de K6Bus
-------------------------------------------------------------------------------
- protobuzig es un proyecto propio: parser .proto + generadores de Zig.
- K6Bus es UN consumidor: copia lo generado (X.zig, X_api.zig, encdec.zig)
  igual que cualquier otro proyecto. El workspace --ws no referencia ningun
  runtime externo (encdec.zig via @embedFile, autocontenido).
- El pub/sub (raw + safe) NO pertenece a protobuzig: es herramienta del lado
  K6Bus que trabaja sobre el Zig generado. protobuzig no sabe nada de
  dominios, transportes ni colas.

-------------------------------------------------------------------------------
2. Espacio de trabajo generado: protobuzig --ws <dir>
-------------------------------------------------------------------------------
Layout (cerrado):
  <ws>/
    protos/            copia del .proto de entrada
    src/
      main.zig         codigo de usuario: ejemplo modificable (con muestra
                       automatica del primer campo del primer mensaje)
      root.zig         modulo raiz: re-exporta lo generado (uso libreria Zig)
      tests.zig        un test round-trip (texto + binario) por mensaje
      runtime/         TODO lo generado: X.zig + X_api.zig + encdec.zig
    build.zig          exe demo + pasos check/run/test; sin cfg/
    .vscode/           settings/tasks/launch
    .gitignore         .zig-cache/, zig-out/, demo.*

Los generados se regeneran SIEMPRE dentro de src/runtime; el usuario no los
toca a mano. El main/root/tests se generan para el primer mensaje del primer
proto y se extienden a mano (un test por mensaje externo).

-------------------------------------------------------------------------------
3. Solo-Zig: cero artefactos binarios
-------------------------------------------------------------------------------
En el supuesto solo-Zig del conops NO se crea ni se usa ninguna libreria:
el consumo Zig es a nivel de fuente (@import de runtime/... o del modulo
root.zig). Un .a/.so solo tiene sentido cuando existe un consumidor no-Zig
(escenario C). El build.zig del ws solo-Zig no lleva addLibrary; root.zig se
compila en "check" via addObject (validacion, no artefacto instalable).

-------------------------------------------------------------------------------
4. Escenario C futuro: la libreria es la fachada C de la API segura generada
-------------------------------------------------------------------------------
- La libreria NO es de protobuzig (parser/generadores NUNCA se exportan).
- Por fichero proto, sobre la API segura Zig:
      Config.proto
        +-> Config.zig        (raw/impl - interno, nunca se exporta)
        +-> Config_api.zig    (API segura Zig: LA superficie real)
        +-> [C] Config_c.zig  (export fns sobre Config_api.zig) + Config.h
              -> libConfig.a  (misma funcionalidad que Config_api.zig, en C)
- El raw/impl no se exporta a C: solo el API segura.
- X_api.zig es el CONTRATO 1:1 de la capa C: initDefault/deinit/clone,
  get/set/has/clear/append/At/Count, oneof y serializacion/formatos con
  propagacion de errores. Debe estar estable antes de emitir el emisor C.
- protobuzig (binario) es un ejecutable puro, sin libreria propia.
- El .h se emite desde el generador (no depende del -femit-h roto de Zig).

-------------------------------------------------------------------------------
5. Directorios del repo protobuzig_v2
-------------------------------------------------------------------------------
- internaltests/: pruebas internas del generador (antes example/):
  testo_main.zig, testo2.zig, testo3.zig + cfg/ + generated/ + protos/.
- examples/: reservado para los workspaces de prueba creados con --ws
  (p. ej. examples/prueba1).
