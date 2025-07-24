FROM registry.fedoraproject.org/fedora-toolbox:42

# gcloud repo config
COPY ../utils/google-cloud-sdk.repo /etc/yum.repos.d/google-cloud-sdk.repo 

# dnf install
COPY ./dnf_package_fedora_42 /tmp/dnf_package_fedora_42
RUN dnf -y update
RUN dnf -y install $(cat /tmp/dnf_package_fedora_42) 
RUN dnf -y clean all

# lazygit :
RUN \
	dnf -y copr enable atim/lazygit && \
	dnf -y install lazygit

# Starship :
RUN \
	dnf -y copr enable atim/starship && \
	dnf -y install starship

# ZSH :
RUN chsh -s /usr/bin/zsh

# ChezMoi :
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/bin
