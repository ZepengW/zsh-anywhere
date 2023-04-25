# ZSH-Anywhere
One command to install Zsh and configure various plugins and themes.

## Features
- [x] Detect and Install [Zsh](https://www.zsh.org/) as un-sudo user
- [x] Deploy [Oh-My-Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [x] Configure plugins and theme (preset by author)
- [ ] Adding options for plugins and themes during deployment

## Getting Started

### Deploy quickly
```bash
sh zsh-anywhere.sh
```

### Deploy your own configuration
1. Fork from this repo
2. Modify the config file ./configs/.zshrc in configs as you wish
3. `sh zsh-anywhere.sh`


## Q&A
1. When you encounter network problems.
This project is downloaded from the China mirror by default. If you find access difficulties in regions outside of China, please execute the command: `sh zsh-anywhere.sh 0 `