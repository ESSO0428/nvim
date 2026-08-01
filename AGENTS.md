# Working Context

- 在修改前，先閱讀這份 `AGENTS.md`，先掌握整體專案方向，再動手調整程式或文件。

## 慣例

- `AGENTS.md` 內的 superpowers 規範屬於行為覆寫：只有當使用者在提示詞中明確要求 `/brainstorming`，或明確貼出 `Brainstorming Ideas Into Designs` 這類被轉成純文字的 brainstorming 指令標題時，才進入 `/brainstorming` 模式。
- 若因任務複雜度或其他原因實際調用了 `/brainstorming` 行為模式，則該輪對話要盡可能一次問完核心問題，避免拆成多輪延伸追問。
- 若處於 `/brainstorming` 模式，提問時應盡量優先使用 `question` tool 進行互動式提問；除非情境不適合，否則不要只用一般文字訊息提問。
- 進入上述提問情境時，每一輪提問都必須附帶詢問使用者四個選項：`1. 不額外限制提問方式（依當前情境提問）`、`2. 繼續深入討論`、`3. 快速收斂問題，不要繼續延伸細節`、`4. 提問環節到此為止`。
- 使用者對上述三個選項作答後，agent 必須如實採用，不可自行延伸或繼續追問未被允許的細節。
- **不可操作 git 控制版本**：AI agent 不可執行任何 git 指令（`git add`、`git commit`、`git push`、`git stash`、`git merge`、`git rebase` 等）。版本控制由人類開發者自行管理；agent 只負責修改檔案內容。
