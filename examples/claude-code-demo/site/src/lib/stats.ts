export type ResourceKey = 'cpu' | 'memory' | 'disk';

export type ResourceRow = {
  key: ResourceKey;
  label: string;
  percent: number;
  display: string;
};

export type UsageStats = {
  generatedAt: string | null;
  cpu: {
    usedCores: number;
    totalCores: number;
    percent: number;
  };
  memory: {
    usedBytes: number;
    totalBytes: number;
    percent: number;
  };
  disk: {
    usedBytes: number;
    totalBytes: number;
    percent: number;
  };
  costPerSecondUsd: number;
};

export type Status = 'connecting' | 'live' | 'waiting';

const LIMITS = {
  cpuCores: 64,
  memoryBytes: 256 * 1024 ** 3,
  diskBytes: 1024 * 1024 ** 4
};

export const FALLBACK_STATS: UsageStats = {
  generatedAt: null,
  cpu: { usedCores: 0, totalCores: LIMITS.cpuCores, percent: 0 },
  memory: { usedBytes: 0, totalBytes: LIMITS.memoryBytes, percent: 0 },
  disk: { usedBytes: 0, totalBytes: LIMITS.diskBytes, percent: 0 },
  costPerSecondUsd: 0
};

export function resourceRows(stats: UsageStats): ResourceRow[] {
  return [
    {
      key: 'cpu',
      label: 'CPU',
      percent: stats.cpu.percent,
      display: `${fmtNumber(stats.cpu.usedCores, 2)} / ${fmtNumber(stats.cpu.totalCores, 0)} cores`
    },
    {
      key: 'memory',
      label: 'MEM',
      percent: stats.memory.percent,
      display: `${fmtBytes(stats.memory.usedBytes)} / ${fmtBytes(stats.memory.totalBytes)}`
    },
    {
      key: 'disk',
      label: 'DISK',
      percent: stats.disk.percent,
      display: `${fmtBytes(stats.disk.usedBytes)} / ${fmtBytes(stats.disk.totalBytes)}`
    }
  ];
}

export function fmtNumber(value: number, digits: number): string {
  return value.toLocaleString('en-US', {
    minimumFractionDigits: digits,
    maximumFractionDigits: digits
  });
}

export function clampPercent(percent: number): number {
  return Math.max(0, Math.min(100, percent));
}

export function parseUsageStats(value: unknown): UsageStats | null {
  if (!isRecord(value)) return null;
  if (!(typeof value.generatedAt === 'string' || value.generatedAt === null)) return null;
  if (!isNumber(value.costPerSecondUsd)) return null;

  const cpu = parseCpuStats(value.cpu);
  const memory = parseByteStats(value.memory);
  const disk = parseByteStats(value.disk);
  if (cpu === null || memory === null || disk === null) return null;

  return {
    generatedAt: value.generatedAt,
    cpu,
    memory,
    disk,
    costPerSecondUsd: value.costPerSecondUsd
  };
}

function fmtBytes(bytes: number): string {
  const gib = bytes / 1024 ** 3;
  if (gib < 1024) return `${fmtNumber(gib, gib < 10 ? 2 : 1)} GiB`;
  const tib = gib / 1024;
  if (tib < 1024) return `${fmtNumber(tib, tib < 10 ? 2 : 1)} TiB`;
  return `${fmtNumber(tib / 1024, 2)} PiB`;
}

function parseCpuStats(value: unknown): UsageStats['cpu'] | null {
  if (!isRecord(value)) return null;
  if (!isNumber(value.usedCores) || !isNumber(value.totalCores) || !isNumber(value.percent)) {
    return null;
  }
  return {
    usedCores: value.usedCores,
    totalCores: value.totalCores,
    percent: value.percent
  };
}

function parseByteStats(value: unknown): UsageStats['memory'] | null {
  if (!isRecord(value)) return null;
  if (!isNumber(value.usedBytes) || !isNumber(value.totalBytes) || !isNumber(value.percent)) {
    return null;
  }
  return {
    usedBytes: value.usedBytes,
    totalBytes: value.totalBytes,
    percent: value.percent
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

function isNumber(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value);
}
