import "./styles.css";

import { isTauri } from "@tauri-apps/api/core";
import { getCurrentWindow } from "@tauri-apps/api/window";

import {
  type NumberBase,
  normalizeInputText,
  normalizeBaseNumberText,
  parseInput,
  calculateNetwork,
  generateIpv6FromIpv4,
  generateIpv4FromIpv6,
  formatStandardRows,
  formatIpv4ToIpv6Rows,
  formatIpv6ToIpv4Rows,
  formatRowsForClipboard,
  formatParsedAddress,
  convertBaseNumber,
  formatBaseConversion,
  toggleBaseConversionBit,
} from "./ipcalc";

async function clipboardWrite(text: string): Promise<void> {
  if (navigator.clipboard && typeof navigator.clipboard.writeText === "function") {
    try {
      await navigator.clipboard.writeText(text);
      return;
    } catch {
      writeTextWithTextarea(text);
      return;
    }
  }

  writeTextWithTextarea(text);
}

function writeTextWithTextarea(text: string): void {
  const ta = document.createElement("textarea");
  ta.className = "clipboard-fallback";
  ta.value = text;
  ta.setAttribute("aria-hidden", "true");
  document.body.appendChild(ta);
  ta.select();
  try {
    document.execCommand("copy");
  } finally {
    document.body.removeChild(ta);
  }
}

type Mode = "cidr" | "v4v6" | "v6v4" | "base";

interface HistoryEntry {
  title: string;
  subtitle: string;
  copyText: string;
}

let currentMode: Mode = "cidr";
const history: HistoryEntry[] = [];
const HISTORY_MAX = 8;
const BASE_INPUT_KINDS: NumberBase[] = ["binary", "decimal", "hexadecimal"];
let feedbackTimer: ReturnType<typeof setTimeout> | null = null;
const buttonFeedbackTimers = new WeakMap<HTMLButtonElement, ReturnType<typeof setTimeout>>();
const composingInputs = new WeakSet<HTMLInputElement>();
let baseValue = 0n;
let hasBaseValue = false;
let currentCopyAll = "";
let currentCopyNetwork = "";

const root = document.querySelector<HTMLDivElement>("#app")!;
root.innerHTML = buildShell();
const appWindow = isTauri() ? getCurrentWindow() : null;

const titlebarDragTargets = root.querySelectorAll<HTMLElement>(".titlebar-drag-target");
const btnWindowMinimize = root.querySelector<HTMLButtonElement>("#window-minimize")!;
const btnWindowMaximize = root.querySelector<HTMLButtonElement>("#window-maximize")!;
const btnWindowClose = root.querySelector<HTMLButtonElement>("#window-close")!;
const segmentBtns = root.querySelectorAll<HTMLButtonElement>(".segmented-btn");
const fieldGroups: Record<Mode, HTMLDivElement> = {
  cidr: root.querySelector<HTMLDivElement>("#field-cidr")!,
  v4v6: root.querySelector<HTMLDivElement>("#field-v4v6")!,
  v6v4: root.querySelector<HTMLDivElement>("#field-v6v4")!,
  base: root.querySelector<HTMLDivElement>("#field-base")!,
};

const inputEls = {
  cidr: root.querySelector<HTMLInputElement>("#input-cidr")!,
  ipv4: root.querySelector<HTMLInputElement>("#input-ipv4")!,
  ipv6Prefix: root.querySelector<HTMLInputElement>("#input-ipv6-prefix")!,
  ipv6Reverse: root.querySelector<HTMLInputElement>("#input-ipv6-reverse")!,
  ipv6ReversePrefix: root.querySelector<HTMLInputElement>("#input-ipv6-reverse-prefix")!,
};

const resultStatus = root.querySelector<HTMLSpanElement>("#result-status")!;
const btnCopyAll = root.querySelector<HTMLButtonElement>("#btn-copy-all")!;
const btnCopyNetwork = root.querySelector<HTMLButtonElement>("#btn-copy-network")!;
const resultTable = root.querySelector<HTMLDivElement>("#result-table")!;
const resultCard = root.querySelector<HTMLDivElement>(".result-card")!;
const historyList = root.querySelector<HTMLDivElement>("#history-list")!;
const leftCol = root.querySelector<HTMLDivElement>(".left-col")!;
const actionRow = root.querySelector<HTMLDivElement>("#action-row")!;
const btnCalc = root.querySelector<HTMLButtonElement>("#btn-calc")!;
const baseInputEls: Record<NumberBase, HTMLInputElement> = {
  binary: root.querySelector<HTMLInputElement>("#input-base-binary")!,
  decimal: root.querySelector<HTMLInputElement>("#input-base-decimal")!,
  hexadecimal: root.querySelector<HTMLInputElement>("#input-base-hexadecimal")!,
};
const binaryBitPanel = root.querySelector<HTMLDivElement>("#binary-bit-panel")!;

function buildShell(): string {
  return `
  <main class="app-shell">
    <div class="custom-titlebar" role="banner">
      <div class="titlebar-app-info titlebar-drag-target" data-tauri-drag-region>
        <img class="titlebar-icon" src="/icons8-accounting-office-l/icons8-accounting-40.png" alt="" aria-hidden="true" draggable="false" data-tauri-drag-region />
        <span data-tauri-drag-region>IP 地址计算器</span>
      </div>
      <div class="titlebar-drag-region titlebar-drag-target" data-tauri-drag-region aria-hidden="true"></div>
      <div class="window-controls" aria-label="窗口控制">
        <button class="window-control" id="window-minimize" type="button" aria-label="最小化">
          <span class="window-icon window-icon-minimize" aria-hidden="true"></span>
        </button>
        <button class="window-control" id="window-maximize" type="button" aria-label="最大化或还原">
          <span class="window-icon window-icon-maximize" aria-hidden="true"></span>
        </button>
        <button class="window-control close" id="window-close" type="button" aria-label="关闭">
          <span class="window-icon window-icon-close" aria-hidden="true"></span>
        </button>
      </div>
    </div>

    <header class="app-header">
      <div class="title-row">
        <img class="app-logo" src="/icons8-accounting-office-l/icons8-accounting-40.png" alt="" aria-hidden="true" />
        <h1>IP 地址计算器</h1>
      </div>
      <p class="subtitle">IPv4 / IPv6 网段计算、V4 到 V6 生成与 V6 反算 V4</p>
    </header>

    <div class="content-grid">
      <div class="left-col">
        <div class="card glass-panel">
          <div class="card-header">
            <span class="card-title">输入</span>
            <div class="segmented glass-tabs" role="tablist" aria-label="输入模式">
              <button class="segmented-btn glass-tab active" role="tab" aria-selected="true" data-mode="cidr" type="button">地址/前缀或掩码</button>
              <button class="segmented-btn glass-tab" role="tab" aria-selected="false" data-mode="v4v6" type="button">V4 -&gt; V6</button>
              <button class="segmented-btn glass-tab" role="tab" aria-selected="false" data-mode="v6v4" type="button">V6 -&gt; V4</button>
              <button class="segmented-btn glass-tab" role="tab" aria-selected="false" data-mode="base" type="button">进制转换</button>
            </div>
          </div>
          <div class="card-divider"></div>
          <div class="card-body">
            <div class="field-group active" id="field-cidr" role="tabpanel">
              <div class="field">
                <div class="field-header">
                  <label class="field-label" for="input-cidr">地址/前缀或掩码</label>
                  <span class="field-example">例如 192.168.1.10/24、10.0.0.7/255.255.255.248 或 2001:db8::1/126</span>
                </div>
                <input class="field-input glass-input" id="input-cidr" type="text" inputmode="text" autocomplete="off" />
              </div>
            </div>

            <div class="field-group two-fields" id="field-v4v6" role="tabpanel">
              <div class="field">
                <div class="field-header">
                  <label class="field-label" for="input-ipv4">IPv4 网段</label>
                  <span class="field-example">例如 48.235.24.0/30</span>
                </div>
                <input class="field-input glass-input" id="input-ipv4" type="text" inputmode="text" autocomplete="off" />
              </div>
              <div class="field">
                <div class="field-header">
                  <label class="field-label" for="input-ipv6-prefix">IPv6 前 96 位</label>
                  <span class="field-example">例如 2001:db8::</span>
                </div>
                <input class="field-input glass-input" id="input-ipv6-prefix" type="text" inputmode="text" autocomplete="off" />
              </div>
            </div>

            <div class="field-group two-fields" id="field-v6v4" role="tabpanel">
              <div class="field">
                <div class="field-header">
                  <label class="field-label" for="input-ipv6-reverse">IPv6 地址/网段</label>
                  <span class="field-example">例如 2001:db8::30eb:1800/126</span>
                </div>
                <input class="field-input glass-input" id="input-ipv6-reverse" type="text" inputmode="text" autocomplete="off" />
              </div>
              <div class="field">
                <div class="field-header">
                  <label class="field-label" for="input-ipv6-reverse-prefix">IPv6 /96 前缀（可选）</label>
                  <span class="field-example">例如 2001:db8::，留空则只取最后 32 位</span>
                </div>
                <input class="field-input glass-input" id="input-ipv6-reverse-prefix" type="text" inputmode="text" autocomplete="off" />
              </div>
            </div>

            <div class="field-group base-fields" id="field-base" role="tabpanel">
              <div class="base-input-grid">
                <div class="field">
                  <div class="field-header">
                    <label class="field-label" for="input-base-binary">二进制</label>
                    <span class="field-example">可输入 0b 前缀</span>
                  </div>
                  <input class="field-input glass-input" id="input-base-binary" type="text" inputmode="numeric" autocomplete="off" spellcheck="false" />
                </div>
                <div class="field">
                  <div class="field-header">
                    <label class="field-label" for="input-base-decimal">十进制</label>
                    <span class="field-example">0 到 4294967295</span>
                  </div>
                  <input class="field-input glass-input" id="input-base-decimal" type="text" inputmode="numeric" autocomplete="off" spellcheck="false" />
                </div>
                <div class="field">
                  <div class="field-header">
                    <label class="field-label" for="input-base-hexadecimal">十六进制</label>
                    <span class="field-example">可输入 0x 前缀</span>
                  </div>
                  <input class="field-input glass-input" id="input-base-hexadecimal" type="text" inputmode="text" autocomplete="off" spellcheck="false" />
                </div>
              </div>

              <div class="binary-panel glass-panel-subtle glass-recessed" aria-label="32 位二进制展示框">
                <div class="binary-panel-header">
                  <span class="binary-panel-title">32 位二进制</span>
                  <span class="binary-panel-hint">点击任意位切换 0 / 1</span>
                </div>
                <div class="binary-bit-panel" id="binary-bit-panel"></div>
              </div>
            </div>
          </div>
          <div class="card-divider"></div>
          <div class="action-row" id="action-row">
            <button class="btn btn-primary" id="btn-calc" type="button">计算</button>
          </div>
        </div>

        <div class="card glass-panel result-card">
          <div class="result-header">
            <span class="result-status" id="result-status">等待输入...</span>
            <div class="result-actions" id="result-actions">
              <button class="btn btn-secondary hidden" id="btn-copy-network" type="button">复制网段</button>
              <button class="btn btn-secondary hidden" id="btn-copy-all" type="button">复制全部</button>
            </div>
          </div>
          <div class="card-divider"></div>
          <div class="result-table glass-panel-subtle glass-recessed" id="result-table">
            <p class="result-empty">暂无结果</p>
          </div>
        </div>
      </div>

      <div class="card glass-panel history-card">
        <div class="card-header">
          <span class="card-title">历史记录</span>
        </div>
        <p class="history-hint">历史结果可手动选中复制</p>
        <div class="card-divider"></div>
        <div class="history-list glass-panel-subtle glass-recessed" id="history-list">
          <p class="history-empty">暂无历史记录</p>
        </div>
      </div>
    </div>
  </main>`;
}

function runWindowAction(action: (window: NonNullable<typeof appWindow>) => Promise<void>): void {
  if (!appWindow) return;
  void action(appWindow).catch(() => undefined);
}

titlebarDragTargets.forEach((target) => {
  target.addEventListener("dblclick", (event) => {
    event.preventDefault();
    runWindowAction((window) => window.toggleMaximize());
  });
});

btnWindowMinimize.addEventListener("click", () => runWindowAction((window) => window.minimize()));
btnWindowMaximize.addEventListener("click", () => runWindowAction((window) => window.toggleMaximize()));
btnWindowClose.addEventListener("click", () => runWindowAction((window) => window.close()));

function switchMode(mode: Mode): void {
  currentMode = mode;
  for (const btn of segmentBtns) {
    const isActive = btn.dataset.mode === mode;
    btn.classList.toggle("active", isActive);
    btn.setAttribute("aria-selected", String(isActive));
  }
  for (const [key, group] of Object.entries(fieldGroups) as [string, HTMLDivElement][]) {
    group.classList.toggle("active", key === mode);
  }
  actionRow.classList.toggle("hidden", mode === "base");
  resultCard.classList.toggle("hidden", mode === "base");
  leftCol.classList.toggle("base-mode", mode === "base");
  if (mode === "base") {
    renderBaseState();
  }
}

segmentBtns.forEach((btn) => {
  btn.addEventListener("click", () => switchMode(btn.dataset.mode as Mode));
});

function normalizeFieldText(text: string): string {
  return normalizeInputText(text).replace(/\/{2,}/g, "/");
}

function normalizeOnInput(input: HTMLInputElement): void {
  const raw = input.value;
  const normalized = normalizeFieldText(raw);
  if (raw !== normalized) {
    const cursorPos = input.selectionStart ?? raw.length;
    const before = normalizeFieldText(raw.slice(0, cursorPos));
    input.value = normalized;
    const pos = Math.min(before.length, normalized.length);
    input.setSelectionRange(pos, pos);
  }
}

function normalizeBeforeInput(input: HTMLInputElement, event: InputEvent): void {
  if (event.isComposing || event.data === null) return;

  const normalized = normalizeFieldText(event.data);
  if (normalized === event.data) return;

  event.preventDefault();
  insertNormalizedText(input, normalized);
}

function insertNormalizedText(input: HTMLInputElement, text: string): void {
  const raw = input.value;
  const start = input.selectionStart ?? raw.length;
  const end = input.selectionEnd ?? start;

  if (text === "/" && start === end && (raw[start - 1] === "/" || raw[start] === "/")) {
    return;
  }

  input.value = raw.slice(0, start) + text + raw.slice(end);
  const cursor = start + text.length;
  input.setSelectionRange(cursor, cursor);
  normalizeOnInput(input);
}

for (const input of Object.values(inputEls)) {
  input.addEventListener("beforeinput", (event) => normalizeBeforeInput(input, event as InputEvent));
  input.addEventListener("compositionstart", () => composingInputs.add(input));
  input.addEventListener("compositionend", () => {
    composingInputs.delete(input);
    normalizeOnInput(input);
  });
  input.addEventListener("input", () => {
    if (!composingInputs.has(input)) normalizeOnInput(input);
  });
  input.addEventListener("blur", () => normalizeOnInput(input));
}

for (const base of BASE_INPUT_KINDS) {
  const input = baseInputEls[base];
  input.addEventListener("input", () => onBaseInput(base));
  input.addEventListener("blur", () => {
    if (input.classList.contains("invalid")) return;
    renderBaseState();
  });
  input.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      e.preventDefault();
      renderBaseState();
    }
  });
}

binaryBitPanel.addEventListener("click", (event) => {
  const target = event.target as HTMLElement;
  const bitButton = target.closest<HTMLButtonElement>(".binary-bit");
  if (!bitButton?.dataset.bitIndex) return;
  onBinaryBitToggle(Number(bitButton.dataset.bitIndex));
});

renderEmptyBaseConversion();

function setStatus(text: string, className: string): void {
  resultStatus.textContent = text;
  resultStatus.className = "result-status" + (className ? ` ${className}` : "");
}

function flashStatus(text: string, className: string, duration = 1400): void {
  if (feedbackTimer !== null) clearTimeout(feedbackTimer);
  setStatus(text, className);
  feedbackTimer = setTimeout(() => {
    feedbackTimer = null;
    setStatus(resultStatus.dataset.stableText ?? "等待输入...", resultStatus.dataset.stableClass ?? "");
  }, duration);
}

function flashButton(btn: HTMLButtonElement, text: string, duration = 1400): void {
  const original = btn.dataset.originalText ?? btn.textContent ?? "";
  btn.textContent = text;
  btn.classList.add("copied");
  const existingTimer = buttonFeedbackTimers.get(btn);
  if (existingTimer !== undefined) clearTimeout(existingTimer);
  const nextTimer = setTimeout(() => {
    buttonFeedbackTimers.delete(btn);
    btn.textContent = original;
    btn.classList.remove("copied");
  }, duration);
  buttonFeedbackTimers.set(btn, nextTimer);
}

function clearResult(): void {
  resultTable.innerHTML = "";
  btnCopyAll.classList.add("hidden");
  btnCopyNetwork.classList.add("hidden");
  btnCopyAll.textContent = "复制全部";
  btnCopyAll.dataset.originalText = "复制全部";
  setNetworkCopyButton("复制网段", "网段");
  btnCopyAll.classList.remove("copied");
  btnCopyNetwork.classList.remove("copied");
  currentCopyAll = "";
  currentCopyNetwork = "";
  renderEmptyResult();
}

function setNetworkCopyButton(text: string, copyLabel: string): void {
  btnCopyNetwork.textContent = text;
  btnCopyNetwork.dataset.originalText = text;
  btnCopyNetwork.dataset.copyLabel = copyLabel;
}

function renderEmptyResult(): void {
  const empty = document.createElement("p");
  empty.className = "result-empty";
  empty.textContent = "暂无结果";
  resultTable.appendChild(empty);
}

function renderResultRows(rows: Array<[string, string]>): void {
  resultTable.innerHTML = "";
  for (const [label, value] of rows) {
    const row = document.createElement("div");
    row.className = "result-row glass-chip";
    row.tabIndex = 0;
    row.setAttribute("role", "button");
    row.setAttribute("aria-label", `点击复制 ${label}`);

    const labelEl = document.createElement("span");
    labelEl.className = "result-label";
    labelEl.textContent = label;

    const valueEl = document.createElement("span");
    valueEl.className = "result-value";
    valueEl.textContent = value;

    const copyHandler = () => {
      void clipboardWrite(value);
      flashStatus(`已复制：${label}`, "accent");
    };

    row.addEventListener("click", copyHandler);
    row.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        copyHandler();
      }
    });

    row.appendChild(labelEl);
    row.appendChild(valueEl);
    resultTable.appendChild(row);
  }
}

function renderBaseConversion(
  result: ReturnType<typeof formatBaseConversion>,
  activeInput: NumberBase | null,
): void {
  baseValue = result.value;
  hasBaseValue = true;

  if (activeInput !== "binary") baseInputEls.binary.value = result.binary;
  if (activeInput !== "decimal") baseInputEls.decimal.value = result.decimal;
  if (activeInput !== "hexadecimal") baseInputEls.hexadecimal.value = result.hexadecimal;

  for (const input of Object.values(baseInputEls)) {
    input.classList.remove("invalid");
  }

  renderBinaryBits(result.binary32);
}

function renderEmptyBaseConversion(): void {
  baseValue = 0n;
  hasBaseValue = false;

  for (const input of Object.values(baseInputEls)) {
    input.value = "";
    input.classList.remove("invalid");
  }

  renderBinaryBits(formatBaseConversion(0n).binary32);
}

function renderBaseState(): void {
  if (hasBaseValue) {
    renderBaseConversion(formatBaseConversion(baseValue), null);
  } else {
    renderEmptyBaseConversion();
  }
}

function onBaseInput(base: NumberBase): void {
  try {
    if (!normalizeBaseNumberText(baseInputEls[base].value)) {
      renderEmptyBaseConversion();
      return;
    }

    renderBaseConversion(convertBaseNumber(baseInputEls[base].value, base), base);
  } catch (err) {
    baseInputEls[base].classList.add("invalid");
    currentCopyAll = "";
    currentCopyNetwork = "";
    btnCopyAll.classList.add("hidden");
    btnCopyNetwork.classList.add("hidden");
    showError((err as Error).message);
    resultStatus.dataset.stableText = "进制转换输入错误";
    resultStatus.dataset.stableClass = "error";
    setStatus("进制转换输入错误", "error");
  }
}

function onBinaryBitToggle(bitIndex: number): void {
  try {
    renderBaseConversion(toggleBaseConversionBit(baseValue, bitIndex), null);
  } catch (err) {
    showError((err as Error).message);
  }
}

function renderBinaryBits(binary32: string): void {
  binaryBitPanel.innerHTML = "";

  for (let rowIndex = 0; rowIndex < 2; rowIndex += 1) {
    const row = document.createElement("div");
    row.className = "binary-bit-row";

    for (let byteIndex = 0; byteIndex < 2; byteIndex += 1) {
      const byte = document.createElement("div");
      byte.className = "binary-byte";

      for (let groupOffset = 0; groupOffset < 2; groupOffset += 1) {
        const groupIndex = byteIndex * 2 + groupOffset;
        const group = document.createElement("div");
        group.className = "binary-bit-group";

        for (let bitOffset = 0; bitOffset < 4; bitOffset += 1) {
          const position = rowIndex * 16 + groupIndex * 4 + bitOffset;
          const bitIndex = 31 - position;
          const bit = binary32[position];
          const btn = document.createElement("button");
          btn.className = `binary-bit ${bit === "1" ? "on" : "off"}`;
          btn.type = "button";
          btn.textContent = bit;
          btn.dataset.bitIndex = String(bitIndex);
          btn.setAttribute("aria-label", `切换第 ${bitIndex} 位，当前为 ${bit}`);
          group.appendChild(btn);
        }

        byte.appendChild(group);
      }

      row.appendChild(byte);
    }

    binaryBitPanel.appendChild(row);
  }
}

function showError(message: string): void {
  resultTable.innerHTML = "";
  setStatus("错误", "error");
  resultStatus.dataset.stableText = "错误";
  resultStatus.dataset.stableClass = "error";

  const errorEl = document.createElement("div");
  errorEl.className = "result-error";
  errorEl.textContent = message;
  resultTable.appendChild(errorEl);
}

function addHistory(title: string, subtitle: string, copyText: string): void {
  if (!copyText) return;

  const idx = history.findIndex((h) => h.copyText === copyText);
  if (idx !== -1) history.splice(idx, 1);

  history.unshift({ title, subtitle, copyText });
  if (history.length > HISTORY_MAX) history.length = HISTORY_MAX;

  renderHistory();
}

function renderHistory(): void {
  historyList.innerHTML = "";

  if (history.length === 0) {
    const empty = document.createElement("p");
    empty.className = "history-empty";
    empty.textContent = "暂无历史记录";
    historyList.appendChild(empty);
    return;
  }

  for (const entry of history) {
    const item = document.createElement("div");
    item.className = "history-item glass-chip";

    const title = document.createElement("div");
    title.className = "history-title";
    title.textContent = entry.title;

    const subtitle = document.createElement("div");
    subtitle.className = "history-subtitle";
    subtitle.textContent = entry.subtitle;

    item.appendChild(title);
    item.appendChild(subtitle);

    historyList.appendChild(item);
  }
}

function onCalculate(): void {
  if (currentMode === "base") {
    renderBaseState();
    return;
  }

  clearResult();

  try {
    if (currentMode === "v4v6") {
      onCalculateV4v6();
    } else if (currentMode === "v6v4") {
      onCalculateV6v4();
    } else {
      onCalculateStandard();
    }
  } catch (err) {
    showError((err as Error).message);
  }
}

function onCalculateStandard(): void {
  const raw = normalizeFieldText(inputEls.cidr.value);
  if (!raw) throw new Error("请输入地址和前缀或掩码，例如 10.0.0.1/20");

  const [address, prefixLength] = parseInput([raw]);
  const result = calculateNetwork(address, prefixLength);
  const rows = formatStandardRows(result);
  const addressText = formatParsedAddress(address);

  const statusText = `${addressText}/${prefixLength}`;
  setStatus(statusText, "accent");
  resultStatus.dataset.stableText = statusText;
  resultStatus.dataset.stableClass = "accent";

  currentCopyAll = formatRowsForClipboard(rows);
  btnCopyAll.classList.remove("hidden");

  renderResultRows(rows);
  addHistory(result.network, `网段计算 · ${addressText}/${prefixLength}`, result.network);
}

function onCalculateV4v6(): void {
  const ipv4Raw = normalizeFieldText(inputEls.ipv4.value);
  const ipv6PrefixRaw = normalizeFieldText(inputEls.ipv6Prefix.value);
  if (!ipv4Raw) throw new Error("请输入 IPv4 网段，例如 48.235.24.0/30");
  if (!ipv6PrefixRaw) throw new Error("请输入 IPv6 前 96 位，例如 2001:db8::");

  const [address, prefixLength] = parseInput([ipv4Raw]);
  const result = generateIpv6FromIpv4(address, prefixLength, ipv6PrefixRaw);
  const rows = formatIpv4ToIpv6Rows(result);

  setStatus("IPv6 网段已生成", "accent");
  resultStatus.dataset.stableText = "IPv6 网段已生成";
  resultStatus.dataset.stableClass = "accent";

  currentCopyAll = formatRowsForClipboard(rows);
  currentCopyNetwork = result.ipv6_network;
  setNetworkCopyButton("复制 IPv6 网段", "IPv6 网段");

  btnCopyAll.classList.remove("hidden");
  btnCopyNetwork.classList.remove("hidden");

  renderResultRows(rows);
  addHistory(result.ipv6_network, `V4 -> V6 · ${result.ipv4_network}`, result.ipv6_network);
}

function onCalculateV6v4(): void {
  const ipv6Raw = normalizeFieldText(inputEls.ipv6Reverse.value);
  const ipv6PrefixRaw = normalizeFieldText(inputEls.ipv6ReversePrefix.value);
  if (!ipv6Raw) throw new Error("请输入 IPv6 地址或网段，例如 2001:db8::30eb:1800/126");

  const result = generateIpv4FromIpv6(ipv6Raw, ipv6PrefixRaw);
  const rows = formatIpv6ToIpv4Rows(result);

  setStatus("IPv4 网段已反算", "accent");
  resultStatus.dataset.stableText = "IPv4 网段已反算";
  resultStatus.dataset.stableClass = "accent";

  currentCopyAll = formatRowsForClipboard(rows);
  currentCopyNetwork = result.ipv4_network;
  setNetworkCopyButton("复制 IPv4 网段", "IPv4 网段");

  btnCopyAll.classList.remove("hidden");
  btnCopyNetwork.classList.remove("hidden");

  renderResultRows(rows);
  addHistory(result.ipv4_network, `V6 -> V4 · ${result.ipv6_network}`, result.ipv4_network);
}

btnCalc.addEventListener("click", onCalculate);

for (const input of Object.values(inputEls)) {
  input.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      e.preventDefault();
      onCalculate();
    }
  });
}

btnCopyAll.addEventListener("click", () => {
  if (!currentCopyAll) return;
  void clipboardWrite(currentCopyAll);
  flashButton(btnCopyAll, "已复制");
  flashStatus("已复制：全部结果", "accent");
});

btnCopyNetwork.addEventListener("click", () => {
  if (!currentCopyNetwork) return;
  void clipboardWrite(currentCopyNetwork);
  flashButton(btnCopyNetwork, "已复制");
  flashStatus(`已复制：${btnCopyNetwork.dataset.copyLabel ?? "网段"}`, "accent");
});
