#!/bin/bash

echo 'installing paperbennis personal dotfiles'
cd dotfiles || exit 1
instantinstall rsync
command -v rsync &>/dev/null || exit 1
if command -v termux-setup-storage; then
    rsync --exclude-from='../termuxignore.txt' -a -r ./ ~/
else
    rsync -a -r ./ ~/
fi
echo "finished installing paperbenni's dotfiles"
