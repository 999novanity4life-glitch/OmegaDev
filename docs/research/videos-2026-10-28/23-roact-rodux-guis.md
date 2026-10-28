# Roblox Developer Conference 2018 - Building Amazing GUIs
- Channel: Roblox | URL: https://www.youtube.com/watch?v=vHTXAsHqrPI | Length: 23:27 | Upload: 2018-07-24 | Captions: auto
About UI code architecture (testing, state, declarative UI), not visual design. 2018 caveat: Roact is deprecated in favor of React-Lua; TestEZ and Lemur are archived (Roblox moved to Jest-Lua); tick() is deprecated. Rodux and Rojo are still in use. Native UICorner, UIStroke, UIGradient, UIPadding, UIFlexLayout are not covered.

- [3:32] State challenge: networking and user input all read and write app state. If parts of the code disagree, you get desync bugs (wrong currency, items vanishing or swapping).
- [4:02] State ownership: define who may write data, who may read it, and how it flows. With a single owner per piece of data, sync is easy.
- [4:33] Dynamic UI is the hard part. Lists and grids (inventories) are hard to diff.
- [5:37] Retained-mode UI (Roblox's native model) is easy for single values but list updates are "an endless rabbit hole". Destroying and recreating everything every frame is very slow.
- [6:39] Immediate-mode UI re-describes the UI every frame from data: great ergonomics, poor performance.
- [9:11] Their answers: TestEZ for testing, Rodux (Redux) for state, Roact (React) for dynamic UI.
- [10:43] Rodux principles: a single source of truth, read-only state, and changes made by pure reducers (state, action) -> newState.
- [13:19] Roact components take props/state and return a description of the UI; underneath it updates real instances efficiently.
- [16:23] Lists: a plain Lua loop creating one element per item inside a Frame with a UIListLayout (SortOrder = LayoutOrder).
- [17:24] Change the data, describe the UI again, update. The library reconciles the difference.
- [22:13] Work with hot reloading on Rojo.

Applies to Roblox how (inferred): Keep one owner per piece of UI state so lists can't desync. Do visual polish with native UICorner, UIStroke, UIGradient and constraints.
