load("@prelude//rust:rust_toolchain.bzl", "PanicRuntime", "RustToolchainInfo")

def _rustup_toolchain_impl(ctx: AnalysisContext) -> list[Provider]:
    dist = ctx.attrs.distribution[DefaultInfo].default_outputs[0]
    prefix = "rust-1.92.0-x86_64-unknown-linux-gnu/"

    rustc_dir = dist.project(prefix + "rustc")
    rustc_bin = rustc_dir.project("bin/rustc")
    rustdoc_bin = rustc_dir.project("bin/rustdoc")
    clippy_bin = dist.project(prefix + "clippy-preview/bin/clippy-driver")
    sysroot_path = dist.project(prefix + "rust-std-x86_64-unknown-linux-gnu")

    hidden = [ctx.attrs.distribution[DefaultInfo].default_outputs]

    return [
        DefaultInfo(),
        RustToolchainInfo(
            clippy_driver = RunInfo(args = cmd_args(clippy_bin, hidden = hidden)),
            compiler = RunInfo(args = cmd_args(rustc_bin, hidden = hidden)),
            panic_runtime = PanicRuntime("unwind"),
            rustc_target_triple = "x86_64-unknown-linux-gnu",
            rustdoc = RunInfo(args = cmd_args(rustdoc_bin, hidden = hidden)),
            sysroot_path = sysroot_path,
        ),
    ]

rustup_toolchain = rule(
    impl = _rustup_toolchain_impl,
    attrs = {
        "distribution": attrs.dep(providers = [DefaultInfo]),
    },
    is_toolchain_rule = True,
)
