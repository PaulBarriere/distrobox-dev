# Distrobox Dev Env

This repository contains the configuration for my personal development environment, built upon [Distrobox](https://distrobox.it/). The main goal is to quickly and reliably recreate a complete development environment on any machine running Podman or Docker.

As a primary user of Fedora Silverblue, this project allows me to maintain a minimal and immutable base OS while having a rich, customized development environment inside a container.

## Context

I am a developer who values the robustness of Fedora Silverblue. For my development workflow, I rely on:

*   **Distrobox** to create development containers that seamlessly integrate with the host.
*   **Neovim** with the **LazyVim** configuration as my primary code editor for a modern and efficient development experience.
*   **Nerd Fonts** for optimal display of icons and symbols in my terminal and editor.

This repository centralizes the configuration of this environment to make it easily deployable.

## Project Structure

```
.
├── Containerfile
├── dnf_package_fedora_42
├── README.md
└── utils
    └── google-cloud-sdk.repo
```

*   `Containerfile`: The build file for the image, based on `fedora-toolbox:42`.
*   `dnf_package_fedora_42`: The list of DNF packages to be installed in the image.
*   **utils/**: Contains utility files shared across different configurations.
*   **README.md**: This file.

## Development Environment Setup (from Fedora Silverblue)

Here are the steps to set up the complete development environment from a fresh Fedora Silverblue installation.

### 1. Prerequisites: Install Distrobox

On Fedora Silverblue, `distrobox` is usually pre-installed. If not, you can install it with the following command:
```bash
rpm-ostree install distrobox
```
Follow the instructions and reboot your machine to apply the changes.

### 2. Install Nerd Fonts

LazyVim and other command-line tools use icons that require a "Nerd Font". We will install the "Hack" font.

```bash
# Download the font
curl -o /tmp/Hack.zip -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Hack.zip

# Create local font directory and unzip
mkdir -p ~/.local/share/fonts
unzip -d ~/.local/share/fonts /tmp/Hack.zip

# Update the font cache
fc-cache -fv

# Clean up
rm /tmp/Hack.zip
```

Natively the terminal of the Sylverblue (pystix) will use the fonts.

### 3. Clone This Repository

Clone this repository into a directory of your choice on your host machine.
```bash
git clone https://github.com/PaulBarriere/distrobox-dev.git ~/dev_config
cd ~/dev_config
```

### 4. Put the distrobox configuration file :

Create a symbolic link from the distrobox config file to the `.config` path :
```sh
mkdir ~/.config/distrobox
ln -s ./distrobox.conf ~/.config/distrobox/distrobox.conf
```

### 5. Build the Distrobox Image

Build the image :
```bash
podman build --pull="always" -t distrobox-dev .
```

### 6. Create and Launch the Distrobox Container

Once the image is built, you can create a Distrobox container from it.
```bash
distrobox create --image distrobox-dev --name distro-dev
```

To enter your new development environment:
```bash
distrobox enter distro-dev
```

### 7. Post-Installation Configuration (inside the Distrobox)

Once inside the distrobox there are two steps needed :

- Bring your keepass file.
- Use chezmoi to import the configuration files.

This environment includes `chezmoi` to manage your configuration files (dotfiles). Initialize it with your dotfiles repository.
```bash
chezmoi init <YOUR_DOTFILES_REPO>
chezmoi apply
```

## Image Contents

For now, there is only one image for my dev containers.
The base image is `registry.fedoraproject.org/fedora-toolbox:42`.

### Installed Packages and Configurations:

*   **Google Cloud SDK**: The repository is configured for an easy installation of `gcloud` tools.
*   **DNF Packages**: A list of packages is installed from the `dnf_package_fedora_42` file, including essential development tools.
*   **Lazygit**: A simple terminal UI for Git, installed via COPR.
*   **Starship**: A customizable cross-shell prompt.
*   **ZSH**: Set as the default shell for the user.
*   **ChezMoi**: A tool to manage your configuration files (dotfiles).
*   **Go**: Golang programming langage.
*   **keepassxc**: For handling ".kdbx" files.

## Next steps:

* Create a modular way of building an image. All dev containers does not need
  golang, terraform, gcloud, ...
* Use buildah to build and remove Containerfile for bash scripts.
