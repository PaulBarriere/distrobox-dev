FROM registry.fedoraproject.org/fedora-toolbox:44

# Which development environment to build (see brewfiles/)
ARG DEV_ENV=work_edf
# Must match your UID on the host so you can use brew inside the distrobox
ARG USER_UID=1000

# Extra CA certificates (e.g. corporate proxy doing TLS interception).
# Put them in certs/ before building, this folder is not versioned.
COPY certs/ /tmp/certs/
RUN \
	find /tmp/certs -name '*.p11-kit' -exec cp {} /etc/pki/ca-trust/source/ \; && \
	find /tmp/certs \( -name '*.crt' -o -name '*.pem' \) -exec cp {} /etc/pki/ca-trust/source/anchors/ \; && \
	update-ca-trust && \
	rm -rf /tmp/certs

# gcloud repo config
COPY utils/google-cloud-sdk.repo /etc/yum.repos.d/google-cloud-sdk.repo

# System packages (dnf)
# EDF proxy workarounds:
# - zchunk disabled: it relies on HTTP range requests, not supported by the proxy
# - HTTPS mirrors only: the proxy rejects authentication on plain HTTP (407)
# - openh264 repo disabled: only served over plain HTTP
COPY dnf_packages /tmp/dnf_packages
RUN \
	echo "zchunk=False" >> /etc/dnf/dnf.conf && \
	sed -i -E 's|^(metalink=.*)$|\1\&protocol=https|' /etc/yum.repos.d/fedora*.repo && \
	sed -i 's/^enabled=1/enabled=0/' /etc/yum.repos.d/fedora-cisco-openh264.repo && \
	dnf -y update && \
	dnf -y install $(cat /tmp/dnf_packages) && \
	dnf -y clean all

# Homebrew : installed by a temporary user owning UID ${USER_UID}, deleted
# afterwards so distrobox can create your own user with the same UID.
RUN \
	useradd --uid ${USER_UID} --create-home --home-dir /home/linuxbrew linuxbrew && \
	mkdir -p /home/linuxbrew/.linuxbrew/bin && \
	git clone --depth 1 https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew/Homebrew && \
	ln -s ../Homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew && \
	chown -R linuxbrew:linuxbrew /home/linuxbrew

# Brew packages
COPY brewfiles/${DEV_ENV}.Brewfile /tmp/Brewfile
USER linuxbrew
# One download at a time: the EDF proxy drops concurrent / large downloads
ENV HOMEBREW_NO_AUTO_UPDATE=1 \
	HOMEBREW_NO_ANALYTICS=1 \
	HOMEBREW_DOWNLOAD_CONCURRENCY=1
# Third-party taps must be trusted explicitly
RUN \
	for tap in $(sed -n 's/^tap "\([^"]*\)".*/\1/p' /tmp/Brewfile); do \
		/home/linuxbrew/.linuxbrew/bin/brew tap "$tap" && \
		/home/linuxbrew/.linuxbrew/bin/brew trust "$tap"; \
	done
RUN \
	/home/linuxbrew/.linuxbrew/bin/brew bundle install --file=/tmp/Brewfile && \
	/home/linuxbrew/.linuxbrew/bin/brew cleanup --prune=all && \
	rm -rf /home/linuxbrew/.cache
USER root
RUN userdel linuxbrew

# Brew in every login shell. No auto-update: the image is the source of truth,
# update by rebuilding it.
RUN printf '%s\n' \
	'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' \
	'export HOMEBREW_NO_AUTO_UPDATE=1' \
	> /etc/profile.d/brew.sh

# podman runs on the host (distrobox-host-exec is provided by distrobox at runtime)
RUN ln -s /usr/bin/distrobox-host-exec /usr/local/bin/podman
