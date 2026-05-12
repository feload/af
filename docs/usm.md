# User Story Map (USM)

Mapa visual del producto Fredo. Vive como sitio estático en este repo;
no requiere servidor ni dependencias. Además del mapa de historias,
contiene los **SPECs** y **BUGs** como fuente única de verdad — el Lead
los escribe aquí (no en `.md`) y el Developer los lee directo del JSON.

## Ubicación

`.af/docs/usm/`

```
.af/docs/usm/
├── index.html   # El mapa interactivo
├── data.js      # Historias, pasos, actividades, slices (window.USM_DATA)
├── specs.js     # SPECs ligados a historias (window.USM_SPECS)
├── bugs.js      # Bugs ligados a historias (window.USM_BUGS)
└── styles.css   # Estilos (incluye soporte para tema claro y oscuro)
```

## Cómo verlo

- **Doble clic** sobre `index.html` — abre en el navegador.
- En distribuciones donde el navegador (Brave/Chrome) corre en sandbox
  Flatpak/Snap y no ve `.af/` (oculto), usar Firefox nativo:
  ```bash
  firefox .af/docs/usm/index.html
  ```
- O servir desde un servidor local:
  ```bash
  python3 -m http.server 8000 --directory .af/docs/usm
  ```

## Cómo se organiza el USM

Estructura Patton-style:

- **Actividades** (fila horizontal arriba) — el recorrido del usuario por
  el producto, de izquierda a derecha. Sticky al hacer scroll vertical.
- **Pasos** (fila horizontal debajo de cada actividad) — las acciones
  concretas que el usuario realiza dentro de cada actividad. También
  sticky.
- **Historias** (columnas verticales bajo cada paso) — las opciones o
  variantes de cómo el usuario hace ese paso.

Las historias se agrupan en **bandas horizontales** por versión
(slice). El orden vertical de las bandas: arriba los slices no
liberados (`planning` + `in-progress`, en orden de planeación), después
las versiones liberadas (la más reciente primero), y al final el
Backlog (historias sin slice asignado). El chip de cada banda muestra
el status del release como sufijo: "Versión v1.0 · en planeación",
"Versión v1.1 · en desarrollo", "Versión MVP · liberada".

## Estado e interacción

- Click en una historia → abre panel lateral derecho con narrativa,
  rationale, criterios de aceptación, tareas, **SPECs relacionados** y
  **bugs relacionados** (cada uno con todo el detalle del template,
  colapsable). La URL queda en `#US-XXXX` para que refrescar o
  compartir reabra la misma historia.
- Click en el chip de una banda → colapsa o expande sus historias.
- Hover sobre un paso o cualquier celda de su columna → resalta toda
  la columna con una franja de color.
- Drag horizontal sobre el mapa → scroll horizontal estilo Miro.
- Scroll vertical normal para recorrer las bandas.

## Señales visuales

Indicadores que ayudan al PM a leer el estado del mapa sin abrir cada
historia:

- **Insignia 🐞N en la tarjeta de la US** — aparece cuando esa US tiene
  bugs en `open` o `in-progress`. La cuenta es agregada de bugs vivos
  de esa US.
- **US liberada con bugs no se atenúa** — las US en bandas liberadas
  normalmente se ven tenues (ya cumplieron su rol). Si tienen bugs
  abiertos vuelven a opacidad 1 para que destaquen entre las
  tranquilas.
- **🐞 N bugs abiertos** (chip en header) — total global. Click activa
  un filtro que oculta toda US sin bugs abiertos: el mapa queda en
  modo "dónde duele". Click de nuevo apaga el filtro.
- **📋 N sin asignar** (chip en header) — incluye drafts de SPEC (con
  o sin story) y bugs huérfanos (sin story). Click abre el panel
  lateral en modo bandeja, mostrando cada item con su detalle
  completo. Es la cola de revisión del Lead.

## Esquema de los datos (`data.js`)

```js
window.USM_DATA = {
  slices: [
    { id, title, status }   // status opcional: planning | in-progress | released
  ],
  activities: [
    {
      id, title,
      steps: [
        {
          id, title,
          stories: [
            {
              id,          // p. ej. "US-0042"; el correlativo continúa
              title,
              status,      // proposed | active | done | dropped
              slice,       // id de slice o null para Backlog
              description, // narrativa "Como X, quiero Y para Z"
              rationale,   // por qué importa (1-2 líneas)
              acceptance,  // arreglo de criterios de aceptación
              tasks        // arreglo opcional [{ title, status }]
            }
          ]
        }
      ]
    }
  ]
}
```

Las historias **ya no llevan** un campo `spec` — la relación va al
revés: cada SPEC apunta a su historia con `story`. El USM filtra los
SPECs (y los bugs) por `id` de historia al abrir el panel. Una historia
puede tener varios SPECs y varios bugs.

### Status del slice (release)

`status` puede tener tres valores:

- `planning` — alcance en discusión, sin trabajo iniciado en las US del slice.
- `in-progress` — alguna US del slice está en `active` o `done`.
- `released` — shippeado en producción. Las historias se ven tenues en el mapa.

El campo es **opcional**. Si está, manda. Si falta, se infiere:

- Hay al menos una US `active` o `done` en el slice → `in-progress`.
- Todas son `proposed` (o el slice está vacío) → `planning`.
- `released` **nunca** se infiere — siempre debe marcarse a mano por el PM,
  porque shippear es decisión humana, no un estado derivable del trabajo.

Esto permite al PM sobreescribir cuando convenga (lock un release en
`in-progress` aunque todas las US estén `done`, por ejemplo, mientras
se espera ventana de deployment).

## Esquema de SPECs (`specs.js`)

```js
window.USM_SPECS = [
  {
    id,            // p. ej. "SPEC-0001"; correlativo único en todo el repo
    title,
    status,        // draft | ready | approved | archived
    story,         // id del US al que pertenece o null para trabajo transversal (infra, refactor, CI)
    context,       // por qué se construye (1 párrafo corto)
    problem,       // qué está roto o falta (específico)
    constraints,   // límites duros: sin deps nuevas, performance, etc.
    subtasks: [
      {
        description, // "[verbo] — files: `ruta` — what to change: [qué] — done when: [criterio]"
        done         // true | false
      }
    ],
    edgeCases,     // lo no obvio que el Developer debe manejar
    doneCriteria   // cómo el PM verifica de punta a punta
  }
]
```

`status` significa:
- `draft` — el Lead lo está escribiendo o el PM aún no lo confirma
- `ready` — listo para implementarse (el Developer puede tomarlo)
- `approved` — implementado y aprobado por el PM, esperando PR
- `archived` — PR mergeado; queda como registro

## Esquema de bugs (`bugs.js`)

```js
window.USM_BUGS = [
  {
    id,                  // p. ej. "BUG-0001"
    title,
    status,              // open | in-progress | fixed | wont-fix
    story,               // id del US al que pertenece, o null para bugs huérfanos (raro)
    foundAt,             // ISO 8601 — cuándo se detectó
    description,         // qué está mal (1 oración clara)
    stepsToReproduce,    // arreglo de strings
    expected,            // qué debería pasar
    actual,              // qué pasa en realidad
    affectedArea,        // archivos/módulos sospechosos
    rootCause,           // qué exactamente lo causa (Lead lo llena)
    fix: [
      {
        description, // mismo formato que las subtasks de SPEC
        done
      }
    ],
    regressionTest,      // test que evita que recurra (obligatorio)
    doneCriteria         // cómo el PM verifica que está corregido
  }
]
```

Cuando se abre el detalle de una historia, el panel muestra cada SPEC y
cada bug como tarjeta colapsable con todas estas secciones. Por defecto
las tarjetas se abren si están vivas (`ready`/`approved` para SPECs,
`open`/`in-progress` para bugs) y cerradas si están terminadas.

## Histórico

Hasta `v0.6` los SPECs vivían como `.md` en `.af/specs/active/` y
`archived/`. A partir de la migración a JSON, la fuente de verdad es
`specs.js` y `bugs.js` bajo `.af/docs/usm/`; el directorio
`.af/specs/` fue eliminado del repo y del bootstrap del framework.
