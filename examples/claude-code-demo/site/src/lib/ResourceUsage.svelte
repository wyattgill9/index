<script lang="ts">
  import { clampPercent, fmtNumber, resourceRows, type Status, type UsageStats } from './stats';

  type Props = {
    stats: UsageStats;
    status: Status;
  };

  const { stats, status }: Props = $props();
  const rows = $derived(resourceRows(stats));
</script>

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
        <span style:width={`${String(clampPercent(row.percent))}%`}></span>
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
