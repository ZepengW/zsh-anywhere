#!/bin/bash
NUM_STEP=4
CN=${1:-1} # flag to use mirror address of China
SOURCE_DIR=`pwd`

printf "\033[1;32m Step[1/%d] \033[0m \033[5;33m Check and Install Zsh \033[0m \n" $NUM_STEP
if ! command -v zsh &> /dev/null
then
    echo "zsh not found. Installing zsh..."
    mkdir tmp
    if [ $CN -eq 1 ]
    then
    wget -c -O ./tmp/zsh.tar.xz https://sourceforge.net/projects/zsh/files/latest/download
    else
    wget -c -O ./tmp/zsh.tar.xz https://sourceforge.net/projects/zsh/files/latest/download
    fi
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

printf "\033[1;32m Step[2/%d] \033[0m \033[5;33m Install oh-my-zsh \033[0m \n" $NUM_STEP
if [ ! -d "~/.oh-my-zsh" ]; then
    if [ $CN == '1' ]
    then
    git clone https://gitee.com/oliverck/ohmyzsh.git ~/.oh-my-zsh
    else
    git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
    fi
else
    echo "oh-my-zsh is already installed ( | rm -r ~/.oh-my-zsh | if you want to re-deploy)"
fi

printf "\033[1;32m Step[3/%d] \033[0m \033[5;33m Install plugins of ZSH \033[0m \n" $NUM_STEP
cd ~/.oh-my-zsh/plugins
printf "\033[1;32m Install plugin: zsh-autosuggestions \033[0m \n"
if [ ! -d "./zsh-autosuggestions" ]; then
    if [ $CN == '1' ]
    then
    git clone https://gitee.com/oliverck/zsh-autosuggestions.git
    else
    git clone https://github.com/zsh-users/zsh-autosuggestions.git
    fi
else
    echo "zsh-autosuggestions is already installed"
fi


printf "\033[1;32m Step[4/%d] \033[0m \033[5;33m Config .zshrc \033[0m \n" $NUM_STEP
cd $SOURCE_DIR
cp ./configs/.zshrc ~/


printf "\033[1;32m zsh-anywhere install finish \033[0m \n"
printf "\033[1;32m The default shell for the user is "
printf `echo $SHELL`
printf "\033[0m \n"

zsh
