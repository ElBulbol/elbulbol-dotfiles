#
# ~/.bashrc
#

[[ $- != *i* ]] && return

# ---- aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias cls='clear'
alias n='neofetch'
alias v='nvim'
alias vim='nvim'
alias s='ls -la | grep -i'          # was defined twice, kept the better one
alias q='pacman -Ss'
alias qA='yay -Ss'
alias sudo='sudo '

# ---- prompt
PS1='[\u@\h \W]\$ '

# ---- install: pacman first, fallback to AUR
i() {
  sudo pacman -S "$1"
  if [[ $? != 0 ]]; then
    read -p "Not found in pacman. Search AUR? [y/n] " ans
    [[ $ans == y ]] && yay -S "$1"
  fi
}

# ---- update: no arg = full system, with arg = single package only
u() {
  if [[ -z "$1" ]]; then
    sudo pacman -Syu && yay -Sua    # full system: pacman + AUR
  else
    if pacman -Qu "$1" &>/dev/null; then
      sudo pacman -S "$1"           # update single pacman package
    elif yay -Qu "$1" &>/dev/null; then
      yay -S "$1"                   # update single AUR package
    else
      echo "$1 is already up to date."
    fi
  fi
}

# ---- remove: pacman first, fallback to AUR
r() {
  if pacman -Q "$1" &>/dev/null; then
    sudo pacman -Rns "$1"
    if [[ $? != 0 ]]; then
      read -p "Force remove with all dependents? [y/n] " ans
      [[ $ans == y ]] && sudo pacman -Rns --cascade "$1"
    fi
  elif yay -Q "$1" &>/dev/null; then
    read -p "Found in AUR. Remove it? [y/n] " ans
    [[ $ans == y ]] && yay -Rns "$1"
  else
    echo "Package '$1' not found."
  fi
}

# ---- check if package is installed
q?() {
  if pacman -Q "$1" &>/dev/null; then
    echo "$1 is installed via pacman"
    pacman -Q "$1"
  elif yay -Q "$1" &>/dev/null; then
    echo "$1 is installed via AUR"
    yay -Q "$1"
  elif which "$1" &>/dev/null; then
    echo "$1 found in PATH at: $(which $1)"
  else
    echo "$1 is not installed."
  fi
}

# ---- recursive file search with color
sr() {
  find . -iname "*$1*" | while read -r f; do
    if [[ -d "$f" ]]; then
      echo -e "\e[1;38;5;33m$f\e[0m"
    elif [[ -x "$f" ]]; then
      echo -e "\e[1;38;5;159m$f\e[0m"
    else
      echo "$f"
    fi
  done
}

# ---- open files by type
open() {
  case "$1" in
    *.jpg|*.jpeg|*.png|*.webp|*.gif|*.bmp|*.tiff|*.tif|\
    *.svg|*.ico|*.psd|*.raw|*.cr2|*.nef|*.heic|*.heif|\
    *.JPG|*.JPEG|*.PNG|*.WEBP|*.GIF|*.BMP|*.TIFF|*.TIF)
      chafa "$1" ;;
    *.pdf|*.PDF)
      setsid zathura "$1" ;;
    *.mp4|*.mkv|*.webm|*.avi|*.mov|*.flv|*.wmv|*.m4v|\
    *.MP4|*.MKV|*.WEBM|*.AVI|*.MOV)
      mpv "$1" ;;
    *.mp3|*.flac|*.wav|*.ogg|*.m4a|*.aac|*.opus)
      mpv "$1" ;;
    *.zip|*.tar|*.tar.gz|*.tar.xz|*.rar|*.7z)
      tar tf "$1" 2>/dev/null || unzip -l "$1" ;;
    *)
      xdg-open "$1" ;;
  esac
}
#ccat command
ccat() {
  if [[ $# -eq 1 ]]; then
    cat "$1" | wl-copy && echo "Copied: $1"
  else
    local output=""
    for file in "$@"; do
      output+="
-- $(realpath "$file") --
$(cat "$file")
"
    done
    echo "$output" | wl-copy && echo "Copied $# files"
  fi
}
# ---- help
h() {
  echo "  i  <pkg>   install (pacman → AUR)"
  echo "  r  <pkg>   remove (pacman → AUR)"
  echo "  u          full system update (pacman + AUR)"
  echo "  u  <pkg>   update single package only"
  echo "  q  <pkg>   search pacman"
  echo "  qA <pkg>   search AUR"
  echo "  q? <pkg>   check if installed"
  echo "  s  <name>  search files in current dir"
  echo "  sr <name>  search files recursively"
  echo "  v  <file>  open in nvim"
  echo "  n          neofetch"
  echo "  cls        clear screen"
}

# ---- environment
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=qt5ct
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_DESKTOP=sway

# ---- PATH (deduplicated)
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.spicetify:$PATH"

# ---- sources
source "$HOME/.config/foot/prompt.sh"
. "$HOME/.local/share/../bin/env"


. "$HOME/.cargo/env"
export PATH="$HOME/.local/bin:$PATH"
