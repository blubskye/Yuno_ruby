# frozen_string_literal: true

#
# Yuno Gasai 2 (Ruby Edition) - Auto Cleaner Module
# Copyright (C) 2025 blubskye
# SPDX-License-Identifier: AGPL-3.0-or-later
#

module Yuno
  module Modules
    class AutoCleaner
      MAX_DELAYS = 3

      def initialize(bot)
        @bot = bot
        @delays = {} # { "guild_id:channel_id" => { count: 0, until: Time } }
        @running = false
      end

      def start
        return if @running

        @running = true
        @thread = Thread.new { run_loop }
        puts '🧹 Auto-cleaner started~'
      end

      def stop
        @running = false
        @thread&.kill
        puts '🧹 Auto-cleaner stopped~'
      end

      def delay(guild_id, channel_id, minutes = 5)
        key = "#{guild_id}:#{channel_id}"
        @delays[key] ||= { count: 0, until: nil }

        return false if @delays[key][:count] >= MAX_DELAYS

        @delays[key][:count] += 1
        @delays[key][:until] = Time.now + (minutes * 60)
        true
      end

      def remaining_delays(guild_id, channel_id)
        key = "#{guild_id}:#{channel_id}"
        MAX_DELAYS - (@delays.dig(key, :count) || 0)
      end

      def reset_delays(guild_id, channel_id)
        key = "#{guild_id}:#{channel_id}"
        @delays.delete(key)
      end

      private

      def run_loop
        while @running
          check_channels
          sleep 60 # Check every minute
        end
      end

      def check_channels
        configs = @bot.database.get_all_auto_clean_configs

        configs.each do |config|
          key = "#{config[:guild_id]}:#{config[:channel_id]}"

          # Check if delayed
          if @delays[key] && @delays[key][:until] && Time.now < @delays[key][:until]
            next
          end

          # Would perform cleaning here
          clean_channel(config[:channel_id], config[:message_count])

          # Reset delays after clean
          reset_delays(config[:guild_id], config[:channel_id])
        end
      rescue StandardError => e
        puts "Auto-cleaner error: #{e.message}"
      end

      def clean_channel(channel_id, max_messages)
        channel = @bot.client.channel(channel_id)
        return unless channel

        messages = channel.history(100)
        return if messages.count <= max_messages

        # Delete oldest messages beyond max_messages
        to_delete = messages.sort_by(&:timestamp)[0..-(max_messages + 1)]
        return if to_delete.empty?

        channel.delete_messages(to_delete)
        puts "🧹 Cleaned #{to_delete.count} messages from channel #{channel_id}~"
      rescue StandardError => e
        puts "Failed to clean channel #{channel_id}: #{e.message}"
      end
    end
  end
end
