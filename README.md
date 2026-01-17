# PyO3 remote build failure minimal repro

This repo is a minimal reproduction of a bug that causes PyO3 (added to the build using [Reindeer](https://github.com/facebookincubator/reindeer)) to fail to build with remote execution.

It has been reproduced with:

- Both [EngFlow](https://www.engflow.com/) and [NativeLink](https://www.nativelink.com/) as RBE backends.
- Different Buck2 versions, the latest tested being 2026-01-02.
- Different versions of PyO3 (mostly 0.26 and 0.27).
- Different versions of Reindeer.
- Enabling and disabling various build scripts in the `fixups.toml` files.

## Setup

Since this bug involves remote execution, you will need an RBE.

First off, add your RBE credentials in `//.buckconfig.local`.
There are examples in the [Buck2 repo](https://github.com/facebook/buck2/tree/main/examples/remote_execution).

You will also need to update (or potentially remove, depending on your RBE setup) `"container-image"` in `//defs.bzl`.

## Reproduction

First off, a local build should succeed:

```
> buck2 clean &>/dev/null && buck2 build --local-only --no-remote-cache //third_party:pyo3
Starting new buck2 daemon...
Connected to new buck2 daemon.
Build ID: 8bbb5034-7d5a-47c9-92ea-352036a774ea
Network: Up: 0B  Down: 1.1GiB
Loading targets.   Remaining     0/17                             45 dirs read, 197 targets declared
Analyzing targets. Remaining     0/202                            2166 actions, 3731 artifacts declared
Executing actions. Remaining     0/186                            1:04.7s exec time total
Command: build.    Finished 56 local
Time elapsed: 1:30.0s
BUILD SUCCEEDED
```

To reproduce the failure:

```
> buck2 clean &>/dev/null && buck2 build --remote-only //third_party:pyo3
Starting new buck2 daemon...
Connected to new buck2 daemon.
Action failed: root//third_party:_pyo3-macros-0.26.0 (rustc proc-macro)
Remote command returned non-zero exit code 1
Remote action digest: `1fef6392df7d9a1a981cef09b28385a32fe37247629a14c836505849e84de221:141`
stdout:
stderr:
error[E0463]: can't find crate for `pyo3_macros_backend`
 --> third_party/pyo3-macros-0.26.0.crate/src/lib.rs:7:5
  |
7 | use pyo3_macros_backend::{
  |     ^^^^^^^^^^^^^^^^^^^ can't find crate


error[E0282]: type annotations needed
  --> third_party/pyo3-macros-0.26.0.crate/src/lib.rs:48:40
   |
48 |                 Ok(expanded) => return expanded.into(),
   |                                        ^^^^^^^^ cannot infer type


error: aborting due to 2 previous errors


Some errors have detailed explanations: E0282, E0463.

For more information about an error, try `rustc --explain E0282`.

info:
Execution result: https://redacted
Build ID: 909f87ca-614c-426b-8114-ffcb3e51a57f
Network: Up: 4.7MiB  Down: 19MiB  (GRPC-SESSION-ID)
Loading targets.   Remaining     0/17                             45 dirs read, 197 targets declared
Analyzing targets. Remaining     0/202                            2166 actions, 3731 artifacts declared
Executing actions. Remaining     0/186                            3:59.8s exec time total
Command: build.    Finished 1 remote, 53 cache (98% hit)          3:59.2s exec time cached (99%)
Time elapsed: 43.6s
BUILD FAILED
Failed to build 'root//third_party:_pyo3-macros-0.26.0 (root//:host#515794b8dd8b21d1)'
```

After this failure, building locally will now fail:

```
> buck2 build --local-only --no-remote-cache //third_party:pyo3
File changed: root//4913
File changed: root//README.md
Directory changed: root//README.md
2 additional file change events
Action failed: root//third_party:_pyo3-macros-0.26.0 (rustc proc-macro)
Local command returned non-zero exit code 1
Reproduce locally: `env --chdir="$(buck2 root --kind project)" -- 'BUCK_SCRATCH_PATH=buck-out/v2/tmp/root/83c4593c3b0497 ...<omitted>... out/v2/gen/root/515794b8dd8b21d1/third_party/___pyo3-macros-0.26.0__/MPPL/pyo3_macros-link-diag.args (run `buck2 log what-failed` to get the full command)`
stdout:
stderr:
error[E0463]: can't find crate for `pyo3_macros_backend`
 --> third_party/pyo3-macros-0.26.0.crate/src/lib.rs:7:5
  |
7 | use pyo3_macros_backend::{
  |     ^^^^^^^^^^^^^^^^^^^ can't find crate


error[E0282]: type annotations needed
  --> third_party/pyo3-macros-0.26.0.crate/src/lib.rs:48:40
   |
48 |                 Ok(expanded) => return expanded.into(),
   |                                        ^^^^^^^^ cannot infer type


error: aborting due to 2 previous errors


Some errors have detailed explanations: E0282, E0463.

For more information about an error, try `rustc --explain E0282`.

Build ID: c658cebc-398a-4ec1-b1fa-131fa29dddbd
Network: Up: 5.0MiB  Down: 1.1GiB  (GRPC-SESSION-ID)
Analyzing targets. Remaining     0/173
Executing actions. Remaining     0/186                            0.5s exec time total
Command: build.    Finished 1 local
Time elapsed: 24.2s
BUILD FAILED
Failed to build 'root//third_party:_pyo3-macros-0.26.0 (root//:host#515794b8dd8b21d1)'
```
