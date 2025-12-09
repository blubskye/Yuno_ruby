# frozen_string_literal: true

#
# Yuno Gasai 2 (Ruby Edition) - Bot Core
# Copyright (C) 2025 blubskye
# SPDX-License-Identifier: AGPL-3.0-or-later
#

require 'discordrb'
require_relative 'config'
require_relative 'database'
require_relative 'commands/moderation'
require_relative 'commands/utility'
require_relative 'commands/fun'
require_relative 'modules/auto_cleaner'
require_relative 'modules/spam_filter'

module Yuno
  class Bot
    attr_reader :client, :config, :database, :auto_cleaner, :spam_filter

    def initialize
      @config = Config.load
      @database = Database.new(@config.database_path)

      @client = Discordrb::Commands::CommandBot.new(
        token: @config.discord_token,
        prefix: method(:get_prefix),
        intents: %i[servers server_messages server_members direct_messages message_content]
      )

      @auto_cleaner = Modules::AutoCleaner.new(self)
      @spam_filter = Modules::SpamFilter.new(self)

      setup_events
      register_commands
      register_slash_commands
    end

    def run
      @client.run
    end

    def master_user?(user_id)
      @config.master_users.include?(user_id.to_s)
    end

    private

    def get_prefix(message)
      return @config.default_prefix unless message.server

      @database.get_prefix(message.server.id) || @config.default_prefix
    end

    def setup_events
      @client.ready do |event|
        puts "💕 Yuno is online! Logged in as #{event.bot.profile.username}~ 💕"
        puts "💗 I'm watching over #{event.bot.servers.count} servers for you~ 💗"
      end

      @client.message do |event|
        handle_message(event)
      end

      @client.member_join do |event|
        # Welcome message could go here
      end
    end

    def handle_message(event)
      return if event.author.bot_account?

      # Handle DMs
      unless event.server
        event.respond(@config.dm_message)
        return
      end

      # Check for spam
      if @spam_filter.check(event)
        @spam_filter.handle(event)
        return
      end

      # Add XP for chatting
      add_xp_for_message(event) if leveling_enabled?(event.server.id)
    end

    def add_xp_for_message(event)
      xp_gain = rand(15..25)
      @database.add_xp(event.author.id, event.server.id, xp_gain)

      user_data = @database.get_user_xp(event.author.id, event.server.id)
      new_level = Math.sqrt(user_data[:xp] / 100.0).to_i

      return unless new_level > user_data[:level]

      @database.set_level(event.author.id, event.server.id, new_level)

      event.channel.send_embed do |embed|
        embed.color = 0xFF69B4
        embed.title = '✨ Level Up! ✨'
        embed.description = "Congratulations #{event.author.mention}! You've reached level **#{new_level}**! 💕"
      end
    end

    def leveling_enabled?(guild_id)
      settings = @database.get_guild_settings(guild_id)
      settings.nil? || settings[:leveling_enabled]
    end

    def register_commands
      Commands::Moderation.register(@client, self)
      Commands::Utility.register(@client, self)
      Commands::Fun.register(@client, self)
    end

    def register_slash_commands
      # Register application commands
      @client.register_application_command(:ping, 'Check if Yuno is awake~ 💓')

      @client.register_application_command(:help, 'See what Yuno can do for you~ 💕')

      @client.register_application_command(:source, "See Yuno's source code~ 📜")

      @client.register_application_command(:ban, 'Ban someone who\'s bothering you~ 🔪') do |cmd|
        cmd.user('user', 'The user to ban', required: true)
        cmd.string('reason', 'Reason for the ban')
        cmd.integer('delete_days', 'Days of messages to delete (0-7)')
      end

      @client.register_application_command(:kick, 'Kick someone out~ 👢') do |cmd|
        cmd.user('user', 'The user to kick', required: true)
        cmd.string('reason', 'Reason for the kick')
      end

      @client.register_application_command(:unban, 'Give someone another chance~ 💕') do |cmd|
        cmd.string('user_id', 'The user ID to unban', required: true)
        cmd.string('reason', 'Reason for the unban')
      end

      @client.register_application_command(:timeout, 'Make them think about what they did~ ⏰') do |cmd|
        cmd.user('user', 'The user to timeout', required: true)
        cmd.integer('minutes', 'Duration in minutes', required: true)
        cmd.string('reason', 'Reason for the timeout')
      end

      @client.register_application_command(:clean, 'Let me tidy up for you~ 🧹') do |cmd|
        cmd.integer('count', 'Number of messages to delete (1-100)', required: true)
        cmd.user('user', 'Only delete messages from this user')
      end

      @client.register_application_command(:'mod-stats', 'See our moderation achievements together~ 📊')

      @client.register_application_command(:prefix, 'Set the command prefix for this server~ 🔧') do |cmd|
        cmd.string('prefix', 'The new prefix to use', required: true)
      end

      @client.register_application_command(:xp, 'Check your or someone\'s level~ ✨') do |cmd|
        cmd.user('user', 'User to check')
      end

      @client.register_application_command(:leaderboard, 'See who\'s been most active~ 🏆')

      @client.register_application_command(:'8ball', "Ask Yuno's magic 8-ball~ 🎱") do |cmd|
        cmd.string('question', 'Your question for fate~', required: true)
      end

      @client.register_application_command(:delay, 'Delay auto-clean for a bit~ ⏳') do |cmd|
        cmd.integer('minutes', 'Minutes to delay (default: 5)')
      end

      @client.register_application_command(:quote, 'Get a random Yuno quote~ 💕')

      @client.register_application_command(:praise, 'Praise someone who deserves it~ 💖') do |cmd|
        cmd.user('user', 'The user to praise', required: true)
      end

      @client.register_application_command(:scold, 'Scold someone being naughty~ 😤') do |cmd|
        cmd.user('user', 'The user to scold', required: true)
      end

      @client.register_application_command(:neko, 'Get a cute neko image~ 😺')

      @client.register_application_command(:urban, 'Search Urban Dictionary~ 📖') do |cmd|
        cmd.string('term', 'The term to search for', required: true)
      end

      @client.register_application_command(:hentai, 'Get NSFW images (NSFW channels only)~ 🔞') do |cmd|
        cmd.integer('count', 'Number of images (1-25)')
        cmd.string('tags', 'Search tags')
      end

      @client.register_application_command(:stats, 'See Yuno\'s statistics~ 📊')

      @client.register_application_command(:'set-level', 'Set a user\'s level~ ⚙️') do |cmd|
        cmd.user('user', 'The user to modify', required: true)
        cmd.integer('level', 'The level to set', required: true)
      end

      # Slash command handlers
      setup_slash_handlers
    end

    def setup_slash_handlers
      @client.application_command(:ping) { |event| Commands::Utility.slash_ping(event, self) }
      @client.application_command(:help) { |event| Commands::Utility.slash_help(event, self) }
      @client.application_command(:source) { |event| Commands::Utility.slash_source(event, self) }
      @client.application_command(:prefix) { |event| Commands::Utility.slash_prefix(event, self) }
      @client.application_command(:xp) { |event| Commands::Utility.slash_xp(event, self) }
      @client.application_command(:leaderboard) { |event| Commands::Utility.slash_leaderboard(event, self) }
      @client.application_command(:delay) { |event| Commands::Utility.slash_delay(event, self) }

      @client.application_command(:ban) { |event| Commands::Moderation.slash_ban(event, self) }
      @client.application_command(:kick) { |event| Commands::Moderation.slash_kick(event, self) }
      @client.application_command(:unban) { |event| Commands::Moderation.slash_unban(event, self) }
      @client.application_command(:timeout) { |event| Commands::Moderation.slash_timeout(event, self) }
      @client.application_command(:clean) { |event| Commands::Moderation.slash_clean(event, self) }
      @client.application_command(:'mod-stats') { |event| Commands::Moderation.slash_mod_stats(event, self) }

      @client.application_command(:'8ball') { |event| Commands::Fun.slash_8ball(event, self) }
      @client.application_command(:quote) { |event| Commands::Fun.slash_quote(event, self) }
      @client.application_command(:praise) { |event| Commands::Fun.slash_praise(event, self) }
      @client.application_command(:scold) { |event| Commands::Fun.slash_scold(event, self) }
      @client.application_command(:neko) { |event| Commands::Fun.slash_neko(event, self) }
      @client.application_command(:urban) { |event| Commands::Fun.slash_urban(event, self) }
      @client.application_command(:hentai) { |event| Commands::Fun.slash_hentai(event, self) }

      @client.application_command(:stats) { |event| Commands::Utility.slash_stats(event, self) }
      @client.application_command(:'set-level') { |event| Commands::Utility.slash_set_level(event, self) }
    end
  end
end
