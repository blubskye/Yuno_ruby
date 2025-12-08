# frozen_string_literal: true

#
# Yuno Gasai 2 (Ruby Edition) - Fun Commands
# Copyright (C) 2025 blubskye
# SPDX-License-Identifier: AGPL-3.0-or-later
#

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

      class << self
        def register(client, bot)
          @bot = bot

          client.command(:'8ball', description: 'Ask the magic 8-ball') do |event, *question_parts|
            question = question_parts.join(' ')
            ask_8ball(event, question)
          end
        end

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

        def create_embed(title:, fields: [], color: 0xFF69B4)
          Discordrb::Webhooks::Embed.new(
            title: title,
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
