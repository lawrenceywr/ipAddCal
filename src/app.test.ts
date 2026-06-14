import { beforeEach, describe, expect, it, vi } from "vitest";

async function loadApp(): Promise<void> {
  vi.resetModules();
  document.body.innerHTML = '<div id="app"></div>';
  Object.defineProperty(navigator, "clipboard", {
    configurable: true,
    value: { writeText: vi.fn().mockResolvedValue(undefined) },
  });
  await import("./main");
}

describe("Tauri frontend behavior", () => {
  beforeEach(async () => {
    await loadApp();
  });

  it("calculates CIDR input without object string leakage", () => {
    const input = document.querySelector<HTMLInputElement>("#input-cidr")!;
    const button = document.querySelector<HTMLButtonElement>("#btn-calc")!;

    input.value = "192.168.1.10/24";
    button.click();

    expect(document.querySelector("#result-status")?.textContent).toBe("192.168.1.10/24");
    expect(document.querySelector("#result-table")?.textContent).toContain("192.168.1.0/24");
    expect(document.querySelector(".history-subtitle")?.textContent).toBe("网段计算 · 192.168.1.10/24");
    expect(document.body.textContent).not.toContain("[object Object]");
  });

  it("keeps dotted netmask input in the unified address field", () => {
    const input = document.querySelector<HTMLInputElement>("#input-cidr")!;
    const button = document.querySelector<HTMLButtonElement>("#btn-calc")!;

    input.value = "10.0.0.7/255.255.255.248";
    button.click();

    expect(document.querySelector('[data-mode="split"]')).toBeNull();
    expect(document.querySelector("#result-status")?.textContent).toBe("10.0.0.7/29");
    expect(document.querySelector("#result-table")?.textContent).toContain("10.0.0.0/29");
  });

  it("copies a result row when clicked", async () => {
    const input = document.querySelector<HTMLInputElement>("#input-cidr")!;
    const button = document.querySelector<HTMLButtonElement>("#btn-calc")!;

    input.value = "192.168.1.10/24";
    button.click();
    document.querySelector<HTMLElement>(".result-row")!.click();
    await Promise.resolve();

    expect(navigator.clipboard.writeText).toHaveBeenCalledWith("192.168.1.0/24");
  });

  it("switches to V4 to V6 mode and exposes IPv6 copy button", () => {
    document.querySelector<HTMLButtonElement>('[data-mode="v4v6"]')!.click();
    document.querySelector<HTMLInputElement>("#input-ipv4")!.value = "48.235.24.0/30";
    document.querySelector<HTMLInputElement>("#input-ipv6-prefix")!.value = "2001:db8::";
    document.querySelector<HTMLButtonElement>("#btn-calc")!.click();

    expect(document.querySelector("#result-status")?.textContent).toBe("IPv6 网段已生成");
    expect(document.querySelector("#result-table")?.textContent).toContain(
      "2001:db8::30eb:1800/126",
    );
    expect(document.querySelector("#btn-copy-network")?.textContent).toBe("复制 IPv6 网段");
    expect(document.querySelector("#btn-copy-network")?.classList.contains("hidden")).toBe(false);
  });

  it("switches to V6 to V4 mode and reverses the last 32 bits", () => {
    document.querySelector<HTMLButtonElement>('[data-mode="v6v4"]')!.click();
    document.querySelector<HTMLInputElement>("#input-ipv6-reverse")!.value =
      "2001:db8::30eb:1800/126";
    document.querySelector<HTMLInputElement>("#input-ipv6-reverse-prefix")!.value = "2001:db8::";
    document.querySelector<HTMLButtonElement>("#btn-calc")!.click();

    expect(document.querySelector("#result-status")?.textContent).toBe("IPv4 网段已反算");
    expect(document.querySelector("#result-table")?.textContent).toContain("48.235.24.0/30");
    expect(document.querySelector("#btn-copy-network")?.textContent).toBe("复制 IPv4 网段");
  });

  it("syncs base conversion inputs while typing", () => {
    document.querySelector<HTMLButtonElement>('[data-mode="base"]')!.click();
    const decimalInput = document.querySelector<HTMLInputElement>("#input-base-decimal")!;

    decimalInput.value = "255";
    decimalInput.dispatchEvent(new Event("input"));

    expect(document.querySelector<HTMLInputElement>("#input-base-binary")?.value).toBe("11111111");
    expect(document.querySelector<HTMLInputElement>("#input-base-hexadecimal")?.value).toBe("FF");
    expect(document.querySelectorAll(".binary-bit.on")).toHaveLength(8);
    expect(document.querySelector(".action-row")?.classList.contains("hidden")).toBe(true);
    expect(document.querySelector(".result-card")?.classList.contains("hidden")).toBe(true);
  });

  it("opens base conversion with blank inputs", () => {
    document.querySelector<HTMLButtonElement>('[data-mode="base"]')!.click();

    expect(document.querySelector<HTMLInputElement>("#input-base-binary")?.value).toBe("");
    expect(document.querySelector<HTMLInputElement>("#input-base-decimal")?.value).toBe("");
    expect(document.querySelector<HTMLInputElement>("#input-base-hexadecimal")?.value).toBe("");
    expect(document.querySelectorAll(".binary-bit")).toHaveLength(32);
    expect(document.querySelectorAll(".binary-bit-row")).toHaveLength(2);
    expect(document.querySelectorAll(".binary-byte")).toHaveLength(4);
    expect(document.querySelectorAll(".binary-bit.on")).toHaveLength(0);
  });

  it("returns base conversion inputs to blank after clearing the active field", () => {
    document.querySelector<HTMLButtonElement>('[data-mode="base"]')!.click();
    const decimalInput = document.querySelector<HTMLInputElement>("#input-base-decimal")!;

    decimalInput.value = "16";
    decimalInput.dispatchEvent(new Event("input"));
    decimalInput.value = "";
    decimalInput.dispatchEvent(new Event("input"));

    expect(document.querySelector<HTMLInputElement>("#input-base-binary")?.value).toBe("");
    expect(document.querySelector<HTMLInputElement>("#input-base-decimal")?.value).toBe("");
    expect(document.querySelector<HTMLInputElement>("#input-base-hexadecimal")?.value).toBe("");
    expect(document.querySelectorAll(".binary-bit.on")).toHaveLength(0);
  });

  it("toggles a binary display bit and updates all base fields", () => {
    document.querySelector<HTMLButtonElement>('[data-mode="base"]')!.click();
    document.querySelector<HTMLButtonElement>('[data-bit-index="31"]')!.click();

    expect(document.querySelector<HTMLInputElement>("#input-base-decimal")?.value).toBe(
      "2147483648",
    );
    expect(document.querySelector<HTMLInputElement>("#input-base-hexadecimal")?.value).toBe(
      "80000000",
    );
    expect(document.querySelector<HTMLInputElement>("#input-base-binary")?.value).toBe(
      `1${"0".repeat(31)}`,
    );
  });

  it("normalizes full-width input while typing", () => {
    const input = document.querySelector<HTMLInputElement>("#input-cidr")!;
    input.value = "１９２．１６８．１．１０／２４";
    input.dispatchEvent(new Event("input"));

    expect(input.value).toBe("192.168.1.10/24");
  });

  it("normalizes Chinese slash punctuation while typing", () => {
    const input = document.querySelector<HTMLInputElement>("#input-cidr")!;
    input.value = "48.235.24.0、30";
    input.dispatchEvent(new Event("input"));

    expect(input.value).toBe("48.235.24.0/30");
  });

  it("converts Chinese slash punctuation before insertion", () => {
    const input = document.querySelector<HTMLInputElement>("#input-cidr")!;
    input.value = "48.235.24.0";
    input.setSelectionRange(input.value.length, input.value.length);

    input.dispatchEvent(
      new InputEvent("beforeinput", {
        bubbles: true,
        cancelable: true,
        data: "、",
        inputType: "insertText",
      }),
    );

    expect(input.value).toBe("48.235.24.0/");
  });

  it("does not duplicate slash when IME has already inserted one", () => {
    const input = document.querySelector<HTMLInputElement>("#input-cidr")!;
    input.value = "48.235.24.0/";
    input.setSelectionRange(input.value.length, input.value.length);

    input.dispatchEvent(
      new InputEvent("beforeinput", {
        bubbles: true,
        cancelable: true,
        data: "、",
        inputType: "insertText",
      }),
    );

    expect(input.value).toBe("48.235.24.0/");
  });

  it("dedupes history entries and caps the list at eight", () => {
    const input = document.querySelector<HTMLInputElement>("#input-cidr")!;
    const button = document.querySelector<HTMLButtonElement>("#btn-calc")!;

    for (let index = 1; index <= 10; index += 1) {
      input.value = `10.0.${index}.1/24`;
      button.click();
    }
    input.value = "10.0.10.1/24";
    button.click();

    expect(document.querySelectorAll(".history-item")).toHaveLength(8);
    expect(document.querySelector(".history-title")?.textContent).toBe("10.0.10.0/24");
  });

  it("restores both copy button labels independently", () => {
    vi.useFakeTimers();

    document.querySelector<HTMLButtonElement>('[data-mode="v4v6"]')!.click();
    document.querySelector<HTMLInputElement>("#input-ipv4")!.value = "48.235.24.0/30";
    document.querySelector<HTMLInputElement>("#input-ipv6-prefix")!.value = "2001:db8::";
    document.querySelector<HTMLButtonElement>("#btn-calc")!.click();

    const copyNetwork = document.querySelector<HTMLButtonElement>("#btn-copy-network")!;
    const copyAll = document.querySelector<HTMLButtonElement>("#btn-copy-all")!;
    copyNetwork.click();
    copyAll.click();

    expect(copyNetwork.textContent).toBe("已复制");
    expect(copyAll.textContent).toBe("已复制");

    vi.advanceTimersByTime(1400);

    expect(copyNetwork.textContent).toBe("复制 IPv6 网段");
    expect(copyAll.textContent).toBe("复制全部");

    vi.useRealTimers();
  });
});
