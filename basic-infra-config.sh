#!/usr/bin/env bash

mkdir -p ~/workspace/tools 

sudo apt-get update && sudo apt -y install git zsh neovim net-tools wget tree x11-apps xsel ripgrep aria2

# install oh-my-zsh and change the shell to zsh for the user blackhawk
cd /tmp && wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh && sh install.sh --unattended && sudo chsh --shell /bin/zsh $USER

# enable the zsh plugins & set theme
sed -i s/plugins=\(git\)/plugins=\(git\ z\ vi-mode\)/g ~/.zshrc
sed -i 's/ZSH_THEME=".*/ZSH_THEME="blinks"/g' ~/.zshrc


# set-up jj as an alternative key to ESC in the zsh command line
sed -i s/bindkey\ -v/bindkey\ -v\\nbindkey\ jj\ vi-cmd-mode/  ~/.oh-my-zsh/plugins/vi-mode/vi-mode.plugin.zsh

# fzf -- mainly for the stylish reverse search
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all 

# install nvim, copy the vimrc from the github and set-up an alias to it.
mkdir -p ~/.config/nvim/ && cd ~/.config/nvim/ && wget https://raw.githubusercontent.com/benny-sec/infra-config/main/vim/init.vim
echo -e "alias vim=nvim\nalias ll='ls -alt'">~/.oh-my-zsh/custom/aliases.zsh

# fix locales
sudo locale-gen en_US && sudo locale-gen en_US.UTF-8 && export LC_ALL="en_US.UTF-8" && sudo update-locale LC_ALL=en_US.UTF-8 && . /etc/default/locale

# Clone the infra-config repo and dump the commands for a few quick set-up (e.g Atlassian servers )
[[ ! -d ~/workspace/tools/infra-config ]] && git clone --depth 1 https://github.com/benny-sec/gcp-infra-config ~/workspace/tools/infra-config    

# set-up tmux
cd
git clone https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cp .tmux/.tmux.conf.local .
sed -i s/"#set -g mode-keys vi"/"set -g mode-keys vi"/g .tmux.conf.local
sed -i s/"#set -g history-limit 10000"/"set -g history-limit 100000"/g .tmux.conf.local
sed -i s/"tmux_conf_copy_to_os_clipboard=false"/"tmux_conf_copy_to_os_clipboard=true"/g .tmux.conf.local
sed -i s/"#set -g mouse on"/"set -g mouse on"/g .tmux.conf.local
sed -i s%"#set -g @plugin 'tmux-plugins/tmux-resurrect'"%" set -g @plugin 'tmux-plugins/tmux-resurrect'"%g .tmux.conf.local

# Default git configuration
git config --global user.email "bennyyjacob@gmail.com"
git config --global user.name "Benny Jacob"

### MUST REVISIT ###
# The below settings are mostly workaround and needs to be reviewed in future.

# sudo -E doesn't seem to honour aliases on Ubuntu 20.04, for e.g. invoke nvim when using sudo vim  
alias sudo='sudo '

# System wide nvim configuration is to be identified. For now copying the settings to root
sudo mkdir -p /root/.config/nvim && sudo cp /home/blackhawk/.config/nvim/init.vim /root/.config/nvim/

# install vim-plug; ideally the default packager manager in neovim should suffice
# but for now couldn't get fzf.vim working with the default package manager
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
nvim --headless +PlugInstall +qall
# mapping of menu key to backspace and Scroll lock to Casps Lock
# xmodmap -e "keycode 135 = BackSpace" -e "keycode 78 = Caps_Lock"


