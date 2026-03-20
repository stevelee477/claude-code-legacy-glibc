# Alpine Claude Code

Run [Claude Code](https://claude.ai) on systems with old glibc (e.g. CentOS 7, RHEL 7, older Ubuntu) by bundling it with musl libc from Alpine Linux.

## How it works

Claude Code is a native binary linked against glibc. On systems with glibc < 2.28 it fails to start. This project uses a multi-stage Docker build to:

1. Install Claude Code inside Alpine Linux (which uses musl libc)
2. Patch the binary's RPATH with `patchelf` so it finds libs relative to itself
3. Extract the binary + musl runtime + dependencies as a portable bundle

The result is a self-contained directory that runs on any x86_64 Linux regardless of glibc version.

## Quick start

### Option 1: Download from GitHub Actions

Go to [Actions](../../actions) and download the latest `claude-code-musl-x86_64` artifact.

### Option 2: Build locally

Requires Docker with BuildKit support.

```bash
git clone https://github.com/stevelee477/alpine-claude-code.git
cd alpine-claude-code
chmod +x install.sh
./install.sh
```

### Setup

After extracting or building:

```bash
# Symlink the musl dynamic linker (one-time, requires root)
sudo ln -fs /path/to/dist/lib/ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1

# Add to PATH
export PATH="/path/to/dist/bin:$PATH"

# Run
claude
```

### Settings

The build generates a `settings.json` that disables the built-in ripgrep (a standalone musl-linked `rg` is bundled instead):

```json
{ "env": { "USE_BUILTIN_RIPGREP": "0" } }
```

Copy it to `~/.claude/settings.json` if needed.

## CI/CD

The GitHub Actions workflow:
- Builds on every push to `main`
- Runs weekly to pick up new Claude Code releases
- Uploads build artifacts
- Creates a GitHub release on each push to `main`

## License

MIT
