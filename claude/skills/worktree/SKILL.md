---
name: worktree
description: Manage git worktrees with isolated PostgreSQL databases (ZFS clones) for parallel Claude Code development. Use when starting a feature/fix that needs an isolated dev environment, when listing existing dev worktrees, or when cleaning up after merge. Supports multi-repo workspaces (e.g. ~/projects/figurout) via --repo or interactive selection.
---

# worktree skill

並行開発のために worktree + ZFSスナップショットDB を一括管理する。
スクリプト本体は `~/projects/nixos-config/scripts/` にあり、このskillは
**ユーザの意図を解釈してスクリプトに渡す薄い層**。

## ワークスペース構造の前提

ユーザは `~/projects/figurout/` をワークスペースとして使い、
配下に複数の git repo をぶら下げている：

```
~/projects/figurout/         ← Claudeはここで起動。.claudeを管理する外側のrepo
├── .claude/
├── .git/                    ← 外側自身もrepo
├── hooolders-engagement/    ← 内側repo（実際の開発対象）
├── hooolders-jwt-setter/
├── figurout-firehouse-app/
└── ...
```

worktree操作の対象は **内側の repo**（外側は `.claude` 専用なので worktree しない）。

## いつ使うか

- 新規ブランチで作業を始めるとき（DB変更を含む可能性があるタスク）
- 並行で複数Claudeセッションを別ブランチで動かすとき
- 作業終了後にworktreeとリソースを後片付けするとき
- 現在の作業中worktreeの一覧を見たいとき

## 前提

- ホストがZFS pool `rpool/safe/dev/pg` を持つ
- 対象repoに docker-compose.yml が存在
- 対象repoに template dataset が seed済み

## アクション

### 1. 新規worktree作成
```bash
~/projects/nixos-config/scripts/worktree-new.sh [--repo <name>] <branch> [base-branch]
```

**Claude側の振る舞い**：
- `<branch>` 必須、`base-branch` 任意（デフォルト main）
- `--repo` 未指定でユーザのcwd配下に内側repoが複数ある場合：
  **AskUserQuestion で対象repoを選んでもらってから渡す**
- repo候補が1つだけなら自動選択（スクリプトもログを出す）

### 2. worktree破棄
```bash
~/projects/nixos-config/scripts/worktree-drop.sh [--repo <name>] <branch> [--force]
```
- 確認プロンプトあり（--force でスキップ）
- 対象repo解決は worktree-new と同じ
- containers停止 → unmount → zfs destroy → git worktree remove の順

### 3. worktree一覧
```bash
~/projects/nixos-config/scripts/worktree-list.sh [--repo <name>]
```
- `--repo` 未指定なら cwd配下の **全 repo を横断** して表示
- 列：REPO / BRANCH / PATH / ZFS_CLONE / CONTAINERS

### 4. テンプレート再生成
```bash
cd <repo>
./scripts/seed-template.sh
```
プロジェクト固有スクリプト。`~/projects/nixos-config/scripts/seed-template.sh.example` を repo にコピーして customize。

## 対象repoの解決ロジック（スクリプト内部）

1. `--repo <name>` または `--repo=<name>` が指定されていれば、それを使う
2. cwd 直下に nested git repo (1段) が複数あれば、fzf or `select` で選択UIを出す
3. 1つだけならそれを自動選択
4. cwd 自身が git repo ならそれを使う
5. どれにも当てはまらなければエラー

## プロジェクト固有設定

各repoのルートに `.worktree.env` を置くと上書きできる：

```bash
# .worktree.env
ZFS_TEMPLATE="rpool/safe/dev/pg/hooolders-engagement-template"
ZFS_BASE="rpool/safe/dev/pg"
PG_MOUNT_BASE="/var/lib/dev/pg"
WORKTREE_BASE="${HOME}/projects/figurout/hooolders-engagement-worktrees"
```

## Claude側の振る舞い指針

- ユーザが「新しい作業を始める」「ブランチを切って試したい」と言ったら、
  以下を1〜2行で確認してから worktree-new を提案：
  - 対象repo（複数候補がある場合）
  - DBに触る作業か（触らないなら通常の git switch でも可）
- `--repo` を渡すときは subdirectory 名のみ（フルパスではない）
- 完了報告時：マージ済みworktreeが残っているなら drop を促す
- list を呼ぶ前にユーザの cwd が `~/projects/figurout/` 等の workspace かを確認

## 失敗時の対応

- `zfs command not found` → ZFS非対応ホスト（移行前のTuxedoOS等）
- `template dataset not found` → 先に `<repo>/scripts/seed-template.sh` 実行を案内
- `umount failed (still in use?)` → コンテナ停止確認、`fuser -m <mount>` で原因特定
- `not a git repo: <path>` → `--repo` の値が間違い、subdirectory名を再確認
