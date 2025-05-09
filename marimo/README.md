# Marimo

[marimo](https://marimo.io) is an open-source reactive notebook for Python — reproducible, git-friendly, SQL built-in, executable as a script, and shareable as an app.

## Build the container

```sh
wave -f Dockerfile --await
```

> [!NOTE]
> You can swap users but Marimo doesn't let you open Notebooks in two different tabs even to avoid breaking the state of the Notebook.
