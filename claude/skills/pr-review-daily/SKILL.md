---
name: pr-review-daily
description: 毎日のPRレビューを省力化する。自分がレビューすべきオープンPRを横断探索し、各PRを pr-reviewer エージェントで並行レビュー。approve相当はAPPROVE・重大ブロッカーはREQUEST_CHANGES・それ以外はCOMMENTとして全件を自動Submitし、結果をターミナル/ローカルダイジェスト/Slack Webhookで通知する。Use when the user wants to run their daily PR review pass, "PRレビュー", "今日のPR見て", "daily pr review".
---

# pr-review-daily skill

soultoru（CTO）の毎日のPRレビューを自動化する薄いオーケストレーション層。
探索・除外・並行レビュー・選択的Submit・報告までを一括で行う。

レビュー本体のロジックは `pr-reviewer` エージェントが持つ。このskillは
**対象PRを正しく集め、pr-reviewer を並行起動し、結果に応じてSubmit/下書きを振り分け、
プレーンURLで報告する**ことに責任を持つ。

---

## Step 1: 対象PRの探索（2系統を必ず併用）

`review-requested:@me` だけでは、自分が過去に CHANGES_REQUESTED / COMMENT を出した後に
著者が対応した（再レビュー依頼が立っていない）PRを取りこぼす。必ず2系統を走査する。

```bash
# (1) 明示的にレビュー依頼が立っているPR
gh search prs --review-requested=@me --state=open --limit 100 \
  --json number,title,url,repository,author,isDraft,updatedAt

# (2) 過去に自分がレビューしたPR（CHANGES_REQUESTED後の再対応を拾う）
gh search prs --reviewed-by=@me --state=open --limit 100 \
  --json number,title,url,repository,author,isDraft,updatedAt
```

(2) の各PRは「自分の最新レビュー以降に新コミットがあるか」を判定する。
GraphQL の `reviews.commitId` は null を返すため REST を使う:

```bash
gh pr view <n> --repo <owner/repo> --json number,title,author,isDraft,headRefOid,reviewRequests,reviews,updatedAt
gh api /repos/<owner>/<repo>/pulls/<n>/reviews --jq '.[] | select(.user.login=="soultoru") | {state,commit:.commit_id,submitted:.submitted_at}'
```

判定:
- 自分の**最新**レビュー対象 commit ≠ 現 `headRefOid` → **再レビュー候補**（新コミットあり）
- 自分の CHANGES_REQUESTED が dismiss されず残っている → **優先度高**（ブロッキング中）

## Step 2: 除外ルール

以下は対象から除外する（理由を1行で記録し、報告末尾に列挙）:

- **著者が `aubreymaemulawan`** → James が担当。レビュー不要（`project_pr_review_policy` メモリ）
- **Draft PR** （`isDraft: true`）
- **自分（soultoru）が著者のPR**
- **自分が現 `headRefOid` に対して APPROVED 済みで以降変更なし** → 再対応不要
- **自分の最新レビュー以降に新コミットが無い**（最新コミットにレビュー済み）
- **すでに提出待ちの自分のPending下書きが現 `headRefOid` に対して存在** → 二重作成しない（報告には「下書き提出待ち」として載せる）
- クローズ済み / マージ済み

## Step 3: pr-reviewer を並行起動

残った対象PRごとに `pr-reviewer` エージェントを **1メッセージ内で並行起動**する
（Agent tool を複数同時に呼ぶ）。各エージェントへのプロンプトに必ず含める:

- リポジトリ・PR番号・URL・タイトル・著者
- 自分の過去レビュー種別（CHANGES_REQUESTED / COMMENT）とその対象 commit、現 HEAD commit
- 「過去の指摘が新コミットで解消されているかを最優先で突き合わせ、解消済みは再掲しない」
- 「既出・Copilot・他レビュアー・著者回答済みの論点は重複投稿しない」
- **保存方法**: シェルのファイルリダイレクト/heredoc がブロックされる環境のため、
  `python3 -c` でJSONを生成し標準入力パイプで
  `gh api -X POST /repos/<o>/<r>/pulls/<n>/reviews --input -` に渡す
  （バッククォート・heredoc・コマンド置換・ファイルリダイレクトを回避）。
  Pending にするため **`event` フィールドは付けない**。
- **Nitコメントの文面**: 推奨アクションが approve 相当でNit/任意指摘を含む場合、各Nitコメントに
  「ブロッカーではないため、可能なら別PRでの対応をご検討ください」の一文を必ず入れる。
- 最終出力として「保存成否 / Pendingレビュー review_id と URL / 過去指摘の解消状況 /
  新規指摘 / 推奨アクション（approve相当 / comment / changes requested相当 のいずれか明示）」を返させる。
- レビューコメントの言語は著者に合わせる（pr-reviewer の規約に従う。日本語話者→日本語、英語話者→英日二重）。

## Step 4: 自動Submit（全件提出）

各エージェントの結果を受け取り、**推奨アクションに応じた event で全件を自動提出**する。
提出は既存Pending下書きを events エンドポイントでそのまま提出する:

```bash
gh api -X POST /repos/<owner>/<repo>/pulls/<n>/reviews/<review_id>/events -f event=<EVENT>
```

**event の振り分け:**

- **APPROVE** — 推奨アクションが approve 相当（過去のブロッキング指摘が全解消、
  新規は Nit / 任意のみ）。CHANGES_REQUESTED がブロッキングのまま残っていたPRをこれで
  提出するとブロックが解除される（意図した挙動）。
- **REQUEST_CHANGES** — **明確で重大なブロッカー**がある場合のみ。具体的には
  セキュリティ脆弱性・データ破壊/損失・マージするとリグレッション確実な correctness バグ等、
  「マージ前に必ず直すべき」と断定できるもの。**迷ったら REQUEST_CHANGES にせず COMMENT にする**
  （マージを止める判断は重い。確信が持てる重大指摘に限定）。
- **COMMENT** — 上記以外すべて。要確認・要検討・Nit・軽微な指摘など。指摘は届くが
  マージはブロックしない。

**Nitコメントの文面**: APPROVE / COMMENT で提出するレビューに Nit / 任意指摘が含まれる場合、
各 Nit コメント本文に「ブロッカーではないため、可能なら別PRでの対応をご検討ください」の一文が
入っていること（pr-reviewer に指示済み）。入っていなければ提出前に追記する。

**提出しない/保留する例外:**
- エージェントが保存失敗を報告した、推奨アクションが判別不能、review_id が取れない 等の
  異常時はそのPRだけ提出せず Pending のまま残し、報告で「要手動確認」と明示する。

全件提出が原則だが、REQUEST_CHANGES だけは安全側（確信が持てる重大ブロッカーに限定）に倒す。

## Step 5: 報告と通知

ユーザーは CLI 利用のため、**markdownインラインリンクを使わず生URLをそのまま**記載する
（`feedback_plain_urls_in_cli` メモリ）。各URLは `#番号 https://...` の形式で1行ずつ。

### 5-1. ターミナル出力

次の3区分でプレーンURL報告:

1. **自動Submit済み** — PR番号・タイトル・著者・提出種別（APPROVE / REQUEST_CHANGES / COMMENT）・レビューURL
2. **保留（要手動確認）** — 異常で提出しなかったPR。理由とレビューURL（あれば）
3. **対象外（除外）** — PR番号・理由（1行）

### 5-2. ローカルダイジェスト（常に追記）

このrunで**1件以上提出した場合のみ**、ダイジェストを追記する（提出ゼロのhourly runは静かにする）。
`date` で実時刻を付与（このskillは通常のシェルで動くため `date` 使用可）:

```bash
python3 -c '
import sys
lines = sys.argv[1]
open("/home/soultoru/.claude-figurout/pr-review-inbox.md","a").write(lines)
' "$(printf "\n## %s 提出 %d件\n%s\n" "$(date "+%Y-%m-%d %H:%M")" "<件数>" "<各行: - [EVENT] #番号 タイトル (著者) URL>")"
```

（実装は1件ずつ素直に追記してよい。要は追記先 `/home/soultoru/.claude-figurout/pr-review-inbox.md` に
「日時・提出種別・PR・著者・生URL」が残ること。）

このダイジェストは次にターミナルを開いた時に表示される（zsh ログインフックが
`pr-review-inbox.md` の未読分を表示し、確認後はユーザーが消すか自動でアーカイブされる想定）。

### 5-3. Slack 通知（提出があった場合のみ）

環境変数 `SLACK_REVIEW_WEBHOOK`（`.envrc` 由来）が設定されていれば、**1件以上提出した場合のみ**
Incoming Webhook に要約を push する。未設定ならスキップ（エラーにしない）。MCP は使わない
（ヘッドレスcronで不発のため curl で送る）:

```bash
[ -n "${SLACK_REVIEW_WEBHOOK:-}" ] && python3 -c '
import json, os, subprocess
text = os.environ["MSG"]
payload = json.dumps({"text": text})
subprocess.run(["curl","-sS","-X","POST","-H","Content-type: application/json",
  "--data","@-", os.environ["SLACK_REVIEW_WEBHOOK"]], input=payload, text=True)
'
```
（`MSG` には「PRレビュー自動提出 N件」+ 各行 `EVENT #番号 タイトル URL` を改行区切りで入れる。
生URLのまま。Slackがリンク化する。）

最後にターミナルへ「Slack通知済み / ダイジェスト追記済み」かどうかも一言添える。

## 注意

- 自動Submit（approve）は外部公開・取り消しづらい操作。条件を満たさない/迷う場合は必ず下書きで止める。
- 探索・除外・保存方法・URL形式の各ルールは関連メモリと整合させること:
  `feedback_pr_review_target_search` / `project_pr_review_policy` /
  `feedback_pr_reviewer_save_method` / `feedback_plain_urls_in_cli`。
- 大量にヒットした場合でも並行起動は一度に行ってよい（Agent tool は並行実行される）。
