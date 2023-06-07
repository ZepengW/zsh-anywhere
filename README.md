# ZSH-Anywhere
One command to install Zsh and configure various plugins and themes.

## Features
- [x] Detect and Install [Zsh](https://www.zsh.org/) as un-sudo user
- [x] Deploy [Oh-My-Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [x] Configure plugins and theme (preset by author)
- [ ] Adding options for plugins and themes during deployment

## Getting Started

### Requirements
- `git`
- `zsh` (optional)

If you don't have permission to install `zsh` on your system, our script will automatically install `zsh` to your home path.

### Deploy quickly
```bash
git clone https://github.com/oliverck/zsh-anywhere.git
cd zsh-anywhere
sh zsh-anywhere.sh
```

### Deploy your own configuration
1. Fork from this repo
2. Modify the config file ./configs/.zshrc in configs as you wish
3. `sh zsh-anywhere.sh`


## Q&A
__When you encounter network problems.__

This project is downloaded from the China mirror by default. If you find access difficulties in regions outside of China, please execute the command: `sh zsh-anywhere.sh 0 `


## Stargazers over time

[![Stargazers over time](https://starchart.cc/oliverck/zsh-anywhere.svg)](https://starchart.cc/oliverck/zsh-anywhere)
