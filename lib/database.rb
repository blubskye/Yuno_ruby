# frozen_string_literal: true

#
# Yuno Gasai 2 (Ruby Edition) - Database
# Copyright (C) 2025 blubskye
# SPDX-License-Identifier: AGPL-3.0-or-later
#

require 'sqlite3'

module Yuno
  class Database
    def initialize(path)
      @db = SQLite3::Database.new(path)
      @db.results_as_hash = true
      initialize_schema
    end

    def close
      @db.close
    end

    private

    def initialize_schema
      @db.execute_batch(<<~SQL)
        CREATE TABLE IF NOT EXISTS guild_settings (
          guild_id TEXT PRIMARY KEY,
          prefix TEXT DEFAULT '.',
          spam_filter_enabled INTEGER DEFAULT 0,
          leveling_enabled INTEGER DEFAULT 1
        );

        CREATE TABLE IF NOT EXISTS user_xp (
          user_id TEXT NOT NULL,
          guild_id TEXT NOT NULL,
          xp INTEGER DEFAULT 0,
          level INTEGER DEFAULT 0,
          PRIMARY KEY (user_id, guild_id)
        );

        CREATE TABLE IF NOT EXISTS mod_actions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          guild_id TEXT NOT NULL,
          moderator_id TEXT NOT NULL,
          target_id TEXT NOT NULL,
          action_type TEXT NOT NULL,
          reason TEXT,
          timestamp INTEGER NOT NULL
        );

        CREATE TABLE IF NOT EXISTS auto_clean_config (
          guild_id TEXT NOT NULL,
          channel_id TEXT NOT NULL,
          interval_minutes INTEGER DEFAULT 60,
          message_count INTEGER DEFAULT 100,
          enabled INTEGER DEFAULT 1,
          PRIMARY KEY (guild_id, channel_id)
        );

        CREATE TABLE IF NOT EXISTS spam_warnings (
          user_id TEXT NOT NULL,
          guild_id TEXT NOT NULL,
          warnings INTEGER DEFAULT 0,
          last_warning INTEGER,
          PRIMARY KEY (user_id, guild_id)
        );

        CREATE INDEX IF NOT EXISTS idx_mod_actions_guild ON mod_actions(guild_id);
        CREATE INDEX IF NOT EXISTS idx_mod_actions_moderator ON mod_actions(moderator_id);
        CREATE INDEX IF NOT EXISTS idx_user_xp_guild ON user_xp(guild_id);
      SQL
    end

    public

    # Guild settings
    def get_guild_settings(guild_id)
      row = @db.get_first_row(
        'SELECT prefix, spam_filter_enabled, leveling_enabled FROM guild_settings WHERE guild_id = ?',
        [guild_id.to_s]
      )
      return nil unless row

      {
        prefix: row['prefix'],
        spam_filter_enabled: row['spam_filter_enabled'] == 1,
        leveling_enabled: row['leveling_enabled'] == 1
      }
    end

    def set_guild_settings(guild_id, settings)
      @db.execute(
        'INSERT OR REPLACE INTO guild_settings (guild_id, prefix, spam_filter_enabled, leveling_enabled) VALUES (?, ?, ?, ?)',
        [guild_id.to_s, settings[:prefix], settings[:spam_filter_enabled] ? 1 : 0, settings[:leveling_enabled] ? 1 : 0]
      )
    end

    def get_prefix(guild_id)
      row = @db.get_first_row('SELECT prefix FROM guild_settings WHERE guild_id = ?', [guild_id.to_s])
      row&.dig('prefix')
    end

    def set_prefix(guild_id, prefix)
      @db.execute(
        'INSERT INTO guild_settings (guild_id, prefix) VALUES (?, ?) ON CONFLICT(guild_id) DO UPDATE SET prefix = ?',
        [guild_id.to_s, prefix, prefix]
      )
    end

    # XP/Leveling
    def get_user_xp(user_id, guild_id)
      row = @db.get_first_row(
        'SELECT xp, level FROM user_xp WHERE user_id = ? AND guild_id = ?',
        [user_id.to_s, guild_id.to_s]
      )
      { xp: row&.dig('xp') || 0, level: row&.dig('level') || 0 }
    end

    def add_xp(user_id, guild_id, amount)
      @db.execute(
        'INSERT INTO user_xp (user_id, guild_id, xp, level) VALUES (?, ?, ?, 0) ' \
        'ON CONFLICT(user_id, guild_id) DO UPDATE SET xp = xp + ?',
        [user_id.to_s, guild_id.to_s, amount, amount]
      )
    end

    def set_level(user_id, guild_id, level)
      @db.execute(
        'UPDATE user_xp SET level = ? WHERE user_id = ? AND guild_id = ?',
        [level, user_id.to_s, guild_id.to_s]
      )
    end

    def get_leaderboard(guild_id, limit = 10)
      @db.execute(
        'SELECT user_id, xp, level FROM user_xp WHERE guild_id = ? ORDER BY xp DESC LIMIT ?',
        [guild_id.to_s, limit]
      ).map do |row|
        { user_id: row['user_id'], xp: row['xp'], level: row['level'] }
      end
    end

    # Mod actions
    def log_mod_action(guild_id:, moderator_id:, target_id:, action_type:, reason: nil)
      @db.execute(
        'INSERT INTO mod_actions (guild_id, moderator_id, target_id, action_type, reason, timestamp) VALUES (?, ?, ?, ?, ?, ?)',
        [guild_id.to_s, moderator_id.to_s, target_id.to_s, action_type, reason, Time.now.to_i]
      )
    end

    def get_mod_actions(guild_id, limit = 100)
      @db.execute(
        'SELECT id, moderator_id, target_id, action_type, reason, timestamp FROM mod_actions WHERE guild_id = ? ORDER BY timestamp DESC LIMIT ?',
        [guild_id.to_s, limit]
      ).map do |row|
        {
          id: row['id'],
          moderator_id: row['moderator_id'],
          target_id: row['target_id'],
          action_type: row['action_type'],
          reason: row['reason'],
          timestamp: row['timestamp']
        }
      end
    end

    def get_mod_stats(guild_id)
      @db.execute(
        'SELECT moderator_id, action_type, COUNT(*) as count FROM mod_actions WHERE guild_id = ? GROUP BY moderator_id, action_type',
        [guild_id.to_s]
      ).each_with_object({}) do |row, stats|
        mod_id = row['moderator_id']
        stats[mod_id] ||= {}
        stats[mod_id][row['action_type']] = row['count']
      end
    end

    # Auto-clean
    def get_auto_clean_config(guild_id, channel_id)
      row = @db.get_first_row(
        'SELECT interval_minutes, message_count, enabled FROM auto_clean_config WHERE guild_id = ? AND channel_id = ?',
        [guild_id.to_s, channel_id.to_s]
      )
      return nil unless row

      {
        interval_minutes: row['interval_minutes'],
        message_count: row['message_count'],
        enabled: row['enabled'] == 1
      }
    end

    def set_auto_clean_config(guild_id, channel_id, config)
      @db.execute(
        'INSERT OR REPLACE INTO auto_clean_config (guild_id, channel_id, interval_minutes, message_count, enabled) VALUES (?, ?, ?, ?, ?)',
        [guild_id.to_s, channel_id.to_s, config[:interval_minutes], config[:message_count], config[:enabled] ? 1 : 0]
      )
    end

    def remove_auto_clean_config(guild_id, channel_id)
      @db.execute(
        'DELETE FROM auto_clean_config WHERE guild_id = ? AND channel_id = ?',
        [guild_id.to_s, channel_id.to_s]
      )
    end

    def get_all_auto_clean_configs
      @db.execute('SELECT guild_id, channel_id, interval_minutes, message_count FROM auto_clean_config WHERE enabled = 1')
         .map do |row|
        {
          guild_id: row['guild_id'],
          channel_id: row['channel_id'],
          interval_minutes: row['interval_minutes'],
          message_count: row['message_count']
        }
      end
    end

    # Spam warnings
    def add_spam_warning(user_id, guild_id)
      @db.execute(
        'INSERT INTO spam_warnings (user_id, guild_id, warnings, last_warning) VALUES (?, ?, 1, ?) ' \
        'ON CONFLICT(user_id, guild_id) DO UPDATE SET warnings = warnings + 1, last_warning = ?',
        [user_id.to_s, guild_id.to_s, Time.now.to_i, Time.now.to_i]
      )
    end

    def get_spam_warnings(user_id, guild_id)
      row = @db.get_first_row(
        'SELECT warnings FROM spam_warnings WHERE user_id = ? AND guild_id = ?',
        [user_id.to_s, guild_id.to_s]
      )
      row&.dig('warnings') || 0
    end

    def reset_spam_warnings(user_id, guild_id)
      @db.execute(
        'DELETE FROM spam_warnings WHERE user_id = ? AND guild_id = ?',
        [user_id.to_s, guild_id.to_s]
      )
    end
  end
end
