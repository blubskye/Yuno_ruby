# frozen_string_literal: true

#
# Yuno Gasai 2 (Ruby Edition) - Spam Filter Module
# Copyright (C) 2025 blubskye
# SPDX-License-Identifier: AGPL-3.0-or-later
#

module Yuno
  module Modules
    class SpamFilter
      MAX_MESSAGES_PER_INTERVAL = 5
      INTERVAL_SECONDS = 5
      DUPLICATE_THRESHOLD = 3
      HISTORY_CLEANUP_SECONDS = 60

      def initialize(bot)
        @bot = bot
        @message_history = {} # { "user_id:guild_id" => [{ timestamp:, content_hash: }] }
      end

      def check(event)
        return false unless spam_filter_enabled?(event.server.id)

        key = "#{event.author.id}:#{event.server.id}"
        @message_history[key] ||= []

        # Cleanup old messages
        cleanup_history(key)

        # Add current message
        content_hash = event.content.hash
        @message_history[key] << { timestamp: Time.now, content_hash: content_hash }

        # Check for spam
        rate_spam?(key) || duplicate_spam?(key, content_hash)
      end

      def handle(event)
        # Delete the spam message
        event.message.delete rescue nil

        # Add warning
        @bot.database.add_spam_warning(event.author.id, event.server.id)
        warnings = @bot.database.get_spam_warnings(event.author.id, event.server.id)

        max_warnings = @bot.config.spam_max_warnings

        if warnings >= max_warnings
          # Timeout the user for 10 minutes
          begin
            member = event.server.member(event.author.id)
            member.timeout(600, 'Spam detected')

            event.channel.send_message("<@#{event.author.id}> has been timed out for spamming! 😤")

            # Reset warnings
            @bot.database.reset_spam_warnings(event.author.id, event.server.id)
          rescue StandardError => e
            puts "Failed to timeout user: #{e.message}"
          end
        else
          event.channel.send_message(
            "<@#{event.author.id}> Stop spamming! 😤 Warning #{warnings}/#{max_warnings}"
          )
        end
      end

      def clear_user(user_id, guild_id)
        key = "#{user_id}:#{guild_id}"
        @message_history.delete(key)
      end

      private

      def spam_filter_enabled?(guild_id)
        settings = @bot.database.get_guild_settings(guild_id)
        settings&.dig(:spam_filter_enabled) || false
      end

      def cleanup_history(key)
        cutoff = Time.now - HISTORY_CLEANUP_SECONDS
        @message_history[key]&.reject! { |msg| msg[:timestamp] < cutoff }
      end

      def rate_spam?(key)
        cutoff = Time.now - INTERVAL_SECONDS
        recent_count = @message_history[key].count { |msg| msg[:timestamp] >= cutoff }
        recent_count >= MAX_MESSAGES_PER_INTERVAL
      end

      def duplicate_spam?(key, content_hash)
        duplicate_count = @message_history[key].count { |msg| msg[:content_hash] == content_hash }
        duplicate_count >= DUPLICATE_THRESHOLD
      end
    end
  end
end
