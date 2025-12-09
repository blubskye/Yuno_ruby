# frozen_string_literal: true

#
# Yuno Gasai 2 (Ruby Edition) - Fun Commands
# Copyright (C) 2025 blubskye
# SPDX-License-Identifier: AGPL-3.0-or-later
#

require 'net/http'
require 'json'
require 'uri'
require 'cgi'

module Yuno
  module Commands
    module Fun
      EIGHTBALL_RESPONSES = [
        # Positive
        'It is certain~ 💕',
        'It is decidedly so~ 💗',
        'Without a doubt~ 💖',
        'Yes, definitely~ 💕',
        'You may rely on it~ 💗',
        'As I see it, yes~ ✨',
        'Most likely~ 💕',
        'Outlook good~ 💖',
        'Yes~ 💗',
        'Signs point to yes~ ✨',

        # Neutral
        'Reply hazy, try again~ 🤔',
        'Ask again later~ 💭',
        'Better not tell you now~ 😏',
        'Cannot predict now~ 🔮',
        'Concentrate and ask again~ 💫',

        # Negative
        "Don't count on it~ 💔",
        'My reply is no~ 😤',
        'My sources say no~ 💢',
        'Outlook not so good~ 😞',
        'Very doubtful~ 💔'
      ].freeze

      YUNO_QUOTES = [
        'Your future belongs to me',
        "I'm glad Yukkis mother is a good person, I didn't have to use any of the tools I brought",
        "I'm the only friend you need",
        "I was practically dead, but you gave me a future. Yukki is my hope in life, but if it won't come true then I will die for Yukki, and even in death I will chase after Yukki",
        'They are all planning to betray you!!!',
        "What's insane is this world that won't let me and Yukki be together!",
        'A half moon, it has a dark half and a bright half, just like me...',
        'Everything in this world is just a game and we are merely the pawns.',
        'Breaking curfew is 3 demerits. 3 demerits gets the cage, the cage means no food.',
        "No matter what happens, I'll protect you~ 💕",
        "I won't let anyone take you away from me!",
        'My love for you is eternal... whether you like it or not~ 💗'
      ].freeze

      PRAISE_IMAGES = [
        'https://media.giphy.com/media/ny8mlxWio6WBi/giphy.gif',
        'https://media.giphy.com/media/BXrwTdoho6hkQ/giphy.gif',
        'https://media.giphy.com/media/3o7TKoWXm3okO1kgHC/giphy.gif'
      ].freeze

      SCOLD_IMAGES = [
        'https://i.imgur.com/ZLaayKG.gif',
        'https://media.giphy.com/media/WoF3yfYupTt8mHc7va/giphy.gif',
        'https://media.giphy.com/media/cOWNPwDDh1tYs/giphy.gif'
      ].freeze

      BANNED_SEARCH_TERMS = %w[loli gore guro scat vore underage shota].freeze

      class << self
        def register(client, bot)
          @bot = bot

          # 8ball command
          client.command(:'8ball', description: 'Ask the magic 8-ball') do |event, *question_parts|
            question = question_parts.join(' ')
            ask_8ball(event, question)
          end

          # Quote command
          client.command(:quote, description: 'Get a random Yuno quote') do |event|
            show_quote(event)
          end

          # Praise command
          client.command(:praise, description: 'Praise someone') do |event, user_mention|
            praise_user(event, user_mention)
          end

          # Scold command
          client.command(:scold, description: 'Scold someone') do |event, user_mention|
            scold_user(event, user_mention)
          end

          # Neko command
          client.command(:neko, description: 'Get a neko image') do |event, *args|
            get_neko(event, args.first)
          end

          client.command(:nya, description: 'Get a neko image') do |event, *args|
            get_neko(event, args.first)
          end

          # Urban Dictionary command
          client.command(:urban, description: 'Search Urban Dictionary') do |event, *term_parts|
            search_urban(event, term_parts.join(' '))
          end

          client.command(:ub, description: 'Search Urban Dictionary') do |event, *term_parts|
            search_urban(event, term_parts.join(' '))
          end

          # Hentai command (NSFW)
          client.command(:hentai, description: 'Get NSFW images (NSFW channels only)') do |event, *args|
            get_hentai(event, args)
          end

          client.command(:hen, description: 'Get NSFW images (NSFW channels only)') do |event, *args|
            get_hentai(event, args)
          end
        end

        # Slash command handlers
        def slash_8ball(event, _bot)
          question = event.options['question']
          response = EIGHTBALL_RESPONSES.sample

          event.respond(embeds: [create_embed(
            title: '🎱 Magic 8-Ball',
            fields: [
              { name: 'Question', value: question, inline: false },
              { name: 'Answer', value: response, inline: false }
            ],
            color: 0xFF69B4
          )].tap do |embeds|
            embeds.first.footer = Discordrb::Webhooks::EmbedFooter.new(
              text: '*shakes the 8-ball mysteriously*'
            )
          end)
        end

        def slash_quote(event, _bot)
          quote = YUNO_QUOTES.sample
          event.respond(content: "💕 *\"#{quote}\"* 💕")
        end

        def slash_praise(event, bot)
          @bot = bot
          user_id = event.options['user']
          image = PRAISE_IMAGES.sample

          event.respond(content: "<@#{user_id}> #{image}\n*Good job~* 💕")
        end

        def slash_scold(event, bot)
          @bot = bot
          user_id = event.options['user']
          image = SCOLD_IMAGES.sample

          event.respond(content: "<@#{user_id}> #{image}\n*Bad!* 😤")
        end

        def slash_neko(event, _bot)
          begin
            uri = URI('https://nekos.life/api/neko')
            response = Net::HTTP.get(uri)
            data = JSON.parse(response)
            image_url = data['neko']

            event.respond(content: "😺 Here's a neko for you~ 💕\n#{image_url}")
          rescue StandardError => e
            event.respond(content: "💔 Couldn't fetch a neko right now~", ephemeral: true)
          end
        end

        def slash_urban(event, _bot)
          term = event.options['term']
          begin
            uri = URI("https://api.urbandictionary.com/v0/define?term=#{CGI.escape(term)}")
            response = Net::HTTP.get(uri)
            data = JSON.parse(response)

            if data['list'].empty?
              return event.respond(content: "❌ No results found for `#{term}`", ephemeral: true)
            end

            result = data['list'].first
            definition = result['definition'][0..500]
            example = result['example']&.slice(0, 200)

            event.respond(embeds: [create_embed(
              title: "📖 #{result['word']}",
              description: "**Definition:** #{definition}\n\n" +
                          (example ? "**Example:** #{example}\n\n" : '') +
                          "👍 #{result['thumbs_up']} | 👎 #{result['thumbs_down']}",
              color: 0xFF69B4
            )])
          rescue StandardError => e
            event.respond(content: "💔 Couldn't search Urban Dictionary right now~", ephemeral: true)
          end
        end

        def slash_hentai(event, _bot)
          unless event.channel.nsfw?
            return event.respond(content: "💔 I can't post those here... Try a NSFW channel~ 😳", ephemeral: true)
          end

          count = event.options['count'] || 2
          count = [[count, 1].max, 25].min
          tags = event.options['tags'] || ''

          clean_args = tags.downcase.gsub(/[^a-z]/, '')
          if BANNED_SEARCH_TERMS.any? { |term| clean_args.include?(term) }
            return event.respond(content: "❌ That search is against Discord ToS. I won't search for that.", ephemeral: true)
          end

          begin
            url = if tags.empty?
                    "https://rule34.xxx/index.php?page=dapi&s=post&q=index&json=1&limit=100&pid=#{rand(2000)}"
                  else
                    "https://rule34.xxx/index.php?page=dapi&s=post&q=index&json=1&limit=100&tags=#{CGI.escape(tags)}"
                  end

            uri = URI(url)
            response = Net::HTTP.get(uri)
            results = JSON.parse(response)

            if results.empty?
              return event.respond(content: "❌ No results found for `#{tags}`", ephemeral: true)
            end

            selected = results.sample(count)
            urls = selected.map { |r| "https://img.rule34.xxx/images/#{r['directory']}/#{r['image']}" }

            event.respond(content: urls.join("\n"))
          rescue StandardError => e
            event.respond(content: "💔 Couldn't fetch images right now~", ephemeral: true)
          end
        end

        private

        def ask_8ball(event, question)
          if question.empty?
            return '💔 You need to ask a question~ 🎱'
          end

          response = EIGHTBALL_RESPONSES.sample

          event.channel.send_embed do |embed|
            embed.title = '🎱 Magic 8-Ball'
            embed.color = 0xFF69B4
            embed.add_field(name: 'Question', value: question, inline: false)
            embed.add_field(name: 'Answer', value: response, inline: false)
            embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: '*shakes the 8-ball mysteriously*')
          end
          nil
        end

        def show_quote(event)
          quote = YUNO_QUOTES.sample
          event.respond("💕 *\"#{quote}\"* 💕")
          nil
        end

        def praise_user(event, user_mention)
          return '💔 Who do you want me to praise?' unless user_mention

          target_id = parse_user_mention(user_mention)
          return '💔 Who do you want me to praise?' unless target_id

          image = PRAISE_IMAGES.sample
          event.respond("<@#{target_id}> #{image}\n*Good job~* 💕")
          nil
        end

        def scold_user(event, user_mention)
          return '💔 Who do you want me to scold?' unless user_mention

          target_id = parse_user_mention(user_mention)
          return '💔 Who do you want me to scold?' unless target_id

          image = SCOLD_IMAGES.sample
          event.respond("<@#{target_id}> #{image}\n*Bad!* 😤")
          nil
        end

        def get_neko(event, lewd_arg)
          begin
            lewd = lewd_arg&.downcase == 'lewd'
            url = lewd ? 'https://nekos.life/api/lewd/neko' : 'https://nekos.life/api/neko'

            uri = URI(url)
            response = Net::HTTP.get(uri)
            data = JSON.parse(response)
            image_url = data['neko']

            event.respond("😺 Here's a neko for you~ 💕\n#{image_url}")
          rescue StandardError => e
            event.respond('💔 Couldn\'t fetch a neko right now~')
          end
          nil
        end

        def search_urban(event, term)
          return '❌ Please provide a search term~' if term.empty?

          begin
            uri = URI("https://api.urbandictionary.com/v0/define?term=#{CGI.escape(term)}")
            response = Net::HTTP.get(uri)
            data = JSON.parse(response)

            if data['list'].empty?
              return "❌ No results found for `#{term}`"
            end

            result = data['list'].first
            definition = result['definition'][0..500]
            example = result['example']&.slice(0, 200)

            event.channel.send_embed do |embed|
              embed.title = "📖 #{result['word']}"
              embed.color = 0xFF69B4
              embed.description = "**Definition:** #{definition}\n\n" +
                                 (example ? "**Example:** #{example}\n\n" : '') +
                                 "👍 #{result['thumbs_up']} | 👎 #{result['thumbs_down']}"
            end
          rescue StandardError => e
            event.respond('💔 Couldn\'t search Urban Dictionary right now~')
          end
          nil
        end

        def get_hentai(event, args)
          unless event.channel.nsfw?
            return '💔 I can\'t post those here... Try a NSFW channel~ 😳'
          end

          count_str = args.first
          count = if count_str && count_str.match?(/^\d+$/)
                    [[count_str.to_i, 1].max, 25].min
                  else
                    2
                  end

          tags = if count_str && count_str.match?(/^\d+$/)
                   args[1..].join(' ')
                 else
                   args.join(' ')
                 end

          clean_args = (tags || '').downcase.gsub(/[^a-z]/, '')
          if BANNED_SEARCH_TERMS.any? { |term| clean_args.include?(term) }
            return '❌ That search is against Discord ToS. I won\'t search for that.'
          end

          begin
            url = if tags.nil? || tags.empty?
                    "https://rule34.xxx/index.php?page=dapi&s=post&q=index&json=1&limit=100&pid=#{rand(2000)}"
                  else
                    "https://rule34.xxx/index.php?page=dapi&s=post&q=index&json=1&limit=100&tags=#{CGI.escape(tags)}"
                  end

            uri = URI(url)
            response = Net::HTTP.get(uri)
            results = JSON.parse(response)

            if results.empty?
              return "❌ No results found for `#{tags}`"
            end

            selected = results.sample(count)
            urls = selected.map { |r| "https://img.rule34.xxx/images/#{r['directory']}/#{r['image']}" }

            event.respond(urls.join("\n"))
          rescue StandardError => e
            event.respond('💔 Couldn\'t fetch images right now~')
          end
          nil
        end

        def parse_user_mention(mention)
          match = mention.match(/<@!?(\d+)>/)
          return match[1].to_i if match

          id = mention.to_i
          id.positive? ? id : nil
        end

        def create_embed(title:, description: nil, fields: [], color: 0xFF69B4)
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
