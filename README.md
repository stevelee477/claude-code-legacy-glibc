# Claude Code for Legacy Linux

Run [Claude Code](https://docs.anthropic.com/en/docs/claude-code) on Linux systems with old glibc (CentOS 7, RHEL 7, older Ubuntu, etc.) by bundling it with musl libc from Alpine Linux.

## Why

Claude Code ships as a native binary linked against glibc >= 2.28. On older enterprise Linux systems it fails to start with errors like:

```
/lib64/libstdc++.so.6: version `GLIBCXX_3.4.26' not found
```
```
Illegal instruction (core dumped)
```

This also affects the **[Claude Code VS Code extension](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code)**, which bundles the same native binary and requires it to function. If your system's glibc is too old, neither the CLI nor the VS Code extension will work.

### glibc compatibility

| Distro | glibc | Native binary status |
|---|---|---|
| Ubuntu 20.04+ | 2.31+ | Officially supported |
| Debian 10+ | 2.28+ | Supported |
| RHEL 8 | 2.28 | Supported (v2.1.78+) |
| Amazon Linux 2 | 2.26 | Supported (v2.1.73+) |
| **CentOS 7** | **2.17** | **Not supported — use this project** |
| **RHEL 7** | **2.17** | **Not supported — use this project** |

Check your glibc version:

```bash
ldd --version | head -1
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/stevelee477/claude-code-legacy-glibc/main/install.sh | bash
```

This will:
- Download the latest release from GitHub
- Extract to `~/.local/share/claude-code`
- Symlink the musl dynamic linker to `/lib/` (**requires sudo**)
- Prompt you to add it to your PATH

To update, just run the same command again.

> **Note:** The install requires `sudo` to create a symlink at `/lib/ld-musl-x86_64.so.1`. This is necessary because the Linux kernel's ELF loader looks for the dynamic linker (interpreter) at an absolute path embedded in the binary, and musl's default path is `/lib/ld-musl-x86_64.so.1`. If you don't have sudo access, ask your admin to run:
> ```bash
> sudo ln -fs ~/.local/share/claude-code/lib/ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1
> ```

## VS Code integration

The Claude Code VS Code extension uses a native binary under the hood. On legacy systems, you can point the extension to this musl-built binary via the `claudeCode.claudeProcessWrapper` setting.

Add this to your VS Code `settings.json`:

```json
{
  "claudeCode.claudeProcessWrapper": "/path/to/claude-code/bin/claude"
}
```

For example, if you used the default install path:

```json
{
  "claudeCode.claudeProcessWrapper": "~/.local/share/claude-code/bin/claude"
}
```

> **Note:** The `claudeProcessWrapper` setting does not support variable substitution (e.g. `${env:HOME}`). Use an absolute path.

## How it works

This project:

1. Installs Claude Code inside Alpine Linux (musl libc) via Docker
2. Patches the binary's RPATH with `patchelf` so it finds libs relative to itself
3. Extracts the binary + musl runtime + libstdc++ as a portable bundle

The GitHub Actions workflow checks for new Claude Code releases every 6 hours and automatically builds & publishes a new release.

## Build locally

```bash
git clone https://github.com/stevelee477/claude-code-legacy-glibc.git
cd claude-code-legacy-glibc
DOCKER_BUILDKIT=1 docker build --progress=plain --output type=local,dest=./dist .
sudo ln -fs "$(pwd)/dist/lib/ld-musl-x86_64.so.1" /lib/ld-musl-x86_64.so.1
export PATH="$(pwd)/dist/bin:$PATH"
claude
```

## Configuration

The build includes a `settings.json` that disables built-in ripgrep (a musl-linked `rg` is bundled instead). The install script copies it to `~/.claude/settings.json` if that file doesn't exist yet.

## License

MIT
