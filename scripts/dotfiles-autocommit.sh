#!/bin/bash
# Auto-commit dotfiles when Claude edits a symlinked file

input=$(cat)
file=$(echo "$input" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")
real=$(realpath "$file" 2>/dev/null || echo "")
dotfiles="$HOME/dotfiles"

if [[ -n "$real" && "$real" == "$dotfiles"/* ]]; then
    git -C "$dotfiles" add -A
    git -C "$dotfiles" diff --cached --quiet && exit 0
    git -C "$dotfiles" commit -m "auto: update" --quiet
    git -C "$dotfiles" push --quiet 2>/dev/null
fi
exit 0
