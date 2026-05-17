mod model;
mod render;
mod shell;

use std::io::Read as _;
use std::path::PathBuf;

use clap::Parser as _;
use model::UnitGraph;
use render::{RenderOptions, render_units_nix};

#[derive(Debug, clap::Parser)]
#[command(about = "Render Cargo unit graphs as composable Nix derivations")]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Debug, clap::Subcommand)]
enum Command {
    /// Render generated Nix from Cargo unit-graph JSON on stdin.
    Render(RenderArgs),
}

#[derive(Debug, clap::Args)]
struct RenderArgs {
    /// Canonical workspace root from cargo --unit-graph.
    #[arg(long, default_value = ".")]
    workspace_root: PathBuf,

    /// Cargo vendor directory used for registry/git crates.
    #[arg(long)]
    vendor_root: Option<PathBuf>,

    /// Emit CA-derivation attributes on generated units.
    #[arg(long)]
    content_addressed: bool,

    /// Salt unit identity hashes with a Rust toolchain id.
    #[arg(long)]
    toolchain_id: Option<String>,
}

fn render(args: RenderArgs) -> color_eyre::Result<()> {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input)?;
    let graph: UnitGraph = serde_json::from_str(&input)?;
    color_eyre::eyre::ensure!(
        graph.version == 1,
        "unsupported cargo unit graph version {}",
        graph.version
    );

    let rendered = render_units_nix(
        &graph,
        &RenderOptions {
            workspace_root: args.workspace_root,
            vendor_root: args.vendor_root,
            content_addressed: args.content_addressed,
            toolchain_id: args.toolchain_id,
        },
    )?;
    print!("{rendered}");

    Ok(())
}

fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;

    match Cli::parse().command {
        Command::Render(args) => render(args),
    }
}
