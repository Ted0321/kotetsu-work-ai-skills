# なぜなぜ分析ツリー（why-why-tree）

「なぜを5回」ではなく、**型**で掘る。1階層ずつ「展開 → 兄弟監査 → 停止判定」を回し、
対策が打てる根本原因まで分解して、型付きロジックツリーとして出力するスキル。

## クイックスタート

**コピペ型（Claude / ChatGPT / Gemini など何でも）**

1. [SKILL.md](./SKILL.md) を開く
2. AIに貼る
3. 末尾に問題を書く（例:「開発プロジェクトの納期遅延が続いている。なぜなぜ分析して」）

**エージェント型（Claude Code / Codex など）**

```bash
npx skills add Ted0321/kotetsu-work-ai-skills@why-why-tree
```

導入後は「〜のなぜなぜ分析をして」で自動発火し、HTMLツリーまで出力する。

例: [examples/sample_input_output.md](./examples/sample_input_output.md)
完成出力の実例: [examples/sample_run/](./examples/sample_run/)（tree.json → why-why-tree-repeat-rate.html。マーカー差し替えだけで生成した実物）

## 出力されるもの

- **型付きロジックツリー** — 全リーフに停止理由の型が付く（● 対策可／◐ 要検証／○ 所与／△ 要調査）。本命パス（最も効く1本道）を濃紺で強調
- **根本原因と次の一手** — ●には打ち手1文、◐には検証方法が必ず付く
- **HTML1ファイル**（エージェント型）— 開いた瞬間にツリー全体が表示される配布用資料（A4印刷可、[assets/tree-template.html](./assets/tree-template.html) をブラウザで開くと完成見本）。コピペ型ではテキスト木＋Mermaid＋対策表

## 注意

- 現場の事実・データを渡さない場合は**仮説モード**で動く（全ノード仮説扱い・検証を前提とした木になる）。事実を貼るほど木は強くなる
- ノード文は40字以内・総数30ノード以下に収める設計（効く枝に絞るのも品質のうち）
- `assets/tree-template.html` は `TREE_DATA_START`〜`TREE_DATA_END` マーカー間のJSONだけを差し替える。それ以外の行は変更しない
