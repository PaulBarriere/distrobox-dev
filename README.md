# Distrobox Dev Env

This repository contains the configuration for my personal development environment, built upon [Distrobox](https://distrobox.it/). The main goal is to quickly and reliably recreate a complete development environment on any machine running Podman or Docker.

As a primary user of Fedora Silverblue, this project allows me to maintain a minimal and immutable base OS while having a rich, customized development environment inside a container.

## Philosophy

*   **The host knows nothing.** Every dev tool lives in the image. Nothing is installed on the host besides Distrobox and fonts.
*   **One image = one development environment.** Each development environment (e.g. `work_edf`) has its own image and its own container, with its own tool versions, side by side.
*   **The image is disposable, the home is not.** The container home lives on the host (`~/distrobox_homes/<container name>`, see `distrobox.conf`). To update anything: rebuild the image and recreate the container, nothing is lost.

## Context

For my development workflow, I rely on:

*   **Distrobox** to create development containers that seamlessly integrate with the host.
*   **Homebrew** to install dev tools inside the image, declared in a `Brewfile` per development environment.
*   **Neovim** with the **LazyVim** configuration as my primary code editor.
*   **Nerd Fonts** for optimal display of icons and symbols in my terminal and editor.
*   **chezmoi** to manage my dotfiles, with secrets stored in **KeePassXC**.

## Project Structure

```
.
├── brewfiles
│   └── work_edf.Brewfile
├── certs
├── Containerfile
├── distrobox.conf
├── dnf_packages
├── README.md
└── utils
    └── google-cloud-sdk.repo
```

*   `Containerfile`: The build file for the image, based on `fedora-toolbox:44`. The development environment to build is selected with `--build-arg DEV_ENV=<name>`.
*   `dnf_packages`: System packages installed with DNF (shell, system libraries, GUI apps, gcloud, Homebrew requirements).
*   `brewfiles/<dev env>.Brewfile`: Dev tools installed with Homebrew for a given development environment.
*   `certs/`: Extra CA certificates added to the image (not versioned, see step 4).
*   `distrobox.conf`: Distrobox configuration (one home per container on the host).
*   `utils/`: Repository files used by the build.

## Development Environment Setup (from Fedora Silverblue)

### 1. Prerequisites: Install Distrobox

On Fedora Silverblue, `distrobox` is usually pre-installed. If not:
```bash
rpm-ostree install distrobox
```
Then reboot your machine to apply the changes.

### 2. Install Nerd Fonts

LazyVim and other command-line tools use icons that require a "Nerd Font". We will install the "Hack" font.

```bash
curl -o /tmp/Hack.zip -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Hack.zip
mkdir -p ~/.local/share/fonts
unzip -d ~/.local/share/fonts /tmp/Hack.zip
fc-cache -fv
rm /tmp/Hack.zip
```

The default Silverblue terminal (Ptyxis) will pick up the font.

### 3. Clone This Repository

```bash
git clone https://github.com/PaulBarriere/distrobox-dev.git ~/dev_config
cd ~/dev_config
```

### 4. Add Corporate CA Certificates (behind a TLS-intercepting proxy only)

Behind a corporate proxy doing TLS interception (e.g. at EDF), the build fails with `SSL certificate problem: self-signed certificate in certificate chain`. Copy the corporate CA certificates (`.p11-kit`, `.crt` or `.pem`) into `certs/`, they are added to the image trust store:

```bash
cp /etc/pki/ca-trust/source/*EDF*.p11-kit certs/
```

`certs/` is ignored by git.

### 5. Link the Distrobox Configuration File

```sh
mkdir -p ~/.config/distrobox
ln -s "$PWD/distrobox.conf" ~/.config/distrobox/distrobox.conf
```

### 6. Build the Image

```bash
podman build --pull=always --no-cache --build-arg DEV_ENV=work_edf -t work_edf .
```

If your UID on the host is not `1000` (check with `id -u`), add `--build-arg USER_UID=$(id -u)`, otherwise you won't be able to use `brew` inside the container.

### 7. Create and Enter the Container

```bash
SHELL=/usr/bin/zsh distrobox create --image work_edf --name work_edf
distrobox enter work_edf
```

### 8. Post-Installation Configuration (inside the Distrobox)

- Bring your KeePass database (the dotfiles templates read their secrets from it).
- Import your dotfiles with chezmoi:
  ```bash
  chezmoi init <YOUR_DOTFILES_REPO>
  chezmoi apply
  ```

## Updating

Rebuild the image, then recreate the container **with the same name** to keep the same home:

```bash
podman build --pull=always --no-cache --build-arg DEV_ENV=work_edf -t work_edf .
distrobox rm -f work_edf    # never --rm-home: it would delete the home
SHELL=/usr/bin/zsh distrobox create --image work_edf --name work_edf
```

Things to know:

*   `SHELL=/usr/bin/zsh` is required: distrobox gives your user the host shell (bash on Silverblue) when the container is first started, and never changes it afterwards.
*   `--no-cache` is required: without it, podman reuses the cached layers and nothing gets updated unless `dnf_packages` or the `Brewfile` changed.
*   Anything installed by hand in the container (`brew install`, `dnf install`) is lost on recreation. Add it to the `Brewfile` or `dnf_packages` instead. Homebrew auto-update is disabled for the same reason.
*   A new container name means a new, empty home.
*   What tools download into the home is kept and **not** updated by a rebuild: Neovim plugins (`~/.local/share/nvim`), uv Python versions, Go toolchains, global npm packages... Update them with the tool itself (`:Lazy update`, `uv python upgrade`, ...).

## Adding a New Development Environment

1.  Create `brewfiles/<name>.Brewfile`.
2.  Build with `--build-arg DEV_ENV=<name> -t <name>`.
3.  Create the container with `SHELL=/usr/bin/zsh distrobox create --image <name> --name <name>`.

## Image Contents (`work_edf`)

Base image: `registry.fedoraproject.org/fedora-toolbox:44`.

*   **DNF**: zsh, Google Cloud CLI, KeePassXC, pinentry, go, Homebrew requirements (gcc, git, curl, procps-ng, file).
*   **podman**: runs the host podman through `distrobox-host-exec`.
*   **Homebrew**: neovim, ripgrep, fd, starship, zoxide, fzf, bat, lazygit, glab, chezmoi, node, uv, terraform.

## Next Steps

*   Use buildah to build and replace the Containerfile with bash scripts.
