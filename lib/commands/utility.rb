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

          # Basic utility commands
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

          client.command(:stats, description: 'Show bot statistics') do |event|
            show_stats(event)
          end

          client.command(:info, description: 'Show bot statistics') do |event|
            show_stats(event)
          end

          client.command(:prefix, description: 'Set server prefix') do |event, new_prefix|
            set_prefix(event, new_prefix)
          end

          # XP/Leveling commands
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

          # Advanced leveling commands (master users only)
          client.command(:'set-level', description: 'Set a user\'s level') do |event, *args|
            return unless @bot.master_user?(event.author.id)

            set_user_level(event, args)
          end

          client.command(:slvl, description: 'Set a user\'s level') do |event, *args|
            return unless @bot.master_user?(event.author.id)

            set_user_level(event, args)
          end

          client.command(:'set-experiencecounter', description: 'Enable or disable XP system') do |event, state|
            return unless @bot.master_user?(event.author.id)

            set_experience_counter(event, state)
          end

          client.command(:'set-levelrolemap', description: 'Map a level to a role') do |event, *args|
            return unless @bot.master_user?(event.author.id)

            set_level_role_map(event, args)
          end

          # Configuration commands (master users only)
          client.command(:'set-spamfilter', description: 'Enable or disable spam filter') do |event, state|
            return unless @bot.master_user?(event.author.id)

            set_spam_filter(event, state)
          end

          client.command(:'set-joinmessage', description: 'Set join DM message') do |event, *args|
            return unless @bot.master_user?(event.author.id)

            set_join_message(event, args)
          end

          client.command(:'set-banimage', description: 'Set custom ban image') do |event, *args|
            set_ban_image(event, args)
          end

          client.command(:'del-banimage', description: 'Delete custom ban image') do |event, user_mention|
            delete_ban_image(event, user_mention)
          end

          # Mention response commands
          client.command(:'add-mentionresponse', description: 'Add auto-response trigger') do |event, *args|
            return unless @bot.master_user?(event.author.id)

            add_mention_response(event, args)
          end

          client.command(:'del-mentionresponse', description: 'Delete auto-response trigger') do |event, trigger|
            return unless @bot.master_user?(event.author.id)

            delete_mention_response(event, trigger)
          end

          client.command(:mentionresponses, description: 'List all auto-responses') do |event|
            return unless @bot.master_user?(event.author.id)

            list_mention_responses(event)
          end

          # Auto-clean management
          client.command(:'auto-clean', description: 'Manage auto-clean settings') do |event, *args|
            return unless @bot.master_user?(event.author.id)

            manage_auto_clean(event, args)
          end

          client.command(:autoclean, description: 'Manage auto-clean settings') do |event, *args|
            return unless @bot.master_user?(event.author.id)

            manage_auto_clean(event, args)
          end

          # Admin commands
          client.command(:shutdown, description: 'Shutdown the bot') do |event|
            return unless @bot.master_user?(event.author.id)

            shutdown_bot(event)
          end

          client.command(:'add-masteruser', description: 'Add a master user') do |event, user_mention|
            return unless @bot.master_user?(event.author.id)

            add_master_user(event, user_mention)
          end

          client.command(:'add-mu', description: 'Add a master user') do |event, user_mention|
            return unless @bot.master_user?(event.author.id)

            add_master_user(event, user_mention)
          end

          # Ban management
          client.command(:exportbans, description: 'Export ban list') do |event|
            return unless @bot.master_user?(event.author.id)

            export_bans(event)
          end

          client.command(:ebans, description: 'Export ban list') do |event|
            return unless @bot.master_user?(event.author.id)

            export_bans(event)
          end

          client.command(:importbans, description: 'Import ban list') do |event, guild_id|
            return unless @bot.master_user?(event.author.id)

            import_bans(event, guild_id)
          end

          client.command(:ibans, description: 'Import ban list') do |event, guild_id|
            return unless @bot.master_user?(event.author.id)

            import_bans(event, guild_id)
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
                value: "`/ping` - Check latency\n`/prefix` - Set server prefix\n`/stats` - Bot statistics\n" \
                       "`/source` - View source code\n`/help` - This menu",
                inline: true
              },
              {
                name: '✨ Leveling',
                value: "`/xp` - Check XP and level\n`/leaderboard` - Server rankings\n`/set-level` - Set user level",
                inline: true
              },
              {
                name: '🎱 Fun',
                value: "`/8ball` - Ask the magic 8-ball\n`/quote` - Yuno quote\n`/praise` - Praise someone\n" \
                       "`/scold` - Scold someone\n`/neko` - Neko images\n`/urban` - Urban Dictionary",
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
                         "**🔷 Clojure Version**: https://github.com/blubskye/yuno_clojure\n" \
                         "**💜 C# Version**: https://github.com/blubskye/yuno_csharp\n" \
                         "**🔩 C Version**: https://github.com/blubskye/yuno_c\n" \
                         "**🐘 PHP Version**: https://github.com/blubskye/yuno_php\n" \
                         "**🦀 Rust Version**: https://github.com/blubskye/yuno_rust\n" \
                         "**📦 Original JS**: https://github.com/japaneseenrichmentorganization/Yuno-Gasai-2\n\n" \
                         'Licensed under **AGPL-3.0** 💗',
            color: 0xFF69B4
          )])
        end

        def slash_stats(event, bot)
          @bot = bot
          memory_mb = ((`ps -o rss= -p #{Process.pid}`.to_i / 1024.0)).round(1)
          uptime_seconds = (Time.now - @bot.client.profile.created_at).to_i rescue (Process.clock_gettime(Process::CLOCK_MONOTONIC)).to_i
          hours = uptime_seconds / 3600
          minutes = (uptime_seconds % 3600) / 60
          seconds = uptime_seconds % 60

          event.respond(embeds: [create_embed(
            title: '📊 Yuno Statistics 💕',
            description: '',
            fields: [
              { name: 'Uptime', value: "#{hours}h #{minutes}m #{seconds}s", inline: true },
              { name: 'Memory', value: "#{memory_mb}MB", inline: true },
              { name: 'Ruby', value: RUBY_VERSION, inline: true },
              { name: 'Platform', value: RUBY_PLATFORM, inline: true },
              { name: 'Servers', value: @bot.client.servers.count.to_s, inline: true }
            ],
            color: 0xFF69B4
          )].tap do |embeds|
            embeds.first.footer = Discordrb::Webhooks::EmbedFooter.new(text: "I'll always be here for you~ 💗")
          end)
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

        def slash_set_level(event, bot)
          @bot = bot

          unless @bot.master_user?(event.user.id)
            return event.respond(content: '❌ Only master users can use this command~', ephemeral: true)
          end

          level = event.options['level']
          user_id = event.options['user']

          if level.negative?
            return event.respond(content: '❌ Level must be non-negative~', ephemeral: true)
          end

          @bot.database.set_xp(user_id, event.server.id, 0, level)

          event.respond(content: "✅ Set <@#{user_id}> to **Level #{level}** 💕")
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
                     "`timeout` - Timeout a user\n`clean` - Delete messages\n`mod-stats` - View moderation stats\n" \
                     "`exportbans` - Export ban list\n`importbans` - Import ban list",
              inline: true
            )

            embed.add_field(
              name: '⚙️ Utility',
              value: "`ping` - Check latency\n`prefix` - Set server prefix\n`stats` - Bot statistics\n" \
                     "`source` - View source code\n`help` - This menu",
              inline: true
            )

            embed.add_field(
              name: '✨ Leveling',
              value: "`xp` - Check XP and level\n`leaderboard` - Server rankings\n`set-level` - Set user level\n" \
                     "`set-levelrolemap` - Map level to role\n`set-experiencecounter` - Toggle XP",
              inline: true
            )

            embed.add_field(
              name: '🎱 Fun',
              value: "`8ball` - Ask the magic 8-ball\n`quote` - Yuno quote\n`praise` - Praise someone\n" \
                     "`scold` - Scold someone\n`neko` - Neko images\n`urban` - Urban Dictionary\n`hentai` - NSFW images",
              inline: true
            )

            embed.add_field(
              name: '⚙️ Configuration',
              value: "`set-spamfilter` - Toggle spam filter\n`set-joinmessage` - Set join DM\n" \
                     "`set-banimage` - Set ban image\n`add-mentionresponse` - Add trigger\n" \
                     "`auto-clean` - Manage auto-clean",
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
                                "**🔷 Clojure Version**: https://github.com/blubskye/yuno_clojure\n" \
                                "**💜 C# Version**: https://github.com/blubskye/yuno_csharp\n" \
                                "**🔩 C Version**: https://github.com/blubskye/yuno_c\n" \
                                "**🐘 PHP Version**: https://github.com/blubskye/yuno_php\n" \
                                "**🦀 Rust Version**: https://github.com/blubskye/yuno_rust\n" \
                                "**📦 Original JS**: https://github.com/japaneseenrichmentorganization/Yuno-Gasai-2\n\n" \
                                'Licensed under **AGPL-3.0** 💗'
            embed.color = 0xFF69B4
          end
          nil
        end

        def show_stats(event)
          memory_mb = ((`ps -o rss= -p #{Process.pid}`.to_i / 1024.0)).round(1) rescue '?'
          uptime_seconds = (Process.clock_gettime(Process::CLOCK_MONOTONIC)).to_i
          hours = uptime_seconds / 3600
          minutes = (uptime_seconds % 3600) / 60
          seconds = uptime_seconds % 60

          event.channel.send_embed do |embed|
            embed.title = '📊 Yuno Statistics 💕'
            embed.color = 0xFF69B4
            embed.add_field(name: 'Uptime', value: "#{hours}h #{minutes}m #{seconds}s", inline: true)
            embed.add_field(name: 'Memory', value: "#{memory_mb}MB", inline: true)
            embed.add_field(name: 'Ruby', value: RUBY_VERSION, inline: true)
            embed.add_field(name: 'Platform', value: RUBY_PLATFORM, inline: true)
            embed.add_field(name: 'Servers', value: @bot.client.servers.count.to_s, inline: true)
            embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "I'll always be here for you~ 💗")
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

        def set_user_level(event, args)
          return '❌ Usage: `set-level <level> <@user>`' if args.length < 2

          level = args[0].to_i
          user_id = parse_user_mention(args[1])

          return '❌ Level must be non-negative~' if level.negative?
          return '❌ Please mention a user~' unless user_id

          @bot.database.set_xp(user_id, event.server.id, 0, level)
          event.respond("✅ Set <@#{user_id}> to **Level #{level}** 💕")
          nil
        end

        def set_experience_counter(event, state)
          return '❌ Usage: `set-experiencecounter <enable|disable>`' unless state

          enabled = %w[enable enabled true on].include?(state.downcase)
          disabled = %w[disable disabled false off].include?(state.downcase)

          return '❌ Usage: `set-experiencecounter <enable|disable>`' unless enabled || disabled

          @bot.database.set_leveling(event.server.id, enabled)
          event.respond("✅ Experience counter is now **#{enabled ? 'enabled' : 'disabled'}** 💕")
          nil
        end

        def set_level_role_map(event, args)
          return '❌ Usage: `set-levelrolemap <level> <@role>`' if args.length < 2

          level = args[0].to_i
          role_id = parse_role_mention(args[1])

          return '❌ Level must be non-negative~' if level.negative?
          return '❌ Please mention a role~' unless role_id

          role_map = @bot.database.get_level_role_map(event.server.id)
          role_map[level.to_s] = role_id.to_s
          @bot.database.set_level_role_map(event.server.id, role_map)

          event.respond("✅ Level **#{level}** will now give <@&#{role_id}> 💕")
          nil
        end

        def set_spam_filter(event, state)
          return '❌ Usage: `set-spamfilter <enable|disable>`' unless state

          enabled = %w[enable enabled true on].include?(state.downcase)
          disabled = %w[disable disabled false off].include?(state.downcase)

          return '❌ Usage: `set-spamfilter <enable|disable>`' unless enabled || disabled

          @bot.database.set_spam_filter(event.server.id, enabled)
          event.respond("✅ Spam filter is now **#{enabled ? 'enabled' : 'disabled'}** 💕")
          nil
        end

        def set_join_message(event, args)
          return '❌ Usage: `set-joinmessage <title> <message>`' if args.length < 2

          title = args[0].tr('_', ' ')
          message = args[1..].join(' ')

          @bot.database.set_join_message(event.server.id, title, message)
          event.respond("✅ Join message updated!\n**Title:** #{title}\n**Message:** #{message} 💕")
          nil
        end

        def set_ban_image(event, args)
          return '❌ Please provide a valid URL~' if args.empty?

          url = args[0]
          return '❌ Please provide a valid URL~' unless url&.match?(%r{^https?://})

          target_id = args[1] ? parse_user_mention(args[1]) : event.author.id
          target_id ||= event.author.id

          @bot.database.set_ban_image(target_id, event.server.id, url)
          event.respond('✅ Ban image set! 💕')
          nil
        end

        def delete_ban_image(event, user_mention)
          target_id = user_mention ? parse_user_mention(user_mention) : event.author.id
          target_id ||= event.author.id

          @bot.database.delete_ban_image(target_id, event.server.id)
          event.respond('✅ Ban image deleted! 💕')
          nil
        end

        def add_mention_response(event, args)
          return '❌ Usage: `add-mentionresponse <trigger> <response> [image-url]`' if args.length < 2

          trigger = args[0]
          response = args[1]
          image_url = args[2] if args[2]&.match?(%r{^https?://})

          existing = @bot.database.get_mention_response(event.server.id, trigger)
          return '❌ A response with that trigger already exists~' if existing

          @bot.database.add_mention_response(event.server.id, trigger, response, image_url)
          msg = "✅ Mention response added!\n**Trigger:** #{trigger}\n**Response:** #{response}"
          msg += "\n**Image:** #{image_url}" if image_url
          event.respond("#{msg} 💕")
          nil
        end

        def delete_mention_response(event, trigger)
          return '❌ Usage: `del-mentionresponse <trigger>`' unless trigger

          existing = @bot.database.get_mention_response(event.server.id, trigger)
          return '❌ No response found with that trigger~' unless existing

          @bot.database.delete_mention_response_by_trigger(event.server.id, trigger)
          event.respond('✅ Mention response deleted! 💕')
          nil
        end

        def list_mention_responses(event)
          responses = @bot.database.get_mention_responses(event.server.id)

          if responses.empty?
            return 'No mention responses configured~'
          end

          list = responses.map { |r| "• **#{r[:trigger]}** → #{r[:response]}" }.join("\n")

          event.channel.send_embed do |embed|
            embed.title = '📋 Mention Responses'
            embed.description = list
            embed.color = 0xFF69B4
          end
          nil
        end

        def manage_auto_clean(event, args)
          action = args[0]&.downcase

          case action
          when 'list'
            cleans = @bot.database.get_guild_auto_cleans(event.server.id)
            if cleans.empty?
              return 'No auto-cleans configured~'
            end

            list = cleans.map { |c| "• <##{c[:channel_id]}> - every #{c[:interval_minutes]}m" }.join("\n")

            event.channel.send_embed do |embed|
              embed.title = '📋 Auto-Cleans'
              embed.description = list
              embed.color = 0xFF69B4
            end

          when 'add', 'edit'
            return '❌ Usage: `auto-clean add <#channel> <interval-mins> <msg-count>`' if args.length < 4

            channel_id = parse_channel_mention(args[1])
            interval = args[2].to_i
            msg_count = args[3].to_i

            return '❌ Please mention a channel~' unless channel_id
            return '❌ Invalid interval~' unless interval.positive?

            @bot.database.set_auto_clean_config(event.server.id, channel_id, {
              interval_minutes: interval,
              message_count: msg_count,
              enabled: true
            })

            event.respond("✅ Auto-clean configured for <##{channel_id}> every #{interval} minutes 💕")

          when 'remove'
            return '❌ Please specify a channel~' if args.length < 2

            channel_id = parse_channel_mention(args[1])
            return '❌ Please mention a channel~' unless channel_id

            @bot.database.remove_auto_clean_config(event.server.id, channel_id)
            event.respond('✅ Auto-clean removed! 💕')

          else
            return '❌ Usage: `auto-clean <list|add|edit|remove> [#channel] [interval] [msg-count]`'
          end
          nil
        end

        def shutdown_bot(event)
          event.respond("💔 Shutting down... Don't forget me~ 💔")
          sleep 1
          exit 0
        end

        def add_master_user(event, user_mention)
          target_id = user_mention ? parse_user_mention(user_mention) : nil
          target_id ||= user_mention.to_i if user_mention&.match?(/^\d+$/)

          return '❌ Please specify a user ID or mention~' unless target_id

          event.respond("✅ To add master user #{target_id}, update config.json and restart~ 💕")
          nil
        end

        def export_bans(event)
          event.channel.send_embed do |embed|
            embed.title = '📋 Export Bans'
            embed.description = "This feature requires fetching all guild bans.\n" \
                               "Ban list would be saved to `BANS-#{event.server.id}.txt`\n" \
                               '*Feature requires ban list fetching* 💕'
            embed.color = 0xFF69B4
          end
          nil
        end

        def import_bans(event, guild_id)
          return '❌ Please provide a valid guild ID~' unless guild_id&.match?(/^\d+$/)

          event.channel.send_embed do |embed|
            embed.title = '📋 Import Bans'
            embed.description = "This would import bans from `BANS-#{guild_id}.txt`\n" \
                               '*Feature requires ban API access* 💕'
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

        def parse_role_mention(mention)
          match = mention.match(/<@&(\d+)>/)
          return match[1].to_i if match

          id = mention.to_i
          id.positive? ? id : nil
        end

        def parse_channel_mention(mention)
          match = mention.match(/<#(\d+)>/)
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
