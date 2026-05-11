package dev.ix.minecraft;

import org.bukkit.Bukkit;
import org.bukkit.ChatColor;
import org.bukkit.World;
import org.bukkit.entity.Player;
import org.bukkit.plugin.java.JavaPlugin;
import org.bukkit.scheduler.BukkitTask;
import org.bukkit.scoreboard.DisplaySlot;
import org.bukkit.scoreboard.Objective;
import org.bukkit.scoreboard.Scoreboard;
import org.bukkit.scoreboard.ScoreboardManager;

public final class TimeScoreboardPlugin extends JavaPlugin {
    private BukkitTask task;

    @Override
    public void onEnable() {
        // Run once per second; scoreboard values only need human-scale updates.
        task = Bukkit.getScheduler().runTaskTimer(this, this::updateScoreboards, 0L, 20L);
    }

    @Override
    public void onDisable() {
        if (task != null) {
            task.cancel();
        }

        ScoreboardManager manager = Bukkit.getScoreboardManager();
        if (manager != null) {
            for (Player player : Bukkit.getOnlinePlayers()) {
                player.setScoreboard(manager.getMainScoreboard());
            }
        }
    }

    private void updateScoreboards() {
        ScoreboardManager manager = Bukkit.getScoreboardManager();
        if (manager == null) {
            return;
        }

        for (Player player : Bukkit.getOnlinePlayers()) {
            // Build a fresh board per player so unloading/reloading the plugin
            // leaves no shared scoreboard state behind.
            World world = player.getWorld();
            long worldTime = world.getTime();
            long gameTime = world.getFullTime();

            Scoreboard board = manager.getNewScoreboard();
            Objective objective = board.registerNewObjective(
                "ix_time",
                "dummy",
                ChatColor.GOLD + "Claude Code Demo"
            );
            objective.setDisplaySlot(DisplaySlot.SIDEBAR);
            objective.getScore(ChatColor.YELLOW + "Clock: " + formatClock(worldTime)).setScore(3);
            objective.getScore(ChatColor.AQUA + "Day: " + (gameTime / 24000L)).setScore(2);
            objective.getScore(ChatColor.GREEN + "World tick: " + worldTime).setScore(1);
            objective.getScore(ChatColor.GRAY + "Game tick: " + gameTime).setScore(0);

            player.setScoreboard(board);
        }
    }

    private static String formatClock(long worldTime) {
        long minutesSinceMidnight = (worldTime + 6000L) % 24000L * 60L / 1000L;
        long hours = minutesSinceMidnight / 60L;
        long minutes = minutesSinceMidnight % 60L;
        return String.format("%02d:%02d", hours, minutes);
    }
}
