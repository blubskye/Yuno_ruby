# frozen_string_literal: true

#
# Yuno Gasai 2 (Ruby Edition) - Database
# Copyright (C) 2025 blubskye
# SPDX-License-Identifier: AGPL-3.0-or-later
#

require 'sqlite3'
require 'json'

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
          leveling_enabled INTEGER DEFAULT 1,
          join_dm_title TEXT,
          join_dm_message TEXT,
          level_role_map TEXT
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

        CREATE TABLE IF NOT EXISTS ban_images (
          user_id TEXT NOT NULL,
          guild_id TEXT NOT NULL,
          image_url TEXT NOT NULL,
          PRIMARY KEY (user_id, guild_id)
        );

        CREATE TABLE IF NOT EXISTS mention_responses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          guild_id TEXT NOT NULL,
          trigger_text TEXT NOT NULL,
          response TEXT NOT NULL,
          image_url TEXT
        );

        CREATE INDEX IF NOT EXISTS idx_mod_actions_guild ON mod_actions(guild_id);
        CREATE INDEX IF NOT EXISTS idx_mod_actions_moderator ON mod_actions(moderator_id);
        CREATE INDEX IF NOT EXISTS idx_mod_actions_target ON mod_actions(guild_id, target_id);
        CREATE INDEX IF NOT EXISTS idx_user_xp_guild ON user_xp(guild_id);
        CREATE INDEX IF NOT EXISTS idx_mention_responses_guild ON mention_responses(guild_id);
      SQL
    end

    public

    # Guild settings
    def get_guild_settings(guild_id)
      row = @db.get_first_row(
        'SELECT * FROM guild_settings WHERE guild_id = ?',
        [guild_id.to_s]
      )
      return nil unless row

      {
        prefix: row['prefix'],
        spam_filter_enabled: row['spam_filter_enabled'] == 1,
        leveling_enabled: row['leveling_enabled'] == 1,
        join_dm_title: row['join_dm_title'],
        join_dm_message: row['join_dm_message'],
        level_role_map: row['level_role_map']
      }
    end

    def set_guild_settings(guild_id, settings)
      @db.execute(
        'INSERT OR REPLACE INTO guild_settings (guild_id, prefix, spam_filter_enabled, leveling_enabled, join_dm_title, join_dm_message, level_role_map) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [guild_id.to_s, settings[:prefix], settings[:spam_filter_enabled] ? 1 : 0, settings[:leveling_enabled] ? 1 : 0,
         settings[:join_dm_title], settings[:join_dm_message], settings[:level_role_map]]
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

    def set_spam_filter(guild_id, enabled)
      settings = get_guild_settings(guild_id) || { prefix: '.', leveling_enabled: true }
      settings[:spam_filter_enabled] = enabled
      set_guild_settings(guild_id, settings)
    end

    def set_leveling(guild_id, enabled)
      settings = get_guild_settings(guild_id) || { prefix: '.', spam_filter_enabled: false }
      settings[:leveling_enabled] = enabled
      set_guild_settings(guild_id, settings)
    end

    def set_join_message(guild_id, title, message)
      settings = get_guild_settings(guild_id) || { prefix: '.', spam_filter_enabled: false, leveling_enabled: true }
      settings[:join_dm_title] = title
      settings[:join_dm_message] = message
      set_guild_settings(guild_id, settings)
    end

    def get_level_role_map(guild_id)
      settings = get_guild_settings(guild_id)
      return {} unless settings&.dig(:level_role_map)

      JSON.parse(settings[:level_role_map])
    rescue JSON::ParserError
      {}
    end

    def set_level_role_map(guild_id, role_map)
      settings = get_guild_settings(guild_id) || { prefix: '.', spam_filter_enabled: false, leveling_enabled: true }
      settings[:level_role_map] = JSON.generate(role_map)
      set_guild_settings(guild_id, settings)
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

    def set_xp(user_id, guild_id, xp, level)
      @db.execute(
        'INSERT INTO user_xp (user_id, guild_id, xp, level) VALUES (?, ?, ?, ?) ' \
        'ON CONFLICT(user_id, guild_id) DO UPDATE SET xp = ?, level = ?',
        [user_id.to_s, guild_id.to_s, xp, level, xp, level]
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

    def get_all_users_xp(guild_id)
      @db.execute(
        'SELECT user_id, xp, level FROM user_xp WHERE guild_id = ?',
        [guild_id.to_s]
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

    def get_user_mod_stats(guild_id, moderator_id)
      results = @db.execute(
        'SELECT action_type, COUNT(*) as count FROM mod_actions WHERE guild_id = ? AND moderator_id = ? GROUP BY action_type',
        [guild_id.to_s, moderator_id.to_s]
      )
      stats = { 'ban' => 0, 'kick' => 0, 'timeout' => 0, 'unban' => 0 }
      results.each { |row| stats[row['action_type']] = row['count'] }
      stats
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

    def get_guild_auto_cleans(guild_id)
      @db.execute(
        'SELECT channel_id, interval_minutes, message_count, enabled FROM auto_clean_config WHERE guild_id = ?',
        [guild_id.to_s]
      ).map do |row|
        {
          channel_id: row['channel_id'],
          interval_minutes: row['interval_minutes'],
          message_count: row['message_count'],
          enabled: row['enabled'] == 1
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

    # Ban images
    def set_ban_image(user_id, guild_id, image_url)
      @db.execute(
        'INSERT OR REPLACE INTO ban_images (user_id, guild_id, image_url) VALUES (?, ?, ?)',
        [user_id.to_s, guild_id.to_s, image_url]
      )
    end

    def get_ban_image(user_id, guild_id)
      row = @db.get_first_row(
        'SELECT image_url FROM ban_images WHERE user_id = ? AND guild_id = ?',
        [user_id.to_s, guild_id.to_s]
      )
      row&.dig('image_url')
    end

    def delete_ban_image(user_id, guild_id)
      @db.execute(
        'DELETE FROM ban_images WHERE user_id = ? AND guild_id = ?',
        [user_id.to_s, guild_id.to_s]
      )
    end

    # Mention responses
    def add_mention_response(guild_id, trigger, response, image_url = nil)
      @db.execute(
        'INSERT INTO mention_responses (guild_id, trigger_text, response, image_url) VALUES (?, ?, ?, ?)',
        [guild_id.to_s, trigger, response, image_url]
      )
    end

    def get_mention_response(guild_id, trigger)
      row = @db.get_first_row(
        'SELECT * FROM mention_responses WHERE guild_id = ? AND trigger_text = ?',
        [guild_id.to_s, trigger]
      )
      return nil unless row

      {
        id: row['id'],
        trigger: row['trigger_text'],
        response: row['response'],
        image_url: row['image_url']
      }
    end

    def get_mention_responses(guild_id)
      @db.execute(
        'SELECT * FROM mention_responses WHERE guild_id = ?',
        [guild_id.to_s]
      ).map do |row|
        {
          id: row['id'],
          trigger: row['trigger_text'],
          response: row['response'],
          image_url: row['image_url']
        }
      end
    end

    def delete_mention_response(id)
      @db.execute('DELETE FROM mention_responses WHERE id = ?', [id])
    end

    def delete_mention_response_by_trigger(guild_id, trigger)
      @db.execute(
        'DELETE FROM mention_responses WHERE guild_id = ? AND trigger_text = ?',
        [guild_id.to_s, trigger]
      )
    end
  end
end
