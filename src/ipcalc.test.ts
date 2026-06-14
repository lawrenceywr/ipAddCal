import { describe, expect, it } from "vitest";

import {
  calculateNetwork,
  convertBaseNumber,
  formatBaseConversion,
  generateIpv4FromIpv6,
  generateIpv6FromIpv4,
  normalizeInputText,
  parseInput,
  toggleBaseConversionBit,
} from "./ipcalc";

describe("IP calculator", () => {
  it("handles IPv4 CIDR input", () => {
    const [address, prefixLength] = parseInput(["192.168.1.10/24"]);
    expect(calculateNetwork(address, prefixLength)).toEqual({
      network: "192.168.1.0/24",
      address_count: "256",
      first_address: "192.168.1.0",
      last_address: "192.168.1.255",
      class_c_count: "1",
    });
  });

  it("handles IPv4 dotted mask input", () => {
    const [address, prefixLength] = parseInput(["10.0.0.7", "255.255.255.248"]);
    expect(calculateNetwork(address, prefixLength)).toEqual({
      network: "10.0.0.0/29",
      address_count: "8",
      first_address: "10.0.0.0",
      last_address: "10.0.0.7",
    });
  });

  it("handles IPv4 numeric prefix input", () => {
    const [address, prefixLength] = parseInput(["10.0.0.7", "29"]);
    expect(calculateNetwork(address, prefixLength)).toEqual({
      network: "10.0.0.0/29",
      address_count: "8",
      first_address: "10.0.0.0",
      last_address: "10.0.0.7",
    });
  });

  it("handles IPv6 CIDR input", () => {
    const [address, prefixLength] = parseInput(["2001:db8::1/126"]);
    expect(calculateNetwork(address, prefixLength)).toEqual({
      network: "2001:db8::/126",
      address_count: "4",
      first_address: "2001:db8::",
      last_address: "2001:db8::3",
    });
  });

  it("handles IPv6 numeric prefix input", () => {
    const [address, prefixLength] = parseInput(["2001:db8::1", "126"]);
    expect(calculateNetwork(address, prefixLength)).toEqual({
      network: "2001:db8::/126",
      address_count: "4",
      first_address: "2001:db8::",
      last_address: "2001:db8::3",
    });
  });

  it("generates IPv6 network from IPv4 network", () => {
    const [address, prefixLength] = parseInput(["48.235.24.0/30"]);
    expect(generateIpv6FromIpv4(address, prefixLength, "2001:db8::")).toEqual({
      ipv4_network: "48.235.24.0/30",
      ipv6_prefix: "2001:db8::/96",
      ipv6_network: "2001:db8::30eb:1800/126",
      address_count: "4",
      first_address: "2001:db8::30eb:1800",
      last_address: "2001:db8::30eb:1803",
    });
  });

  it("reverses IPv6 network suffixes back to IPv4 networks", () => {
    expect(generateIpv4FromIpv6("2001:db8::30eb:1800/126", "2001:db8::")).toEqual({
      ipv6_prefix: "2001:db8::/96",
      ipv6_network: "2001:db8::30eb:1800/126",
      ipv4_network: "48.235.24.0/30",
      address_count: "4",
      first_address: "48.235.24.0",
      last_address: "48.235.24.3",
    });
  });

  it("treats IPv6 addresses without a prefix as single IPv4 addresses", () => {
    expect(generateIpv4FromIpv6("2001:db8::30eb:1801")).toEqual({
      ipv6_prefix: "2001:db8::/96",
      ipv6_network: "2001:db8::30eb:1801/128",
      ipv4_network: "48.235.24.1/32",
      address_count: "1",
      first_address: "48.235.24.1",
      last_address: "48.235.24.1",
    });
  });

  it("rejects IPv6 to IPv4 reverse inputs outside the last 32 bits", () => {
    expect(() => generateIpv4FromIpv6("2001:db8::/95")).toThrow("between /96 and /128");
  });

  it("validates the optional IPv6 /96 prefix for reverse calculation", () => {
    expect(() => generateIpv4FromIpv6("2001:db8::30eb:1800/126", "2001:db9::")).toThrow(
      "does not match",
    );
  });

  it("requires a /96 IPv6 prefix for IPv4 to IPv6 generation", () => {
    const [address, prefixLength] = parseInput(["48.235.24.0/30"]);
    expect(() => generateIpv6FromIpv4(address, prefixLength, "2001:db8::1")).toThrow(
      "/96 prefix",
    );
  });

  it("rejects invalid netmasks", () => {
    expect(() => parseInput(["10.0.0.7", "255.0.255.0"])).toThrow("invalid IPv4 netmask");
  });

  it("rejects IPv4 hostmask two-argument form", () => {
    expect(() => parseInput(["10.0.0.7", "0.0.0.255"])).toThrow("invalid IPv4 netmask");
  });

  it("rejects IPv4 hostmask single-argument form", () => {
    expect(() => parseInput(["10.0.0.7/0.0.0.255"])).toThrow("invalid IPv4 netmask");
  });

  it("rejects invalid IPv4 prefix length", () => {
    expect(() => parseInput(["10.0.0.7", "33"])).toThrow("prefix length out of range for IPv4");
  });

  it("rejects dotted masks for IPv6", () => {
    expect(() => parseInput(["2001:db8::1", "255.255.255.0"])).toThrow(
      "IPv6 requires a numeric prefix length",
    );
  });

  it("handles prefix boundaries", () => {
    const cases = [
      ["0.0.0.1", "0", "0.0.0.0/0", "4294967296", "0.0.0.0", "255.255.255.255"],
      ["192.168.1.10", "32", "192.168.1.10/32", "1", "192.168.1.10", "192.168.1.10"],
      ["10.0.0.1", "31", "10.0.0.0/31", "2", "10.0.0.0", "10.0.0.1"],
      ["2001:db8::1", "128", "2001:db8::1/128", "1", "2001:db8::1", "2001:db8::1"],
    ];

    for (const [addressText, prefixText, network, count, first, last] of cases) {
      const [address, prefixLength] = parseInput([addressText, prefixText]);
      expect(calculateNetwork(address, prefixLength)).toEqual({
        network,
        address_count: count,
        first_address: first,
        last_address: last,
      });
    }
  });

  it("normalizes full-width punctuation and whitespace", () => {
    expect(normalizeInputText("  １９２．１６８．１．１０／２４ ")).toBe("192.168.1.10/24");
    expect(normalizeInputText("2001：db8：：")).toBe("2001:db8::");
    expect(normalizeInputText("48.235.24.0、30")).toBe("48.235.24.0/30");
  });

  it("converts between binary, decimal, and hexadecimal within 32 bits", () => {
    expect(convertBaseNumber("255", "decimal")).toMatchObject({
      binary: "11111111",
      decimal: "255",
      hexadecimal: "FF",
      binary32: "00000000000000000000000011111111",
    });
    expect(convertBaseNumber("0b1010", "binary").decimal).toBe("10");
    expect(convertBaseNumber("0xff", "hexadecimal").binary).toBe("11111111");
  });

  it("supports the maximum unsigned 32-bit value", () => {
    expect(convertBaseNumber("FFFFFFFF", "hexadecimal")).toMatchObject({
      decimal: "4294967295",
      binary32: "1".repeat(32),
    });
  });

  it("rejects base conversion values outside 32 bits", () => {
    expect(() => convertBaseNumber("4294967296", "decimal")).toThrow("32 位");
    expect(() => convertBaseNumber("1".repeat(33), "binary")).toThrow("32 位");
  });

  it("toggles individual 32-bit display bits", () => {
    expect(toggleBaseConversionBit(0n, 31)).toMatchObject({
      hexadecimal: "80000000",
      binary32: `1${"0".repeat(31)}`,
    });
    expect(toggleBaseConversionBit(formatBaseConversion(8n).value, 3).decimal).toBe("0");
  });
});
