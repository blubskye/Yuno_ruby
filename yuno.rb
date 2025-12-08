#!/usr/bin/env ruby
# frozen_string_literal: true

#
# Yuno Gasai 2 (Ruby Edition)
# "I'll protect this server forever... just for you~" <3
#
# Copyright (C) 2025 blubskye
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#

require 'dotenv/load'
require_relative 'lib/bot'

def print_banner
  puts <<~BANNER

    💕 ╔═══════════════════════════════════════════╗ 💕
       ║     Yuno Gasai 2 (Ruby Edition)           ║
       ║     "I'll protect you forever~" 💗        ║
       ╚═══════════════════════════════════════════╝

  BANNER
end

print_banner

# Handle graceful shutdown
trap('INT') do
  puts "\n💔 Yuno is shutting down... goodbye, my love~ 💔"
  exit
end

trap('TERM') do
  puts "\n💔 Yuno is shutting down... goodbye, my love~ 💔"
  exit
end

begin
  puts '💕 Yuno is waking up... please wait~'
  bot = Yuno::Bot.new
  bot.run
rescue StandardError => e
  puts "💔 Fatal error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end
