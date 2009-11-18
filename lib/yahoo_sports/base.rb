
require 'rubygems'
require 'tzinfo'

require 'net/http'
require 'scrapi'
require 'ostruct'
require 'htmlentities'

module YahooSports

# little helper method i wrote to retry the fetch a few times
def self.fetchurl(url)
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
