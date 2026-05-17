from __future__ import annotations

import argparse
import code
import contextlib
import io
import traceback
from collections.abc import Callable, Sequence
from dataclasses import dataclass, field
from typing import cast

from mcp.server.fastmcp import FastMCP


@dataclass
class PythonSession:
    globals: dict[str, object] = field(default_factory=lambda: {"__name__": "__ix_python_mcp__"})

    def evaluate(self, expression: str) -> str:
        def run() -> str:
            value = cast(object, eval(compile(expression, "<ix-python-mcp eval>", "eval"), self.globals))
            return repr(value)

        return self._capture(run)

    def execute(self, source: str) -> str:
        def run() -> str:
            exec(compile(source, "<ix-python-mcp exec>", "exec"), self.globals)
            return ""

        return self._capture(run)

    def reset(self) -> str:
        self.globals.clear()
        self.globals["__name__"] = "__ix_python_mcp__"
        return "session reset"

    def repl(self) -> None:
        console = code.InteractiveConsole(self.globals)
        console.interact(banner="ix Python MCP session", exitmsg="")

    def _capture(self, run: Callable[[], str]) -> str:
        stdout = io.StringIO()
        stderr = io.StringIO()

        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            try:
                value = run()
            except Exception:
                value = ""
                traceback.print_exc()

        sections: list[str] = []
        if stdout.getvalue():
            sections.append("stdout:\n" + stdout.getvalue().rstrip())
        if stderr.getvalue():
            sections.append("stderr:\n" + stderr.getvalue().rstrip())
        if value:
            sections.append("result:\n" + value)

        return "\n\n".join(sections) if sections else "ok"


session = PythonSession()
mcp = FastMCP("ix-python")


@mcp.tool()
def python_eval(expression: str) -> str:
    """Evaluate a Python expression in the persistent session."""
    return session.evaluate(expression)


@mcp.tool()
def python_exec(source: str) -> str:
    """Execute Python statements in the persistent session."""
    return session.execute(source)


@mcp.tool()
def python_reset() -> str:
    """Clear the persistent Python session."""
    return session.reset()


def main(argv: Sequence[str] | None = None) -> None:
    parser = argparse.ArgumentParser(prog="ix-python-mcp")
    subcommands = parser.add_subparsers(dest="command")
    _ = subcommands.add_parser("serve")
    _ = subcommands.add_parser("repl")

    eval_parser = subcommands.add_parser("eval")
    _ = eval_parser.add_argument("expression")

    exec_parser = subcommands.add_parser("exec")
    _ = exec_parser.add_argument("source")

    args = parser.parse_args(argv)
    command = _optional_string_attr(args, "command")
    match command:
        case None | "serve":
            mcp.run()
        case "repl":
            session.repl()
        case "eval":
            print(session.evaluate(_string_attr(args, "expression")))
        case "exec":
            print(session.execute(_string_attr(args, "source")))
        case _:
            parser.error(f"unknown command: {command}")


def _optional_string_attr(args: argparse.Namespace, name: str) -> str | None:
    value = cast(object, getattr(args, name, None))
    if value is None or isinstance(value, str):
        return value
    raise TypeError(f"{name} must be a string")


def _string_attr(args: argparse.Namespace, name: str) -> str:
    value = cast(object, getattr(args, name))
    if isinstance(value, str):
        return value
    raise TypeError(f"{name} must be a string")
