#!/usr/bin/env bash

set -e

HELM_VERSION="v3.19.0"
INSTALL_DIR="$HOME/.local/bin"

# Make Helm available to this shell and future Git Bash sessions.
case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *) export PATH="$INSTALL_DIR:$PATH" ;;
esac

if [[ -f "$HOME/.bashrc" ]] && ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
    printf '\n# Helm installed by Devops_kubernets\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.bashrc"
elif [[ ! -f "$HOME/.bashrc" ]]; then
    printf '# Helm installed by Devops_kubernets\nexport PATH="$HOME/.local/bin:$PATH"\n' > "$HOME/.bashrc"
fi

echo "Checking if Helm is already installed..."

if command -v helm >/dev/null 2>&1; then
    echo "Helm is already installed:"
    helm version
    exit 0
fi

echo "Helm not found."
echo "Installing Helm ${HELM_VERSION}..."

mkdir -p "$INSTALL_DIR"

UNAME="$(uname -s)"
ARCH="$(uname -m)"

# Convert architecture
case "$ARCH" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# --------------------------------------------------
# Windows / Git Bash
# --------------------------------------------------

if [[ "$UNAME" == MINGW* || "$UNAME" == MSYS* || "$UNAME" == CYGWIN* ]]; then

    OS="windows"
    PACKAGE="zip"

    FILE="helm-${HELM_VERSION}-${OS}-${ARCH}.${PACKAGE}"
    URL="https://get.helm.sh/${FILE}"

    echo "Detected Windows / Git Bash"
    echo "Downloading: $URL"

    curl -fsSL "$URL" -o "/tmp/$FILE"

    echo "Extracting Helm..."

    unzip -q "/tmp/$FILE" -d /tmp/helm-install

    mv "/tmp/helm-install/windows-${ARCH}/helm.exe" \
       "$INSTALL_DIR/helm.exe"

    rm -rf "/tmp/$FILE" "/tmp/helm-install"

# --------------------------------------------------
# Linux / macOS
# --------------------------------------------------

else

    case "$UNAME" in
        Linux*)
            OS="linux"
            ;;
        Darwin*)
            OS="darwin"
            ;;
        *)
            echo "Unsupported operating system: $UNAME"
            exit 1
            ;;
    esac

    FILE="helm-${HELM_VERSION}-${OS}-${ARCH}.tar.gz"
    URL="https://get.helm.sh/${FILE}"

    echo "Detected OS: $OS"
    echo "Downloading: $URL"

    curl -fsSL "$URL" -o "/tmp/$FILE"

    echo "Extracting Helm..."

    mkdir -p /tmp/helm-install

    tar -xzf "/tmp/$FILE" -C /tmp/helm-install

    mv "/tmp/helm-install/${OS}-${ARCH}/helm" \
       "$INSTALL_DIR/helm"

    chmod +x "$INSTALL_DIR/helm"

    rm -rf "/tmp/$FILE" "/tmp/helm-install"

fi

echo
echo "Helm installation completed!"
echo

helm version