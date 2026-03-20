# Claude Code for Legacy Linux

Run [Claude Code](https://docs.anthropic.com/en/docs/claude-code) on Linux systems with old glibc (CentOS 7, RHEL 7, older Ubuntu, etc.) by bundling it with musl libc from Alpine Linux.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/stevelee477/claude-code-legacy-linux/main/install.sh | bash
```

This will:
- Download the latest release from GitHub
- Extract to `~/.local/share/claude-code`
- Symlink the musl dynamic linker
- Prompt you to add it to your PATH

To update, just run the same command again.

## How it works

Claude Code ships as a native binary linked against glibc >= 2.28. On older systems it fails to start. This project:

1. Installs Claude Code inside Alpine Linux (musl libc) via Docker
2. Patches the binary's RPATH with `patchelf` so it finds libs relative to itself
3. Extracts the binary + musl runtime + libstdc++ as a portable bundle

The GitHub Actions workflow checks for new Claude Code releases every 6 hours and automatically builds & publishes a new release.

## Build locally

```bash
git clone https://github.com/stevelee477/claude-code-legacy-linux.git
cd claude-code-legacy-linux
DOCKER_BUILDKIT=1 docker build --progress=plain --output type=local,dest=./dist .
sudo ln -fs "$(pwd)/dist/lib/ld-musl-x86_64.so.1" /lib/ld-musl-x86_64.so.1
export PATH="$(pwd)/dist/bin:$PATH"
claude
```

## Configuration

The build includes a `settings.json` that disables built-in ripgrep (a musl-linked `rg` is bundled instead). The install script copies it to `~/.claude/settings.json` if that file doesn't exist yet.

## License

MIT
