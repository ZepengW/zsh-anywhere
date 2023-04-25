#!/bin/bash
NUM_STEP=1
printf "\033[1;32m Step[1/%d] \033[0m \033[5;33m Check and Install Zsh \033[0m \n" $NUM_STEP
if ! command -v zsh &> /dev/null
then
    echo "zsh not found. Installing zsh..."
    wget -c -O zsh.tar.xz -P ./tmp https://sourceforge.net/projects/zsh/files/latest/download
    cd tmp
    tar -xf zsh.tar.xz
    cd zsh-*
    ./configure --prefix=$HOME/.local
    make && make install
    source ~/.profile
    echo "zsh installed successfully!"
else
    echo "zsh is already installed"
fi

