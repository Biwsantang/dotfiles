#/bin/bash

# check if this Ubuntu
if [ ! -f /etc/os-release ] || ! grep -q "Ubuntu" /etc/os-release; then
    echo "This script is designed for Ubuntu. Exiting."
    exit 1
fi

REPO_URL="https://github.com/biwsantang/dotfiles.git"
REPO_BRANCH="ubuntu"
DOTFILES_DIR="$HOME/.dotfiles"

# Check if dotfiles directory exists and is the correct repository
if [ ! -d "$DOTFILES_DIR" ]; then
    # Ensure git is installed first
    if ! command -v git &> /dev/null; then
        sudo apt update
        sudo apt install -y git
    fi
    
    # Clone the repository
    git clone -b "$REPO_BRANCH" "$REPO_URL" "$DOTFILES_DIR" || exit
else
    # Check if the existing directory is the correct repository
    cd "$DOTFILES_DIR" || {
        echo "Error: Could not change to dotfiles directory"
        echo "Please check if the directory exists and you have permissions"
        exit 1
    }
    
    # Verify the remote URL matches the expected repository
    if ! git remote get-url origin | grep -q "$REPO_URL"; then
        echo "Error: ~/.dotfiles contains a different repository"
        exit 1
    fi
    
    # Fetch and update the repository
    git fetch origin "$REPO_BRANCH" || exit
    git checkout "$REPO_BRANCH" || exit
    git pull origin "$REPO_BRANCH" || exit
fi

sudo apt update

# check install apt package if it not already installed

packages=(
    zsh
    stow
    git
    jq
    neovim
    fzf
    eza
    tmux
)

for pkg in "${packages[@]}"; do
    if ! dpkg -l | grep -q "$pkg"; then
        sudo apt install -y "$pkg"
    else
        echo "$pkg is already installed. Skipping."
    fi
done

# check if zplug is already installed
if [ ! -d "$HOME/.zplug" ]; then
    curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
else
    echo "zplug is already installed. Skipping."
fi

# check if starship is already installed
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    echo "Starship prompt is already installed. Skipping."
fi

if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(which zsh)" ]; then
    # Change the default login shell to zsh
    sudo chsh -s "$(which zsh)" "$USER"
    echo "Changed default login shell to zsh"
else
    echo "Default login shell is already zsh. Skipping."
fi

stow nvim
stow zsh

add_source_if_not_exists() {
    if ! grep -q "$1" ~/.zshrc; then
        echo "$1" >> ~/.zshrc
    fi
}

source_lines=(
    "source ~/.config/zsh/alias.sh"
    "source ~/.config/zsh/rc.sh"
    "source ~/.config/zsh/prompt.sh"
    "source ~/.config/zplug/plugin.sh"
)

for line in "${source_lines[@]}"; do
    if ! grep -q "$line" ~/.zshrc; then
        echo "$line" >> ~/.zshrc
    fi
done