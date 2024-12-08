#!/bin/bash

# Setup development environment for GhostOS
set -e

# Base development tools
BASE_TOOLS=(
    gcc
    g++
    clang
    llvm
    make
    cmake
    ninja-build
    gdb
    lldb
    valgrind
    strace
    ltrace
    perf
)

# Version control
VCS_TOOLS=(
    git
    git-lfs
    subversion
    mercurial
)

# Build essentials
BUILD_TOOLS=(
    autoconf
    automake
    libtool
    pkg-config
    binutils
    bison
    flex
    yacc
    nasm
    as31
    fasm
)

# Kernel development
KERNEL_TOOLS=(
    linux-headers-$(uname -r)
    kernel-package
    libncurses5-dev
    libssl-dev
    bc
    kmod
    cpio
)

# Scripting languages
SCRIPT_LANGS=(
    python3
    python3-pip
    python3-venv
    ruby
    nodejs
    npm
    lua5.4
    perl
)

# Modern languages
MODERN_LANGS=(
    golang
    rustc
    cargo
    default-jdk
    kotlin
    scala
)

# Development environments
DEV_ENVS=(
    vim
    neovim
    emacs
    tmux
    screen
    vscode
)

# Documentation
DOC_TOOLS=(
    doxygen
    graphviz
    sphinx-doc
    pandoc
    texlive
)

# Testing tools
TEST_TOOLS=(
    cppunit
    googletest
    pytest
    selenium
    jmeter
)

# Container tools
CONTAINER_TOOLS=(
    docker-ce
    docker-compose
    podman
    buildah
    skopeo
)

# Database development
DB_TOOLS=(
    postgresql
    mysql-server
    sqlite3
    redis
    mongodb
)

# Install functions
install_packages() {
    echo "Installing $1 tools..."
    sudo apt-get install -y "${@:2}"
}

setup_python() {
    echo "Setting up Python development environment..."
    python3 -m pip install --upgrade pip
    python3 -m pip install \
        ipython \
        jupyter \
        numpy \
        pandas \
        scikit-learn \
        tensorflow \
        torch \
        matplotlib \
        pylint \
        black \
        mypy
}

setup_rust() {
    echo "Setting up Rust development environment..."
    rustup default stable
    rustup component add rls rust-analysis rust-src
    cargo install \
        cargo-edit \
        cargo-watch \
        cargo-audit \
        cargo-outdated
}

setup_node() {
    echo "Setting up Node.js development environment..."
    npm install -g \
        typescript \
        ts-node \
        nodemon \
        eslint \
        prettier \
        webpack \
        yarn
}

setup_vim() {
    echo "Setting up Vim/Neovim development environment..."
    # Install vim-plug
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    
    # Install neovim plugins
    curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

setup_vscode() {
    echo "Setting up VSCode extensions..."
    code --install-extension ms-vscode.cpptools
    code --install-extension rust-lang.rust-analyzer
    code --install-extension ms-python.python
    code --install-extension golang.go
    code --install-extension dbaeumer.vscode-eslint
    code --install-extension esbenp.prettier-vscode
    code --install-extension ms-vscode.cmake-tools
    code --install-extension ms-azuretools.vscode-docker
}

# Main installation
echo "Setting up GhostOS development environment..."

# Update package list
sudo apt-get update

# Install all package groups
install_packages "Base development" "${BASE_TOOLS[@]}"
install_packages "Version control" "${VCS_TOOLS[@]}"
install_packages "Build" "${BUILD_TOOLS[@]}"
install_packages "Kernel development" "${KERNEL_TOOLS[@]}"
install_packages "Scripting languages" "${SCRIPT_LANGS[@]}"
install_packages "Modern languages" "${MODERN_LANGS[@]}"
install_packages "Development environments" "${DEV_ENVS[@]}"
install_packages "Documentation" "${DOC_TOOLS[@]}"
install_packages "Testing" "${TEST_TOOLS[@]}"
install_packages "Container" "${CONTAINER_TOOLS[@]}"
install_packages "Database" "${DB_TOOLS[@]}"

# Setup language-specific environments
setup_python
setup_rust
setup_node
setup_vim
setup_vscode

echo "Development environment setup complete!"
