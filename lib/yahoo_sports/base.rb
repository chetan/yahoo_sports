
require 'rubygems'
require 'tzinfo'

require 'net/http'
require 'scrapi'
require 'ostruct'
require 'htmlentities'

module YahooSports

# Fetches the given URL and returns the body
#
# @param [String] URL
# @return [String] contents of response body
def self.fetchurl(url)
    # puts "FETCHING: '#{url}'"
    return Net::HTTP.get_response(URI.parse(URI.escape(url))).body
end

# Strip HTML tags from the given string. Also performs some common entity
# substitutions.
#
# List of entity codes:
# * &nbsp;
# * &amp;
# * &quot;
# * &lt;
# * &gt;
# * &ellip;
# * &apos;
#
# @param [String] html text to be filtered
# @return [String] original string with HTML tags filtered out and entities replaced
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

    # Get the scoreboard games for the given sport. Includes recently completed,
    # live and upcoming games.
    #
    # Source: http://sports.yahoo.com/<sport>
    #
    # Game struct has the following keys:
    #   game.date   # date of game; includes time if preview
    #   game.team1  # visiting team
    #   game.team2  # home team
    #   game.score1 # team1's score, if live or final
    #   game.score2 # team2's score, if live or final
    #   game.state  # live, final or preview
    #   game.tv     # TV station showing the game, if preview and available
    #
    # Example:
    #   #<OpenStruct state="final", score1="34", date=Thu Nov 26 00:00:00 -0500 2009, score2="12", team1="Green Bay", team2="Detroit">
    #
    #
    # @param [String] sport         sport to list, can be one of ["mlb", "nba", "nfl", "nhl"]
    # @param [String] state         Optionally filter for the given state ("live", "final", or "preview")
    # @return [Array<OpenStruct>] list of games
    def self.get_homepage_games(sport, state = "")

        sport.downcase!
        if sport !~ /^(nba|nhl|nfl|mlb)$/ then
            raise sprintf("Invalid param for 'sport' = '%s'", sport)
        end

        state.downcase! if not state.empty?
        if not state.empty? and state !~ /^(live|final|preview)$/ then
            raise sprintf("Invalid param for 'state' = '%s'", state)
        end

        html = YahooSports.fetchurl("http://sports.yahoo.com/#{sport}/proxy/html/scorethin")
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
            gm.team1 = g.teams[0].strip if g.teams[0]
            gm.team2 = g.teams[1].strip if g.teams[1]
            gm.score1 = g.scores[0].strip if g.scores[0]
            gm.score2 = g.scores[1].strip if g.scores[1]

            if g.class_src.include? ' ' then
                gm.state = g.class_src[ g.class_src.index(' ')+1, g.class_src.length ].strip
            else
                gm.state = g.class_src.strip
            end

            gm.tv = $1 if g.extra_src =~ /TV: (.*)/

            status = g.status.strip if g.status
            time_str = (gm.state == "preview" ? " #{status}" : "")

            if sport == 'mlb' then
                gm.date = Time.parse(Time.new.strftime('%Y') + g.date_src[2,4] + time_str)
            else
                gm.date = Time.parse(g.date_src[0,8] + time_str)
            end

            next if not state.empty? and state != gm.state
            games << gm

        }

        return games

    end

    # Retrieves team information for the team in the given sport
    #
    # Source: http://sports.yahoo.com/<sport>/teams/<team>
    #
    # Team struct has the following keys:
    #   team.name       # full team name
    #   team.standing   # current standing
    #   team.position   # position in the conference
    #   team.last5      # previous games results
    #   team.next5      # upcoming scheduled games
    #   team.live       # struct describing in-progress game, if available
    #
    #
    # Games in the last5 and next5 lists have the following keys:
    #   game.date       # date of game
    #   game.team       # full team name
    #   game.status     # score for completed games (e.g. "L 20 - 23") or "preview"
    #   game.away       # boolean value indicating an away game
    #
    # @param [String] sport         sport to list, can be one of ["mlb", "nba", "nfl", "nhl"]
    # @param [String] str           3-letter team code or partial team name
    # @return [OpenStruct] team info
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
        bye_added = false # help us put it in the right place (hopefully)

        games_temp.games.each_index { |i|

            info = games_temp.games[i].split("\n").slice(1, 3)
            if info[0] == "Bye"
                # team is in a bye week
                bye = true
                next
            else
                t = (bye ? i - 1 : i)
                team = games_temp.teams[t].strip
            end

            gm = OpenStruct.new

            info[1] =~ /(\([\d-]+\))/
            record = $1
            status = info[2]

            preview = (status !~ /^(W|L)/)
            date_str = (preview ? "#{info[0]} #{status}" : info[0])
            gm.date = Time.parse(date_str)

            gm.team = "#{team} #{record}".strip
            gm.status = (preview ? "preview" : status)

            gm.away = (info[1] =~ / at / ? true : false)

            if preview then
                if bye and not bye_added then
                    gmb = OpenStruct.new
                    gmb.bye = true
                    next5 << gmb
                    bye_added = true
                end
                next5 << gm
            else
                if bye and not bye_added then
                    gmb = OpenStruct.new
                    gmb.bye = true
                    last5 << gmb
                    bye_added = true
                end
                last5 << gm
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
