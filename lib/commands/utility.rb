# frozen_string_literal: true

#
# Yuno Gasai 2 (Ruby Edition) - Utility Commands
# Copyright (C) 2025 blubskye
# SPDX-License-Identifier: AGPL-3.0-or-later
#

module Yuno
  module Commands
    module Utility
      class << self
        def register(client, bot)
          @bot = bot

          client.command(:ping, description: 'Check bot latency') do |event|
            start_time = Time.now
            msg = event.respond('💓 Pong!')
            latency = ((Time.now - start_time) * 1000).round
            msg.edit("💓 **Pong!**\nLatency: #{latency}ms 💕")
            nil
          end

          client.command(:help, description: 'Show available commands') do |event|
            show_help(event)
          end

          client.command(:source, description: 'Show bot source code') do |event|
            show_source(event)
          end

          client.command(:prefix, description: 'Set server prefix') do |event, new_prefix|
            set_prefix(event, new_prefix)
          end

          client.command(:xp, description: 'Check XP and level') do |event, user_mention|
            show_xp(event, user_mention)
          end

          client.command(:level, description: 'Check XP and level') do |event, user_mention|
            show_xp(event, user_mention)
          end

          client.command(:rank, description: 'Check XP and level') do |event, user_mention|
            show_xp(event, user_mention)
          end

          client.command(:leaderboard, description: 'Show server leaderboard') do |event|
            show_leaderboard(event)
          end

          client.command(:lb, description: 'Show server leaderboard') do |event|
            show_leaderboard(event)
          end

          client.command(:top, description: 'Show server leaderboard') do |event|
            show_leaderboard(event)
          end

          client.command(:delay, description: 'Delay auto-clean') do |event, minutes|
            delay_clean(event, minutes&.to_i || 5)
          end
        end

        # Slash command handlers
        def slash_ping(event, bot)
          @bot = bot
          start_time = Time.now
          event.respond(content: '💓 Calculating...')
          latency = ((Time.now - start_time) * 1000).round

          event.edit_response(embeds: [create_embed(
            title: '💓 Pong!',
            description: "I'm always here for you~ 💕",
            fields: [
              { name: 'Latency', value: "#{latency}ms", inline: true }
            ],
            color: 0xFF69B4
          )])
        end

        def slash_help(event, bot)
          @bot = bot
          event.respond(embeds: [create_embed(
            title: "💕 Yuno's Commands 💕",
            description: "*\"Let me show you everything I can do for you~\"* 💗",
            fields: [
              {
                name: '🔪 Moderation',
                value: "`/ban` - Ban a user\n`/kick` - Kick a user\n`/unban` - Unban a user\n" \
                       "`/timeout` - Timeout a user\n`/clean` - Delete messages\n`/mod-stats` - View moderation stats",
                inline: true
              },
              {
                name: '⚙️ Utility',
                value: "`/ping` - Check latency\n`/prefix` - Set server prefix\n`/delay` - Delay auto-clean\n" \
                       "`/source` - View source code\n`/help` - This menu",
                inline: true
              },
              {
                name: '✨ Leveling',
                value: "`/xp` - Check XP and level\n`/leaderboard` - Server rankings",
                inline: true
              },
              {
                name: '🎱 Fun',
                value: '`/8ball` - Ask the magic 8-ball',
                inline: true
              }
            ],
            color: 0xFF69B4
          )])
        end

        def slash_source(event, _bot)
          event.respond(embeds: [create_embed(
            title: '📜 Source Code',
            description: "*\"I have nothing to hide from you~\"* 💕\n\n" \
                         "**💎 Ruby Version**: https://github.com/blubskye/yuno_ruby\n" \
                         "**🔩 C Version**: https://github.com/blubskye/yuno_c\n" \
                         "**🔧 C++ Version**: https://github.com/blubskye/yuno_cpp\n" \
                         "**🦀 Rust Version**: https://github.com/blubskye/yuno_rust\n" \
                         "**📦 Original JS**: https://github.com/japaneseenrichmentorganization/Yuno-Gasai-2\n\n" \
                         'Licensed under **AGPL-3.0** 💗',
            color: 0xFF69B4
          )])
        end

        def slash_prefix(event, bot)
          @bot = bot
          new_prefix = event.options['prefix']

          if new_prefix.length > 5
            event.respond(content: '💔 Prefix too long! Max 5 characters~', ephemeral: true)
            return
          end

          @bot.database.set_prefix(event.server.id, new_prefix)

          event.respond(embeds: [create_embed(
            title: '🔧 Prefix Updated!',
            description: "New prefix is now: `#{new_prefix}` 💕",
            color: 0xFF69B4
          )])
        end

        def slash_xp(event, bot)
          @bot = bot
          user_id = event.options['user'] || event.user.id
          user_data = @bot.database.get_user_xp(user_id, event.server.id)

          next_level = user_data[:level] + 1
          xp_for_next = next_level * next_level * 100
          progress = ((user_data[:xp].to_f / xp_for_next) * 100).round

          event.respond(embeds: [create_embed(
            title: '✨ XP Stats',
            description: "<@#{user_id}>'s progress~ 💕",
            fields: [
              { name: 'Level', value: user_data[:level].to_s, inline: true },
              { name: 'XP', value: user_data[:xp].to_s, inline: true },
              { name: 'Progress to Next', value: "#{progress}%", inline: true }
            ],
            color: 0xFF69B4
          )])
        end

        def slash_leaderboard(event, bot)
          @bot = bot
          top_users = @bot.database.get_leaderboard(event.server.id, 10)

          leaderboard_text = top_users.each_with_index.map do |user, idx|
            medal = case idx
                    when 0 then '🥇'
                    when 1 then '🥈'
                    when 2 then '🥉'
                    else "#{idx + 1}."
                    end
            "#{medal} <@#{user[:user_id]}> - Level #{user[:level]} (#{user[:xp]} XP)"
          end.join("\n")

          leaderboard_text = 'No one has earned XP yet~' if leaderboard_text.empty?

          event.respond(embeds: [create_embed(
            title: '🏆 Server Leaderboard',
            description: "*\"Look who's been the most active~\"* 💕\n\n#{leaderboard_text}",
            color: 0xFF69B4
          )])
        end

        def slash_delay(event, _bot)
          minutes = event.options['minutes'] || 5

          event.respond(embeds: [create_embed(
            title: '⏳ Delay Requested',
            description: "I'll wait #{minutes} more minutes before cleaning~ 💕",
            color: 0xFF69B4
          )])
        end

        private

        def show_help(event)
          prefix = @bot.database.get_prefix(event.server.id) || @bot.config.default_prefix

          event.channel.send_embed do |embed|
            embed.title = "💕 Yuno's Commands 💕"
            embed.description = "*\"Let me show you everything I can do for you~\"* 💗\nPrefix: `#{prefix}`"
            embed.color = 0xFF69B4

            embed.add_field(
              name: '🔪 Moderation',
              value: "`ban` - Ban a user\n`kick` - Kick a user\n`unban` - Unban a user\n" \
                     "`timeout` - Timeout a user\n`clean` - Delete messages\n`mod-stats` - View moderation stats",
              inline: true
            )

            embed.add_field(
              name: '⚙️ Utility',
              value: "`ping` - Check latency\n`prefix` - Set server prefix\n`delay` - Delay auto-clean\n" \
                     "`source` - View source code\n`help` - This menu",
              inline: true
            )

            embed.add_field(
              name: '✨ Leveling',
              value: "`xp` - Check XP and level\n`leaderboard` - Server rankings",
              inline: true
            )

            embed.add_field(
              name: '🎱 Fun',
              value: '`8ball` - Ask the magic 8-ball',
              inline: true
            )

            embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: '💕 Yuno is always watching over you~ 💕')
          end
          nil
        end

        def show_source(event)
          event.channel.send_embed do |embed|
            embed.title = '📜 Source Code'
            embed.description = "*\"I have nothing to hide from you~\"* 💕\n\n" \
                                "**💎 Ruby Version**: https://github.com/blubskye/yuno_ruby\n" \
                                "**🔩 C Version**: https://github.com/blubskye/yuno_c\n" \
                                "**🔧 C++ Version**: https://github.com/blubskye/yuno_cpp\n" \
                                "**🦀 Rust Version**: https://github.com/blubskye/yuno_rust\n" \
                                "**📦 Original JS**: https://github.com/japaneseenrichmentorganization/Yuno-Gasai-2\n\n" \
                                'Licensed under **AGPL-3.0** 💗'
            embed.color = 0xFF69B4
          end
          nil
        end

        def set_prefix(event, new_prefix)
          return '💔 Please specify a new prefix~' unless new_prefix
          return '💔 Prefix too long! Max 5 characters~' if new_prefix.length > 5

          @bot.database.set_prefix(event.server.id, new_prefix)

          event.channel.send_embed do |embed|
            embed.title = '🔧 Prefix Updated!'
            embed.description = "New prefix is now: `#{new_prefix}` 💕"
            embed.color = 0xFF69B4
          end
          nil
        end

        def show_xp(event, user_mention)
          user_id = if user_mention
                      parse_user_mention(user_mention) || event.author.id
                    else
                      event.author.id
                    end

          user_data = @bot.database.get_user_xp(user_id, event.server.id)

          next_level = user_data[:level] + 1
          xp_for_next = next_level * next_level * 100
          progress = ((user_data[:xp].to_f / xp_for_next) * 100).round

          event.channel.send_embed do |embed|
            embed.title = '✨ XP Stats'
            embed.description = "<@#{user_id}>'s progress~ 💕"
            embed.color = 0xFF69B4
            embed.add_field(name: 'Level', value: user_data[:level].to_s, inline: true)
            embed.add_field(name: 'XP', value: user_data[:xp].to_s, inline: true)
            embed.add_field(name: 'Progress to Next', value: "#{progress}%", inline: true)
          end
          nil
        end

        def show_leaderboard(event)
          top_users = @bot.database.get_leaderboard(event.server.id, 10)

          event.channel.send_embed do |embed|
            embed.title = '🏆 Server Leaderboard'
            embed.description = "*\"Look who's been the most active~\"* 💕"
            embed.color = 0xFF69B4

            leaderboard_text = top_users.each_with_index.map do |user, idx|
              medal = case idx
                      when 0 then '🥇'
                      when 1 then '🥈'
                      when 2 then '🥉'
                      else "#{idx + 1}."
                      end
              "#{medal} <@#{user[:user_id]}> - Level #{user[:level]} (#{user[:xp]} XP)"
            end.join("\n")

            leaderboard_text = 'No one has earned XP yet~' if leaderboard_text.empty?

            embed.add_field(name: 'Top Users', value: leaderboard_text, inline: false)
          end
          nil
        end

        def delay_clean(event, minutes)
          event.channel.send_embed do |embed|
            embed.title = '⏳ Delay Requested'
            embed.description = "I'll wait #{minutes} more minutes before cleaning~ 💕"
            embed.color = 0xFF69B4
          end
          nil
        end

        def parse_user_mention(mention)
          match = mention.match(/<@!?(\d+)>/)
          return match[1].to_i if match

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
