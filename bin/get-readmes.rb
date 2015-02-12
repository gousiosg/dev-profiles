#!/usr/bin/env ruby

require 'ghtorrent'
require 'parallel'
require 'open-uri'
require 'net/http'

class PullReqDataExtraction < GHTorrent::Command

  def prepare_options(options)
    options.banner <<-BANNER
Get all README.md files for repositories in dev's profile

#{command_name} dev

    BANNER
  end

  def validate
    super
    Trollop::die 'One argument required' unless !args[0].nil?
  end

  def ght
    Thread.current[:ght] ||= GHTorrent::Mirror.new(settings)
    Thread.current[:ght]
  end

  def db
    Thread.current[:sql_db] ||= ght.get_db
    Thread.current[:sql_db]
  end

  def go

    dev = ARGV[0]
    user = db[:users].first(:login => dev)
    repos = db[:projects].where(:owner_id => user[:id], :deleted => false)

    #Parallel.map(repos, :in_threads => 4) do |repo|
    repos.each do |repo|

      url = "https://raw.github.com/#{user[:login]}/#{repo[:name]}/master/README.md"
      fname = "#{dev}@#{repo[:name]}@#{if repo[:forked_from].nil? then 'orig' else 'fork' end}@README.md"
      puts "Getting: #{url} -> #{fname}"

      uri = URI.parse(url)
      f = File.open("data/#{fname}", 'w')
      begin
        open(uri) do |resp|
          resp.each_line {|line| f.write line}
        end
      rescue Exception => e
        puts "Cannot open #{url}: #{e.message}"
      ensure
        f.close
      end

    end

  end
end

PullReqDataExtraction.run