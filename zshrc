# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="ys"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
#plugins=(git)
plugins=(docker docker-compose git ruby rails command-not-found bundler compleat dirhistory gem git-flow npm pip direnv)

# User configuration

export PATH=$HOME/bin:/usr/local/bin:$PATH
# export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

alias grep='grep --color=always'
#export LESS='-gj10 --no-init --quit-if-one-screen -R'
export LESS='-Rgj10'
#export LESSOPEN='| /usr/share/source-highlight/src-hilite-lesspipe.sh %s'
# export LESSOPEN='| /usr/bin/source-highlight --failsafe --src-lang=%s --out-format=esc -i %s'

# Created by `pipx` on 2023-02-10 02:41:53
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=/usr/bin/vim

# dotfiles auto-update
(cd ~/dotfiles && git pull --ff-only --quiet 2>/dev/null &)

# PRレビュー自動提出のダイジェスト表示（pr-review-daily skill）
# 未読分があれば起動時に1度だけ表示し、アーカイブへ退避して既読化する
_pr_review_inbox="$HOME/.claude-figurout/pr-review-inbox.md"
if [ -s "$_pr_review_inbox" ]; then
  printf '\n\033[1;36m── PRレビュー自動提出（未読）──\033[0m\n'
  cat "$_pr_review_inbox"
  printf '\033[2m(上記はアーカイブへ退避しました: pr-review-inbox.archive.md)\033[0m\n\n'
  cat "$_pr_review_inbox" >> "$HOME/.claude-figurout/pr-review-inbox.archive.md"
  : > "$_pr_review_inbox"
fi
unset _pr_review_inbox
