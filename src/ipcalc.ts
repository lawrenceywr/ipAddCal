export type IpVersion = 4 | 6;

export type ParsedAddress = {
  version: IpVersion;
  value: bigint;
};

export type NetworkResult = Record<string, string>;

export type NumberBase = "binary" | "decimal" | "hexadecimal";

export type BaseConversionResult = {
  value: bigint;
  binary: string;
  decimal: string;
  hexadecimal: string;
  binary32: string;
};

const IPV4_BITS = 32n;
const IPV6_BITS = 128n;
const IPV4_SIZE = 1n << IPV4_BITS;
const U32_BITS = 32n;
const U32_MAX = (1n << U32_BITS) - 1n;

const INPUT_TRANSLATION: Record<string, string> = {
  "、": "/",
  "。": ".",
  "．": ".",
  "：": ":",
  "／": "/",
  "，": ",",
};

export function normalizeInputText(text: string): string {
  const translated = Array.from(text, (char) => INPUT_TRANSLATION[char] ?? char).join("");
  return translated.normalize("NFKC").replace(/\s+/g, "");
}

export function normalizeBaseNumberText(text: string): string {
  return normalizeInputText(text).replace(/[,_]/g, "");
}

export function convertBaseNumber(text: string, base: NumberBase): BaseConversionResult {
  return formatBaseConversion(parseUnsigned32(text, base));
}

export function formatBaseConversion(value: bigint): BaseConversionResult {
  assertUnsigned32(value);
  return {
    value,
    binary: value.toString(2),
    decimal: value.toString(10),
    hexadecimal: value.toString(16).toUpperCase(),
    binary32: value.toString(2).padStart(Number(U32_BITS), "0"),
  };
}

export function toggleBaseConversionBit(value: bigint, bitIndex: number): BaseConversionResult {
  if (!Number.isInteger(bitIndex) || bitIndex < 0 || bitIndex >= Number(U32_BITS)) {
    throw new Error(`bit index out of range: ${bitIndex}`);
  }
  assertUnsigned32(value);
  return formatBaseConversion(value ^ (1n << BigInt(bitIndex)));
}

function parseUnsigned32(text: string, base: NumberBase): bigint {
  const normalized = normalizeBaseNumberText(text);
  if (!normalized) {
    return 0n;
  }

  let digits = normalized;
  if (base === "binary" && /^0b/i.test(digits)) {
    digits = digits.slice(2);
  } else if (base === "hexadecimal" && /^0x/i.test(digits)) {
    digits = digits.slice(2);
  }

  if (!digits) {
    return 0n;
  }

  let value: bigint;
  if (base === "binary") {
    if (!/^[01]+$/.test(digits)) {
      throw new Error("二进制只能包含 0 和 1");
    }
    value = parseDigits(digits, 2);
  } else if (base === "decimal") {
    if (!/^\d+$/.test(digits)) {
      throw new Error("十进制只能包含 0 到 9");
    }
    value = BigInt(digits);
  } else {
    if (!/^[0-9a-f]+$/i.test(digits)) {
      throw new Error("十六进制只能包含 0-9 和 A-F");
    }
    value = parseDigits(digits, 16);
  }

  assertUnsigned32(value);
  return value;
}

function parseDigits(digits: string, radix: 2 | 16): bigint {
  let value = 0n;
  const bigRadix = BigInt(radix);
  for (const digit of digits.toLowerCase()) {
    value = value * bigRadix + BigInt(Number.parseInt(digit, radix));
    if (value > U32_MAX) {
      throw new Error("数值超出 32 位无符号整数范围");
    }
  }
  return value;
}

function assertUnsigned32(value: bigint): void {
  if (value < 0n || value > U32_MAX) {
    throw new Error("数值超出 32 位无符号整数范围");
  }
}

export function parseInput(values: string[]): [ParsedAddress, number] {
  let addressText: string;
  let prefixText: string;

  if (values.length === 1) {
    if (!values[0].includes("/")) {
      throw new Error("single-argument form must be ADDRESS/PREFIX_OR_MASK");
    }
    const splitIndex = values[0].lastIndexOf("/");
    addressText = values[0].slice(0, splitIndex);
    prefixText = values[0].slice(splitIndex + 1);
  } else if (values.length === 2) {
    [addressText, prefixText] = values;
  } else {
    throw new Error("provide either ADDRESS/PREFIX_OR_MASK or ADDRESS PREFIX_OR_MASK");
  }

  const address = parseIpAddress(addressText);
  const prefixLength = parsePrefix(address, prefixText);
  return [address, prefixLength];
}

export function parseIpv6_96Prefix(prefixText: string): bigint {
  if (!prefixText) {
    throw new Error("IPv6 prefix is required");
  }

  if (prefixText.includes("/")) {
    const [addressText, prefixLengthText] = splitNetwork(prefixText);
    const prefixLength = parseNumericPrefix(prefixLengthText, 128, "IPv6");
    if (prefixLength !== 96) {
      throw new Error("IPv6 prefix must be /96");
    }
    const address = parseIpv6Address(addressText);
    return networkAddress(address, 96, IPV6_BITS);
  }

  let address: bigint;
  try {
    address = parseIpv6Address(prefixText);
  } catch (error) {
    throw new Error(`invalid IPv6 prefix: ${prefixText}`, { cause: error });
  }

  const prefixNetwork = networkAddress(address, 96, IPV6_BITS);
  if (address !== prefixNetwork) {
    throw new Error("IPv6 /96 prefix must not contain bits in the last 32 bits");
  }
  return prefixNetwork;
}

export function calculateNetwork(address: ParsedAddress, prefixLength: number): NetworkResult {
  const bitLength = address.version === 4 ? IPV4_BITS : IPV6_BITS;
  const network = networkAddress(address.value, prefixLength, bitLength);
  const addressCount = 1n << (bitLength - BigInt(prefixLength));
  const lastAddress = network + addressCount - 1n;

  const result: NetworkResult = {
    network: `${formatAddress(address.version, network)}/${prefixLength}`,
    address_count: addressCount.toString(),
    first_address: formatAddress(address.version, network),
    last_address: formatAddress(address.version, lastAddress),
  };

  if (address.version === 4 && prefixLength >= 16 && prefixLength <= 24) {
    result.class_c_count = (1n << BigInt(24 - prefixLength)).toString();
  }

  return result;
}

export function generateIpv6FromIpv4(
  address: ParsedAddress,
  prefixLength: number,
  ipv6PrefixText: string,
): NetworkResult {
  if (address.version !== 4) {
    throw new Error("IPv4 to IPv6 generation requires an IPv4 address or network");
  }

  const ipv4Network = networkAddress(address.value, prefixLength, IPV4_BITS);
  const ipv6Prefix = parseIpv6_96Prefix(ipv6PrefixText);
  const ipv6PrefixLength = 96 + prefixLength;
  const ipv6Address = ipv6Prefix | ipv4Network;
  const ipv6Network = networkAddress(ipv6Address, ipv6PrefixLength, IPV6_BITS);
  const addressCount = 1n << (IPV6_BITS - BigInt(ipv6PrefixLength));

  return {
    ipv4_network: `${formatIpv4Address(ipv4Network)}/${prefixLength}`,
    ipv6_prefix: `${formatIpv6Address(ipv6Prefix)}/96`,
    ipv6_network: `${formatIpv6Address(ipv6Network)}/${ipv6PrefixLength}`,
    address_count: addressCount.toString(),
    first_address: formatIpv6Address(ipv6Network),
    last_address: formatIpv6Address(ipv6Network + addressCount - 1n),
  };
}

export function generateIpv4FromIpv6(ipv6Text: string, ipv6PrefixText = ""): NetworkResult {
  const [address, prefixLength] = parseIpv6NetworkInput(ipv6Text);
  if (prefixLength < 96) {
    throw new Error("IPv6 network prefix length must be between /96 and /128");
  }

  const ipv6Network = networkAddress(address.value, prefixLength, IPV6_BITS);
  const ipv6Prefix = networkAddress(ipv6Network, 96, IPV6_BITS);
  if (ipv6PrefixText) {
    const expectedPrefix = parseIpv6_96Prefix(ipv6PrefixText);
    if (ipv6Prefix !== expectedPrefix) {
      throw new Error("IPv6 /96 prefix does not match the IPv6 address or network");
    }
  }

  const ipv4PrefixLength = prefixLength - 96;
  const ipv4Network = networkAddress(ipv6Network & (IPV4_SIZE - 1n), ipv4PrefixLength, IPV4_BITS);
  const addressCount = 1n << (IPV4_BITS - BigInt(ipv4PrefixLength));

  return {
    ipv6_prefix: `${formatIpv6Address(ipv6Prefix)}/96`,
    ipv6_network: `${formatIpv6Address(ipv6Network)}/${prefixLength}`,
    ipv4_network: `${formatIpv4Address(ipv4Network)}/${ipv4PrefixLength}`,
    address_count: addressCount.toString(),
    first_address: formatIpv4Address(ipv4Network),
    last_address: formatIpv4Address(ipv4Network + addressCount - 1n),
  };
}

export function formatStandardRows(result: NetworkResult): Array<[string, string]> {
  const rows: Array<[string, string]> = [
    ["网段", result.network],
    ["地址数量", result.address_count],
    ["首个地址", result.first_address],
    ["最后地址", result.last_address],
  ];
  if (result.class_c_count !== undefined) {
    rows.push(["C段数量", result.class_c_count]);
  }
  return rows;
}

export function formatIpv4ToIpv6Rows(result: NetworkResult): Array<[string, string]> {
  return [
    ["IPv4 网段", result.ipv4_network],
    ["IPv6 前缀", result.ipv6_prefix],
    ["IPv6 网段", result.ipv6_network],
    ["地址数量", result.address_count],
    ["首个地址", result.first_address],
    ["最后地址", result.last_address],
  ];
}

export function formatIpv6ToIpv4Rows(result: NetworkResult): Array<[string, string]> {
  return [
    ["IPv6 前缀", result.ipv6_prefix],
    ["IPv6 网段", result.ipv6_network],
    ["IPv4 网段", result.ipv4_network],
    ["地址数量", result.address_count],
    ["首个 IPv4", result.first_address],
    ["最后 IPv4", result.last_address],
  ];
}

export function formatRowsForClipboard(rows: Array<[string, string]>): string {
  return rows.map(([label, value]) => `${label}: ${value}`).join("\n");
}

export function formatParsedAddress(address: ParsedAddress): string {
  return formatAddress(address.version, address.value);
}

function parseIpAddress(addressText: string): ParsedAddress {
  if (addressText.includes(":")) {
    try {
      return { version: 6, value: parseIpv6Address(addressText) };
    } catch (error) {
      throw new Error(`invalid IP address: ${addressText}`, { cause: error });
    }
  }

  try {
    return { version: 4, value: parseIpv4Address(addressText) };
  } catch (error) {
    throw new Error(`invalid IP address: ${addressText}`, { cause: error });
  }
}

function parseIpv6NetworkInput(networkText: string): [ParsedAddress, number] {
  if (!networkText) {
    throw new Error("IPv6 address or network is required");
  }

  if (networkText.includes("/")) {
    const [address, prefixLength] = parseInput([networkText]);
    if (address.version !== 6) {
      throw new Error("IPv6 to IPv4 reverse calculation requires an IPv6 address or network");
    }
    return [address, prefixLength];
  }

  try {
    return [{ version: 6, value: parseIpv6Address(networkText) }, 128];
  } catch (error) {
    throw new Error(`invalid IPv6 address: ${networkText}`, { cause: error });
  }
}

function parsePrefix(address: ParsedAddress, prefixText: string): number {
  if (address.version === 4 && prefixText.includes(".")) {
    let mask: bigint;
    try {
      mask = parseIpv4Address(prefixText);
    } catch (error) {
      throw new Error(`invalid IPv4 netmask: ${prefixText}`, { cause: error });
    }

    const prefixLength = prefixLengthFromIpv4Netmask(mask);
    if (prefixLength === null || prefixText !== formatIpv4Netmask(prefixLength)) {
      throw new Error(`invalid IPv4 netmask: ${prefixText}`);
    }
    return prefixLength;
  }

  if (address.version === 6 && prefixText.includes(".")) {
    throw new Error("IPv6 requires a numeric prefix length");
  }

  return parseNumericPrefix(prefixText, address.version === 4 ? 32 : 128, `IPv${address.version}`);
}

function parseNumericPrefix(prefixText: string, maxPrefix: number, versionLabel: string): number {
  if (!/^[+-]?\d+$/.test(prefixText)) {
    throw new Error(`invalid prefix length: ${prefixText}`);
  }
  const prefixLength = Number(prefixText);
  if (!Number.isSafeInteger(prefixLength)) {
    throw new Error(`invalid prefix length: ${prefixText}`);
  }
  if (prefixLength < 0 || prefixLength > maxPrefix) {
    throw new Error(`prefix length out of range for ${versionLabel}: ${prefixLength}`);
  }
  return prefixLength;
}

function parseIpv4Address(addressText: string): bigint {
  const parts = addressText.split(".");
  if (parts.length !== 4) {
    throw new Error("IPv4 address must contain four octets");
  }

  let value = 0n;
  for (const part of parts) {
    if (!/^\d+$/.test(part) || (part.length > 1 && part.startsWith("0"))) {
      throw new Error("invalid IPv4 octet");
    }
    const octet = Number(part);
    if (!Number.isInteger(octet) || octet < 0 || octet > 255) {
      throw new Error("IPv4 octet out of range");
    }
    value = (value << 8n) | BigInt(octet);
  }
  return value;
}

function parseIpv6Address(addressText: string): bigint {
  if (!addressText || addressText.includes(":::")) {
    throw new Error("invalid IPv6 address");
  }

  const doubleColonParts = addressText.toLowerCase().split("::");
  if (doubleColonParts.length > 2) {
    throw new Error("invalid IPv6 address");
  }

  const head = parseIpv6Hextets(doubleColonParts[0]);
  const tail = doubleColonParts.length === 2 ? parseIpv6Hextets(doubleColonParts[1]) : [];
  const missing = 8 - head.length - tail.length;

  if (doubleColonParts.length === 1 && missing !== 0) {
    throw new Error("invalid IPv6 address");
  }
  if (doubleColonParts.length === 2 && missing < 1) {
    throw new Error("invalid IPv6 address");
  }

  const groups = [...head, ...Array<number>(missing).fill(0), ...tail];
  return groups.reduce((value, group) => (value << 16n) | BigInt(group), 0n);
}

function parseIpv6Hextets(section: string): number[] {
  if (!section) {
    return [];
  }
  return section.split(":").map((part) => {
    if (!/^[0-9a-f]{1,4}$/i.test(part)) {
      throw new Error("invalid IPv6 hextet");
    }
    return Number.parseInt(part, 16);
  });
}

function splitNetwork(networkText: string): [string, string] {
  const parts = networkText.split("/");
  if (parts.length !== 2) {
    throw new Error("invalid network");
  }
  return [parts[0], parts[1]];
}

function prefixLengthFromIpv4Netmask(mask: bigint): number | null {
  let seenZero = false;
  let prefixLength = 0;
  for (let bit = 31; bit >= 0; bit -= 1) {
    const isOne = (mask & (1n << BigInt(bit))) !== 0n;
    if (isOne && seenZero) {
      return null;
    }
    if (isOne) {
      prefixLength += 1;
    } else {
      seenZero = true;
    }
  }
  return prefixLength;
}

function formatIpv4Netmask(prefixLength: number): string {
  return formatIpv4Address(networkMask(prefixLength, IPV4_BITS) & (IPV4_SIZE - 1n));
}

function networkAddress(address: bigint, prefixLength: number, bitLength: bigint): bigint {
  return address & networkMask(prefixLength, bitLength);
}

function networkMask(prefixLength: number, bitLength: bigint): bigint {
  if (prefixLength === 0) {
    return 0n;
  }
  const hostBits = bitLength - BigInt(prefixLength);
  const size = 1n << bitLength;
  return (size - 1n) ^ ((1n << hostBits) - 1n);
}

function formatAddress(version: IpVersion, value: bigint): string {
  return version === 4 ? formatIpv4Address(value) : formatIpv6Address(value);
}

function formatIpv4Address(value: bigint): string {
  const octets: string[] = [];
  for (let shift = 24; shift >= 0; shift -= 8) {
    octets.push(Number((value >> BigInt(shift)) & 255n).toString());
  }
  return octets.join(".");
}

function formatIpv6Address(value: bigint): string {
  const groups = Array.from({ length: 8 }, (_, index) =>
    Number((value >> BigInt((7 - index) * 16)) & 0xffffn),
  );
  const [bestStart, bestLength] = longestZeroRun(groups);
  const rendered: string[] = [];

  for (let index = 0; index < groups.length; index += 1) {
    if (bestLength >= 2 && index === bestStart) {
      rendered.push("");
      index += bestLength - 1;
      if (index === groups.length - 1) {
        rendered.push("");
      }
      continue;
    }
    rendered.push(groups[index].toString(16));
  }

  const text = rendered.join(":");
  return text.startsWith(":") ? `:${text}` : text;
}

function longestZeroRun(groups: number[]): [number, number] {
  let bestStart = -1;
  let bestLength = 0;
  let currentStart = -1;
  let currentLength = 0;

  groups.forEach((group, index) => {
    if (group === 0) {
      if (currentStart === -1) {
        currentStart = index;
        currentLength = 0;
      }
      currentLength += 1;
      if (currentLength > bestLength) {
        bestStart = currentStart;
        bestLength = currentLength;
      }
    } else {
      currentStart = -1;
      currentLength = 0;
    }
  });

  return [bestStart, bestLength];
}
