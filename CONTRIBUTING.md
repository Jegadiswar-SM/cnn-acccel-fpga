# Contributing

## Principles

- Keep documentation and RTL synchronized.
- Do not hand-edit generated netlists, waveforms, SMT2 files, or OpenROAD database artifacts.
- Keep active source lists synchronized when adding or removing RTL modules.
- Preserve the distinction between integrated top-level behavior and exploratory or unused modules.

## Before Submitting Changes

Run the checks that are available in your environment:

```sh
cd dv
make lint
make sim
```

When Yosys/Z3 paths are available:

```sh
cd dv/fv
make bmc DEPTH=60

cd ../../syn
make synth
```

For OpenROAD changes:

```sh
cd flow
make synth
make floorplan
make place
```

Run later physical-design stages as your environment supports them.

## RTL Changes

If you change top-level functionality:

- update or add simulation tests in `dv/`,
- update formal assumptions/assertions in `rtl/cnn_top.v` or `dv/fv/`,
- update register/interface documentation under `docs/`,
- mirror `rtl/` changes into `flow/designs/src/cnn_top/` unless the flow config is changed to use the canonical RTL directory.

## Documentation Changes

Do not invent behavior. If a behavior is not inferable from the repository, state that it could not be inferred.

Update these docs when changing:

- registers or ports: `docs/configuration.md`, `README.md`
- top-level behavior: `docs/architecture.md`, `docs/usage.md`
- tests/formal: `docs/verification.md`
- synthesis or OpenROAD flow: `docs/synthesis-and-physical-design.md`
- known gaps: `docs/limitations.md`, `docs/troubleshooting.md`
