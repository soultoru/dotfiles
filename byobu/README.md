# byobu

自分でカスタマイズした byobu 設定のみ管理する（byobu 自動生成ファイルは除外）。

- `.tmux.conf` … マウスホイールでのスクロール有効化（`set -g mouse on`）
- `keybindings.tmux` … prefix を `^S`（Ctrl-s）+ F12 に変更
- `backend` … tmux バックエンドを使用

## 設定ディレクトリ

byobu は `$BYOBU_CONFIG_DIR` を参照する。未設定なら `$XDG_CONFIG_HOME/byobu`（通常 `~/.config/byobu`）、それも無ければ `~/.byobu`。

## 新しいマシンへの展開

```sh
mkdir -p ~/.config/byobu
cp ~/dotfiles/byobu/.tmux.conf      ~/.config/byobu/.tmux.conf
cp ~/dotfiles/byobu/keybindings.tmux ~/.config/byobu/keybindings.tmux
cp ~/dotfiles/byobu/backend          ~/.config/byobu/backend
```

反映（byobu 起動中なら）:

```sh
tmux source-file ~/.config/byobu/.tmux.conf
```
