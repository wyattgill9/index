mod model;
mod render;
mod shell;

use std::io::Read as _;
use std::path::PathBuf;

use model::UnitGraph;
use render::{RenderOptions, render_units_nix};

#[derive(Debug)]
struct Cli {
    workspace_root: PathBuf,
    vendor_root: Option<PathBuf>,
    content_addressed: bool,
    toolchain_id: Option<String>,
}

fn parse_cli() -> Result<Cli, String> {
    let mut args = std::env::args().skip(1);

    let command = args
        .next()
        .ok_or_else(|| "expected command: render".to_string())?;
    if command != "render" {
        return Err(format!("unknown command {command:?}; expected render"));
    }

    let mut workspace_root = None;
    let mut vendor_root = None;
    let mut content_addressed = false;
    let mut toolchain_id = None;

    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--workspace-root" => {
                workspace_root =
                    Some(PathBuf::from(args.next().ok_or_else(|| {
                        "--workspace-root needs a value".to_string()
                    })?));
            }
            "--vendor-root" => {
                vendor_root = Some(PathBuf::from(
                    args.next()
                        .ok_or_else(|| "--vendor-root needs a value".to_string())?,
                ));
            }
            "--content-addressed" => {
                content_addressed = true;
            }
            "--toolchain-id" => {
                toolchain_id = Some(
                    args.next()
                        .ok_or_else(|| "--toolchain-id needs a value".to_string())?,
                );
            }
            "-h" | "--help" => {
                print_help();
                std::process::exit(0);
            }
            other => return Err(format!("unknown argument {other:?}")),
        }
    }

    Ok(Cli {
        workspace_root: workspace_root.unwrap_or_else(|| PathBuf::from(".")),
        vendor_root,
        content_addressed,
        toolchain_id,
    })
}

fn print_help() {
    println!(
        "\
nix-cargo-unit render [OPTIONS] < unit-graph.json

Options:
  --workspace-root PATH    Canonical workspace root from cargo --unit-graph
  --vendor-root PATH       Cargo vendor directory used for registry/git crates
  --content-addressed      Emit CA-derivation attributes on generated units
  --toolchain-id VALUE     Salt unit identity hashes with a Rust toolchain id
"
    );
}

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let cli = parse_cli().map_err(|message| format!("{message}\n\nrun with --help for usage"))?;

    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input)?;
    let graph: UnitGraph = serde_json::from_str(&input)?;
    if graph.version != 1 {
        return Err(format!("unsupported cargo unit graph version {}", graph.version).into());
    }

    let rendered = render_units_nix(
        &graph,
        &RenderOptions {
            workspace_root: cli.workspace_root,
            vendor_root: cli.vendor_root,
            content_addressed: cli.content_addressed,
            toolchain_id: cli.toolchain_id,
        },
    )?;
    print!("{rendered}");

    Ok(())
}

fn main() {
    if let Err(error) = run() {
        eprintln!("error: {error}");
        std::process::exit(1);
    }
}
