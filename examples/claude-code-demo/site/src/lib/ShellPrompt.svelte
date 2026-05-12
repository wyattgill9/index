<script lang="ts">
  import Box from './Box.svelte';
</script>

<Box title="shell" hint="/src/linux">
  <pre><span class="p">$</span> btop
<span class="p">$</span> cd /src/linux
<span class="p">$</span> make -j$(nproc) defconfig bzImage</pre>
</Box>

<style>
  pre {
    margin: 0;
    overflow-x: auto;
    white-space: pre;
    color: var(--ix-ink);
  }

  .p {
    color: var(--ix-ink-faint);
  }
</style>
