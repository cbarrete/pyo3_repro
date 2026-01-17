def _execution_platform_impl(ctx: AnalysisContext) -> list[Provider]:
    execution_platform = ExecutionPlatformInfo(
        label = ctx.label.raw_target(),
        configuration = ConfigurationInfo(
            constraints = ctx.attrs.cpu_configuration[ConfigurationInfo].constraints |
                          ctx.attrs.os_configuration[ConfigurationInfo].constraints,
            values = {},
        ),
        executor_config = CommandExecutorConfig(
            local_enabled = True,
            use_persistent_workers = True,
            remote_enabled = True,
            remote_cache_enabled = True,
            allow_cache_uploads = True,
            use_limited_hybrid = False,
            remote_execution_properties = {
                "container-image": "docker://registry.com:image_name@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            },
            remote_execution_use_case = "buck2-default",
            remote_output_paths = "strict",
        ),
    )

    return [
        DefaultInfo(),
        execution_platform,
        ExecutionPlatformRegistrationInfo(platforms = [execution_platform]),
    ]

execution_platform = rule(
    impl = _execution_platform_impl,
    attrs = {
        "cpu_configuration": attrs.dep(providers = [ConfigurationInfo]),
        "os_configuration": attrs.dep(providers = [ConfigurationInfo]),
    },
)
