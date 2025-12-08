# frozen_string_literal: true

#
# Yuno Gasai 2 (Ruby Edition) - Moderation Commands
# Copyright (C) 2025 blubskye
# SPDX-License-Identifier: AGPL-3.0-or-later
#

module Yuno
  module Commands
    module Moderation
      class << self
        def register(client, bot)
          @bot = bot

          # Ban command
          client.command(:ban, description: 'Ban a user from the server') do |event, user_mention, *reason_parts|
            ban_user(event, user_mention, reason_parts.join(' '))
          end

          # Kick command
          client.command(:kick, description: 'Kick a user from the server') do |event, user_mention, *reason_parts|
            kick_user(event, user_mention, reason_parts.join(' '))
          end

          # Unban command
          client.command(:unban, description: 'Unban a user from the server') do |event, user_id, *reason_parts|
            unban_user(event, user_id, reason_parts.join(' '))
          end

          # Timeout command
          client.command(:timeout, description: 'Timeout a user') do |event, user_mention, minutes, *reason_parts|
            timeout_user(event, user_mention, minutes.to_i, reason_parts.join(' '))
          end

          # Clean command
          client.command(:clean, description: 'Delete messages from a channel') do |event, count|
            clean_messages(event, count.to_i)
          end

          # Mod stats command
          client.command(:'mod-stats', description: 'View moderation statistics') do |event|
            show_mod_stats(event)
          end

          client.command(:modstats, description: 'View moderation statistics') do |event|
            show_mod_stats(event)
          end
        end

        # Slash command handlers
        def slash_ban(event, bot)
          @bot = bot
          user = event.options['user']
          reason = event.options['reason'] || 'No reason provided'

          begin
            event.server.ban(user, 0, reason: reason)

            @bot.database.log_mod_action(
              guild_id: event.server.id,
              moderator_id: event.user.id,
              target_id: user,
              action_type: 'ban',
              reason: reason
            )

            event.respond(embeds: [create_embed(
              title: '🔪 Banned!',
              description: "They won't bother you anymore~ 💕",
              fields: [
                { name: 'User', value: "<@#{user}>", inline: true },
                { name: 'Moderator', value: event.user.mention, inline: true },
                { name: 'Reason', value: reason, inline: false }
              ],
              color: 0xFF0000
            )])
          rescue StandardError => e
            event.respond(content: "💔 I couldn't ban them... #{e.message}", ephemeral: true)
          end
        end

        def slash_kick(event, bot)
          @bot = bot
          user = event.options['user']
          reason = event.options['reason'] || 'No reason provided'

          begin
            event.server.kick(user, reason)

            @bot.database.log_mod_action(
              guild_id: event.server.id,
              moderator_id: event.user.id,
              target_id: user,
              action_type: 'kick',
              reason: reason
            )

            event.respond(embeds: [create_embed(
              title: '👢 Kicked!',
              description: 'Get out! 💢',
              fields: [
                { name: 'User', value: "<@#{user}>", inline: true },
                { name: 'Moderator', value: event.user.mention, inline: true },
                { name: 'Reason', value: reason, inline: false }
              ],
              color: 0xFFA500
            )])
          rescue StandardError => e
            event.respond(content: "💔 I couldn't kick them... #{e.message}", ephemeral: true)
          end
        end

        def slash_unban(event, bot)
          @bot = bot
          user_id = event.options['user_id']
          reason = event.options['reason'] || 'No reason provided'

          begin
            event.server.unban(user_id, reason)

            @bot.database.log_mod_action(
              guild_id: event.server.id,
              moderator_id: event.user.id,
              target_id: user_id,
              action_type: 'unban',
              reason: reason
            )

            event.respond(embeds: [create_embed(
              title: '💕 Unbanned!',
              description: "I'm giving them another chance~ Be good this time!",
              fields: [
                { name: 'User', value: "<@#{user_id}>", inline: true },
                { name: 'Moderator', value: event.user.mention, inline: true },
                { name: 'Reason', value: reason, inline: false }
              ],
              color: 0x00FF00
            )])
          rescue StandardError => e
            event.respond(content: "💔 I couldn't unban them... #{e.message}", ephemeral: true)
          end
        end

        def slash_timeout(event, bot)
          @bot = bot
          user = event.options['user']
          minutes = event.options['minutes']
          reason = event.options['reason'] || 'No reason provided'

          begin
            member = event.server.member(user)
            member.timeout(minutes * 60, reason)

            @bot.database.log_mod_action(
              guild_id: event.server.id,
              moderator_id: event.user.id,
              target_id: user,
              action_type: 'timeout',
              reason: "#{reason} (#{minutes} minutes)"
            )

            event.respond(embeds: [create_embed(
              title: '⏰ Timed Out!',
              description: 'Think about what you did~ 😤',
              fields: [
                { name: 'User', value: "<@#{user}>", inline: true },
                { name: 'Duration', value: "#{minutes} minutes", inline: true },
                { name: 'Moderator', value: event.user.mention, inline: true },
                { name: 'Reason', value: reason, inline: false }
              ],
              color: 0xFFFF00
            )])
          rescue StandardError => e
            event.respond(content: "💔 I couldn't timeout them... #{e.message}", ephemeral: true)
          end
        end

        def slash_clean(event, bot)
          @bot = bot
          count = event.options['count']
          target_user = event.options['user']

          if count < 1 || count > 100
            event.respond(content: '💔 Please specify a number between 1 and 100~', ephemeral: true)
            return
          end

          begin
            messages = event.channel.history(count + 1)
            messages = messages.select { |m| m.author.id == target_user } if target_user

            event.channel.delete_messages(messages)

            event.respond(embeds: [create_embed(
              title: '🧹 Cleaned!',
              description: "I deleted **#{messages.count}** messages for you~ 💕",
              color: 0xFF69B4
            )])
          rescue StandardError => e
            event.respond(content: "💔 Failed to delete messages... #{e.message}", ephemeral: true)
          end
        end

        def slash_mod_stats(event, bot)
          @bot = bot
          stats = @bot.database.get_mod_stats(event.server.id)

          fields = stats.map do |mod_id, actions|
            action_text = actions.map { |type, count| "• #{type}: #{count}" }.join("\n")
            { name: "<@#{mod_id}>", value: action_text, inline: true }
          end

          if fields.empty?
            fields = [{ name: 'No Data', value: 'No moderation actions recorded yet~', inline: false }]
          end

          event.respond(embeds: [create_embed(
            title: '📊 Moderation Statistics',
            description: 'Look at all we\'ve done together~ 💕',
            fields: fields,
            color: 0xFF69B4
          )])
        end

        private

        def ban_user(event, user_mention, reason)
          return '💔 Please specify a user to ban~' unless user_mention

          user_id = parse_user_mention(user_mention)
          return '💔 I couldn\'t find that user~' unless user_id

          reason = 'No reason provided' if reason.empty?

          begin
            event.server.ban(user_id, 0, reason: reason)

            @bot.database.log_mod_action(
              guild_id: event.server.id,
              moderator_id: event.author.id,
              target_id: user_id,
              action_type: 'ban',
              reason: reason
            )

            event.channel.send_embed do |embed|
              embed.title = '🔪 Banned!'
              embed.description = "They won't bother you anymore~ 💕"
              embed.color = 0xFF0000
              embed.add_field(name: 'User', value: "<@#{user_id}>", inline: true)
              embed.add_field(name: 'Moderator', value: event.author.mention, inline: true)
              embed.add_field(name: 'Reason', value: reason, inline: false)
            end
            nil
          rescue StandardError => e
            "💔 I couldn't ban them... #{e.message}"
          end
        end

        def kick_user(event, user_mention, reason)
          return '💔 Please specify a user to kick~' unless user_mention

          user_id = parse_user_mention(user_mention)
          return '💔 I couldn\'t find that user~' unless user_id

          reason = 'No reason provided' if reason.empty?

          begin
            event.server.kick(user_id, reason)

            @bot.database.log_mod_action(
              guild_id: event.server.id,
              moderator_id: event.author.id,
              target_id: user_id,
              action_type: 'kick',
              reason: reason
            )

            event.channel.send_embed do |embed|
              embed.title = '👢 Kicked!'
              embed.description = 'Get out! 💢'
              embed.color = 0xFFA500
              embed.add_field(name: 'User', value: "<@#{user_id}>", inline: true)
              embed.add_field(name: 'Moderator', value: event.author.mention, inline: true)
              embed.add_field(name: 'Reason', value: reason, inline: false)
            end
            nil
          rescue StandardError => e
            "💔 I couldn't kick them... #{e.message}"
          end
        end

        def unban_user(event, user_id_str, reason)
          return '💔 Please specify a user ID to unban~' unless user_id_str

          user_id = user_id_str.to_i
          return '💔 Invalid user ID~' if user_id.zero?

          reason = 'No reason provided' if reason.empty?

          begin
            event.server.unban(user_id, reason)

            @bot.database.log_mod_action(
              guild_id: event.server.id,
              moderator_id: event.author.id,
              target_id: user_id,
              action_type: 'unban',
              reason: reason
            )

            event.channel.send_embed do |embed|
              embed.title = '💕 Unbanned!'
              embed.description = "I'm giving them another chance~ Be good this time!"
              embed.color = 0x00FF00
              embed.add_field(name: 'User', value: "<@#{user_id}>", inline: true)
              embed.add_field(name: 'Moderator', value: event.author.mention, inline: true)
              embed.add_field(name: 'Reason', value: reason, inline: false)
            end
            nil
          rescue StandardError => e
            "💔 I couldn't unban them... #{e.message}"
          end
        end

        def timeout_user(event, user_mention, minutes, reason)
          return '💔 Usage: timeout <user> <minutes> [reason]~' unless user_mention && minutes.positive?

          user_id = parse_user_mention(user_mention)
          return '💔 I couldn\'t find that user~' unless user_id

          reason = 'No reason provided' if reason.empty?

          begin
            member = event.server.member(user_id)
            member.timeout(minutes * 60, reason)

            @bot.database.log_mod_action(
              guild_id: event.server.id,
              moderator_id: event.author.id,
              target_id: user_id,
              action_type: 'timeout',
              reason: "#{reason} (#{minutes} minutes)"
            )

            event.channel.send_embed do |embed|
              embed.title = '⏰ Timed Out!'
              embed.description = 'Think about what you did~ 😤'
              embed.color = 0xFFFF00
              embed.add_field(name: 'User', value: "<@#{user_id}>", inline: true)
              embed.add_field(name: 'Duration', value: "#{minutes} minutes", inline: true)
              embed.add_field(name: 'Moderator', value: event.author.mention, inline: true)
              embed.add_field(name: 'Reason', value: reason, inline: false)
            end
            nil
          rescue StandardError => e
            "💔 I couldn't timeout them... #{e.message}"
          end
        end

        def clean_messages(event, count)
          if count < 1 || count > 100
            return '💔 Please specify a number between 1 and 100~'
          end

          begin
            messages = event.channel.history(count + 1) # +1 to include command message
            event.channel.delete_messages(messages)

            event.channel.send_embed do |embed|
              embed.title = '🧹 Cleaned!'
              embed.description = "I deleted **#{messages.count}** messages for you~ 💕"
              embed.color = 0xFF69B4
            end
            nil
          rescue StandardError => e
            "💔 Failed to delete messages... #{e.message}"
          end
        end

        def show_mod_stats(event)
          stats = @bot.database.get_mod_stats(event.server.id)

          event.channel.send_embed do |embed|
            embed.title = '📊 Moderation Statistics'
            embed.description = 'Look at all we\'ve done together~ 💕'
            embed.color = 0xFF69B4

            if stats.empty?
              embed.add_field(name: 'No Data', value: 'No moderation actions recorded yet~', inline: false)
            else
              stats.each do |mod_id, actions|
                action_text = actions.map { |type, count| "• #{type}: #{count}" }.join("\n")
                embed.add_field(name: "<@#{mod_id}>", value: action_text, inline: true)
              end
            end
          end
          nil
        end

        def parse_user_mention(mention)
          match = mention.match(/<@!?(\d+)>/)
          return match[1].to_i if match

          # Try as raw ID
          id = mention.to_i
          id.positive? ? id : nil
        end

        def create_embed(title:, description:, fields: [], color: 0xFF69B4)
          Discordrb::Webhooks::Embed.new(
            title: title,
            description: description,
            color: color
          ).tap do |embed|
            fields.each do |field|
              embed.add_field(name: field[:name], value: field[:value], inline: field[:inline])
            end
          end
        end
      end
    end
  end
end
