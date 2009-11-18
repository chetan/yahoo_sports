
require 'rubygems'
require 'tzinfo'

require 'net/http'
require 'scrapi'
require 'ostruct'
require 'htmlentities'

module YahooSports

# little helper method i wrote to retry the fetch a few times
def self.fetchurl(url)
    puts "FETCHING #{url}"
    return Net::HTTP.get_response(URI.parse(URI.escape(url))).body    
end

def self.strip_tags(html)
		
    HTMLEntities.new.decode(
        html.gsub(/<.+?>/,'').
        gsub(/&nbsp;/,' ').
        gsub(/&amp;/,'&').
        gsub(/&quot;/,'"').
        gsub(/&lt;/,'<').
        gsub(/&gt;/,'>').
        gsub(/&ellip;/,'...').
        gsub(/&apos;/, "'").
        gsub(/<br *\/>/m, '')
    ).strip

end

class Base

    def self.get_homepage_games(sport, state = '')

        sport.downcase!
        if sport !~ /^(nba|nhl|nfl|mlb)$/ then
            raise sprintf("Invalid param for 'sport' = '%s'", sport)
        end
        
        state.downcase! if not state.empty?
        if not state.empty? and state !~ /^(live|final|preview)$/ then
            raise sprintf("Invalid param for 'state' = '%s'", state)
        end
    
        html = YahooSports.fetchurl('http://sports.yahoo.com/' + sport)
        if not html then
            raise 'Error fetching url'
        end

        sports_game = Scraper.define do
        
            array :teams
            array :scores
            
            process "li.odd, li.even, li.live", :date_src => "@id"
            process "li.odd, li.even, li.live", :class_src => "@class"
            process "li.link-box", :extra_src => :text
            
            process "td.team>a", :teams => :text
            process "td.score", :scores => :text
            
            process "li.status>a", :status => :text
            
            
            result :date_src, :teams, :scores, :status, :class_src, :extra_src
            
        end
        
        sports = Scraper.define do
            
            array :games
            
            process "ul.game-list>li", :games => sports_game
            
            result :games
            
        end
        
        games_temp = sports.scrape(html)

        games = []
        
        return games if games_temp.nil?
        
        games_temp.each { |g|
        
            gm = OpenStruct.new
            gm.status = g.status.strip if g.status
            gm.team1 = g.teams[0].strip if g.teams[0]
            gm.team2 = g.teams[1].strip if g.teams[1]
            gm.score1 = g.scores[0].strip if g.scores[0]
            gm.score2 = g.scores[1].strip if g.scores[1]
                                 
            if sport == 'mlb' then
                gm.date = Time.parse(Time.new.strftime('%Y') + g.date_src[2,4])
            else
                gm.date = Time.parse(g.date_src[0,8])
            end
            
            if g.class_src.include? ' ' then
                gm.state = g.class_src[ g.class_src.index(' ')+1, g.class_src.length ].strip
            else
                gm.state = g.class_src.strip
            end
            
            gm.extra = $1 if g.extra_src =~ /TV: (.*)/
            
            next if not state.empty? and state != gm.state
            games << gm
        
        }
        
        return games
    
    end
    
    def self.get_team_stats(sport, str)
        
        sport.downcase!
        if sport !~ /^(nba|nhl|nfl|mlb)$/ then
            raise sprintf("Invalid param for 'sport' = '%s'", sport)
        end

        str.downcase!
        (team, html) = find_team_page(sport, str)
        if html.nil? then
            raise sprintf("Can't find team '%s'", str)
        end
        
        info = get_team_info(html)
        last5, next5 = get_scores_and_schedule(html)
        live_game = get_live_game(info.name, html)
        
        return OpenStruct.new({:name => info.name,
                               :standing => info.standing,
                               :position => info.position,
                               :last5 => last5,
                               :next5 => next5,
                               :live  => live_game})
    end
    
    
    private
    
    def self.get_team_info(html)
        
        info_scraper = Scraper.define do
            
            process "div#team-header div.info h1", :name => :text
            process "div#team-header div.info div.stats li.score", :standing => :text
            process "div#team-header div.info div.stats li.position", :position => :text
            
            result :name, :standing, :position
        end
        
        info_temp = info_scraper.scrape(html)
        
        info = OpenStruct.new
        return info if info_temp.nil?
        
        info.name = info_temp.name
        info_temp.standing.gsub!(/,/, '')
        info.standing = info_temp.standing
        info.position = info_temp.position        
        return info        
    end
    
    
    def self.get_scores_and_schedule(html)

        last5 = []
        next5 = []
        
        games_scraper = Scraper.define do
        
            array :games
            array :teams
            
            process "div#team-schedule-list div.bd table tbody tr", :games => :text
            process "div#team-schedule-list div.bd table tbody tr td.title span", :teams => :text
            
            result :games, :teams
            
        end
        
        games_temp = games_scraper.scrape(html)
        
        return [last5, next5] if games_temp.nil?
                
        bye = false # bye week support for nfl
        
        games_temp.games.each_index { |i|
            
            info = games_temp.games[i].split("\n").slice(1, 3)
            if info[0] == "Bye"
                bye = true
                team = nil
            else
                t = (bye ? i - 1 : i)
                team = games_temp.teams[t].strip
            end
            
            gm = OpenStruct.new
            
            if bye then
                # team is in a bye week
                gm.bye = true
                next5 << gm
                next
            end
            
            date = Time.parse(info[0])
            info[1] =~ /(\([\d-]+\))/
            record = $1
            status = info[2]
            
            gm.date = date
            gm.team = "#{team} #{record}"
            gm.status = status

            if info[1] =~ / at / then
                gm.away = 1
            else
                gm.away = 0
            end
                        
            if gm.status =~ /^(W|L)/
                last5 << gm 
            else
                next5 << gm
            end
            
        }
        
        return [last5, next5]
    end
    
    def self.get_live_game(team, html)
    
        return nil if html !~ /In Progress Game/
        
        team_scraper = Scraper.define do
           
            process_first "td:nth-child(2)", :name => :text
            process_first "td:nth-child(4)", :runs => :text
            process_first "td:nth-child(5)", :hits => :text
            process_first "td:nth-child(6)", :errors => :text
            
            result :name, :runs, :hits, :errors
            
        end
        
        live_scraper = Scraper.define do
            array :teams
            process_first "td.yspscores", :inning => :text
            process "tr.ysptblclbg5", :teams => team_scraper
            result :inning, :teams
        end
        
        game = live_scraper.scrape(html)
        game = struct_to_ostruct(game)
        game.inning.strip!
        
        # they are at home if team 1 (2nd team) is them
        if game.teams[1].name.split.size > 1 then
            t = game.teams[1].name.split[-1]
        else
            t = game.teams[1].name
        end
        
        if team.include? t then
            # home game
            game.home = true
        else
            game.home = false            
        end

        # helpers        
        game.away_team = game.teams[0]
        game.home_team = game.teams[1]
        game.delete_field('teams')
        
        return game
        
    end
    
    def self.find_team_page(sport, str)
        
        sport.downcase!
        str.downcase!        
    
        begin
            html = YahooSports.fetchurl("http://sports.yahoo.com/#{sport}/teams/" + str)
        rescue => ex
            puts ex
            return
        end
        
        if html !~ %r{<title><MapleRegion id ="page_title_generic"/></title>} then
            # got the right page
            return [str, html]
        end
        
        # look for it
        begin
            html = YahooSports.fetchurl("http://sports.yahoo.com/#{sport}/teams")
        rescue => ex
            puts ex
            return
        end


        team_scraper = Scraper.define do
            array :teams, :links
            process "table.yspcontent tr.ysprow1", :teams => :text
            process "table.yspcontent tr.ysprow1 a", :links => "@href"
            process "table.yspcontent tr.ysprow2", :teams => :text
            process "table.yspcontent tr.ysprow2 a", :links => "@href"
            result :teams, :links
        end
        
        ret = team_scraper.scrape(html)
        return nil if ret.nil?
        
        ret.teams.each_index { |i|
            t = ret.teams[i]
            l = ret.links[i].strip.gsub(%r{/$}, "") # strip trailing slash for nfl
            t = YahooSports.strip_tags(t).strip
            
            if t == str or t.downcase.include? str then
                # found a matching team
                begin
                    html = YahooSports.fetchurl("http://sports.yahoo.com#{l}")
                rescue => ex
                    puts ex
                    return
                end
                t =~ %r{^/[a-z]+/teams/(.+)$}
                return [$1, html]
            end
        }
        
        return nil
    
    end
    
    def self.struct_to_ostruct(struct)
        hash = {}
        struct.each_pair { |key,val|
            if val.kind_of? Struct then
                val = struct_to_ostruct(val)
            elsif val.kind_of? Array then
                val.map! { |v| v.to_s =~ /struct/ ? struct_to_ostruct(v) : v }
            end
            hash[key] = val
        }
        return OpenStruct.new(hash)
    end

end

end
