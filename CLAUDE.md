# CLAUDE.md (maid-cafe-tokyo)

open-englishとrealdata.proの融合。運用先 https://maid-cafe.tokyo 。
Fusion of open-english and realdata.pro, served at https://maid-cafe.tokyo.

決まり / Rules: 新しいRESTは作らない(Connectのみ)/ no new REST; 秘密は書かない / never write secrets; 開発・試験は手元PC、VPSは配備と確認だけ / develop and test locally, VPS only for deploy and checks.

## 2026-11-20 低VRAM・VRAM無し端末(VPS・PC・タブレット・スマホ)でのAI/LLMのノウハウ / Low-VRAM AI know-how
日本語: AI・LLMを使う機能(推論・要約・補完等)は [aruaru-llm/docs/LOW-VRAM-KNOWHOW.md](https://github.com/aon-co-jp/aruaru-llm/blob/main/docs/LOW-VRAM-KNOWHOW.md) に従う: 短い文脈・上限・タイムアウト、VPSで重い推論を直接回さない、メモリが足りなければ小さいモデルへ自動で下げる。広い桁(FP64以上)は本番で使わず、試験の正解にだけ使う。
English: Features that use AI/LLMs follow the file above: short context, caps and timeouts, no heavy inference directly on the VPS, auto-downgrade to a smaller model when memory is short. Wide floats (FP64 and above) are for test oracles only, not production.
