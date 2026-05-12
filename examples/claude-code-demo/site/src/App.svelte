<script>
  import { onDestroy, onMount } from 'svelte';

  const LIMITS = {
    cpuCores: 64,
    memoryBytes: 256 * 1024 ** 3,
    diskBytes: 1024 * 1024 ** 4
  };

  const FALLBACK_STATS = {
    generatedAt: null,
    cpu: { usedCores: 0, totalCores: LIMITS.cpuCores, percent: 0 },
    memory: { usedBytes: 0, totalBytes: LIMITS.memoryBytes, percent: 0 },
    disk: { usedBytes: 0, totalBytes: LIMITS.diskBytes, percent: 0 },
    costPerSecondUsd: 0
  };

  let stats = $state(FALLBACK_STATS);
  let status = $state('connecting');
  let timer = null;

  const rows = $derived([
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
  ]);

  function fmtNumber(value, digits) {
    return value.toLocaleString('en-US', {
      minimumFractionDigits: digits,
      maximumFractionDigits: digits
    });
  }

  function fmtBytes(bytes) {
    const gib = bytes / 1024 ** 3;
    if (gib < 1024) return `${fmtNumber(gib, gib < 10 ? 2 : 1)} GiB`;
    const tib = gib / 1024;
    if (tib < 1024) return `${fmtNumber(tib, tib < 10 ? 2 : 1)} TiB`;
    return `${fmtNumber(tib / 1024, 2)} PiB`;
  }

  function clampPercent(percent) {
    return Math.max(0, Math.min(100, percent));
  }

  async function refresh() {
    try {
      const response = await fetch('/stats.json', { cache: 'no-store' });
      if (!response.ok) throw new Error(`stats returned ${response.status}`);
      stats = await response.json();
      status = 'live';
    } catch (error) {
      status = 'waiting';
    }
  }

  onMount(() => {
    refresh();
    timer = window.setInterval(refresh, 1000);
  });

  onDestroy(() => {
    if (timer !== null) window.clearInterval(timer);
  });
</script>

<main class="landing">
  <div class="mark">ix</div>

  <section class="box" aria-label="demo VM resource usage">
    <div class="title">
      <span>demo-vm</span>
      <span class:live={status === 'live'}>{status}</span>
    </div>

    <div class="grid">
      {#each rows as row (row.key)}
        <span class="k">{row.label}</span>
        <span
          class="meter"
          role="meter"
          aria-label={`${row.label} usage`}
          aria-valuemin="0"
          aria-valuemax="100"
          aria-valuenow={Math.round(clampPercent(row.percent))}
          aria-valuetext={row.display}
        >
          <span style={`width: ${clampPercent(row.percent)}%`}></span>
        </span>
        <span class="v">{row.display}</span>
      {/each}
    </div>

    <div class="rule"></div>

    <div class="total">
      <span>COST</span>
      <span></span>
      <strong>${fmtNumber(stats.costPerSecondUsd, 6)}/s</strong>
    </div>
  </section>

  <section class="box" aria-label="shell prompt">
    <div class="title">
      <span>shell</span>
      <span>/src/linux</span>
    </div>
    <pre><span>$</span> btop
<span>$</span> cd /src/linux
<span>$</span> make -j$(nproc) defconfig bzImage</pre>
  </section>
</main>
