# frozen_string_literal: true

#
# Yuno Gasai 2 (Ruby Edition) - Configuration
# Copyright (C) 2025 blubskye
# SPDX-License-Identifier: AGPL-3.0-or-later
#

require 'json'

module Yuno
  class Config
    attr_reader :discord_token, :default_prefix, :database_path, :master_users,
                :spam_max_warnings, :ban_default_image, :dm_message,
                :insufficient_permissions_message

    def initialize(options = {})
      @discord_token = options[:discord_token] || ''
      @default_prefix = options[:default_prefix] || '.'
      @database_path = options[:database_path] || 'yuno.db'
      @master_users = options[:master_users] || []
      @spam_max_warnings = options[:spam_max_warnings] || 3
      @ban_default_image = options[:ban_default_image]
      @dm_message = options[:dm_message] || "I'm just a bot :'(. I can't answer to you."
      @insufficient_permissions_message = options[:insufficient_permissions_message] ||
                                          "${author} You don't have permission to do that~"
    end

    def self.load(path = nil)
      config_path = path || ENV['CONFIG_PATH'] || 'config.json'

      if File.exist?(config_path)
        load_from_file(config_path)
      else
        puts '📝 Config file not found, checking environment...'
        load_from_env
      end
    end

    def self.load_from_file(path)
      data = JSON.parse(File.read(path), symbolize_names: true)

      new(
        discord_token: data[:discord_token],
        default_prefix: data[:default_prefix],
        database_path: data[:database_path],
        master_users: data[:master_users] || [],
        spam_max_warnings: data[:spam_max_warnings],
        ban_default_image: data[:ban_default_image],
        dm_message: data[:dm_message],
        insufficient_permissions_message: data[:insufficient_permissions_message]
      )
    rescue JSON::ParserError => e
      raise "Failed to parse config file: #{e.message}"
    end

    def self.load_from_env
      new(
        discord_token: ENV['DISCORD_TOKEN'],
        default_prefix: ENV['DEFAULT_PREFIX'] || '.',
        database_path: ENV['DATABASE_PATH'] || 'yuno.db',
        master_users: ENV['MASTER_USER'] ? [ENV['MASTER_USER']] : [],
        spam_max_warnings: ENV['SPAM_MAX_WARNINGS']&.to_i || 3,
        dm_message: ENV['DM_MESSAGE']
      )
    end

    def valid?
      !@discord_token.nil? && !@discord_token.empty? &&
        @discord_token != 'YOUR_DISCORD_BOT_TOKEN_HERE'
    end
  end
end
