---
name: prepara-pr
description: Abre el PR de la rama actual contra main, pero solo si pasan ruff, bandit, pytest y Conventional Commits, y si el subagente revisor-pr aprueba el diff. Usar cuando el usuario pide preparar, abrir o crear el PR de la rama en la que está trabajando (`/prepara-pr`).
---

Este skill automatiza la apertura de un PR de la rama actual contra `main`, pero SOLO si pasan todos los controles de calidad y la revisión de código. Sigue estos pasos en orden y no te saltes ninguno.

## 1. Ejecutar los gates

Corre el script de gates y muestra su salida completa al usuario:

```
bash .claude/skills/prepara-pr/gates.sh
```

Este script corre, en orden, y siempre completo (no se detiene en el primer fallo):
1. `ruff check` sobre `src/` y `tests/`.
2. `bandit -r src/ -ll` (solo severidad media y alta).
3. `pytest`.
4. Verificación de Conventional Commits en todos los commits de la rama actual que no estén en `main`.

- Si el script termina con código **distinto de 0**: DETENTE. No continúes con los pasos siguientes, no toques git ni GitHub. Resume al usuario cuál(es) gate(s) fallaron y por qué, usando la salida del script.
- Si termina con código **0**, continúa al paso 2.

## 2. Pedir revisión al subagente `revisor-pr`

Invoca el agente `revisor-pr` (tool Agent, `subagent_type: "revisor-pr"`) pidiéndole explícitamente que revise el diff de la rama actual contra `main` (por ejemplo `git diff main...HEAD`, o el rango de commits equivalente). Dale contexto suficiente: nombre de la rama, base (`main`), y que su veredicto decide si se abre el PR.

## 3. Interpretar el veredicto

- Si el veredicto es **RECHAZAR/RECHAZO**: DETENTE. No abras el PR. Muestra al usuario la lista de problemas que reportó `revisor-pr` y su justificación.
- Si el veredicto es **APROBAR**: continúa al paso 4.

## 4. Abrir el PR

Solo si los gates pasaron Y `revisor-pr` aprobó:

1. Si la rama actual no tiene upstream o hay commits sin publicar, haz `git push -u origin <rama-actual>` (o `git push` si ya tiene upstream).
2. Crea el PR contra `main` con `gh pr create --base main --title "..." --body "..."`, siguiendo las instrucciones estándar de creación de PRs (resume los commits del rango `main...HEAD`, no solo el último commit).
3. Devuelve al usuario la URL del PR creado.

## Notas

- Nunca abras el PR si te saltaste el paso 1 o 2, o si alguno de ellos fue negativo.
- No hagas `git push --force` ni reescribas historia como parte de este flujo.
- Si `gh` no está autenticado o la rama actual es `main`, detente y explica el problema en vez de intentar workarounds.
