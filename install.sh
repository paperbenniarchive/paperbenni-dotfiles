#!/bin/bash

if ! [ -e ~/.zshrc ]
then
    touch ~/.zshrc
fi

if ! grep -q paperbenni-dotfiles ~/.zshrc
then
    echo "installing zsh"
    echo 'source ~/workspace/paperbenni-dotfiles/zsh.sh'
fi
