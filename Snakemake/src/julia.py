### UTILS: running julia
import os
import tempfile
from json import dumps

from snakemake.shell import shell


def process_args(x):
    """
    Processes input/output/etc. as dict if it has kwargs or a list if it doesn't.
    """
    kwargs = dict(x)
    if kwargs:
        args_as_dict = {i + 1: v for i, v in enumerate(x)}
        return args_as_dict | kwargs
    else:
        return list(x)


def julia(scriptfile, **rule):
    """
    Run a Julia script.
    """
    rule_dict = {k: process_args(v) for k, v in rule.items()}
    # write dumps(rule) to a temp file
    # use tempfile package
    with tempfile.NamedTemporaryFile(delete=False, suffix=".json") as f:
        f.write(dumps(rule_dict).encode())
        f.flush()
        # make sure to close the file
        f.close()
        daemon_mode = config.get("daemon-mode", "no").lower() in [
            "true",
            "1",
            "t",
            "y",
            "yes",
        ]
        if daemon_mode:
            shell(
                f"julia --project=. -e 'using DaemonMode; runargs()' {scriptfile} '{f.name}'"
            )
        else:
            threads = config.get("threads", "auto")
            sysimage = (
                f"--sysimage={config['sysimage']}" if config.get("sysimage") else ""
            )
            shell(
                f"julia --project=. --threads={threads} {sysimage} {scriptfile} < '{f.name}'"
            )
        # delete the temp file
        os.remove(f.name)
