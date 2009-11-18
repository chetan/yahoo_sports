
module YahooSports

class NFL < Base

    def self.get_homepage_games(state = '')
        return super('nfl', state)
    end
    
    def self.find_team_page(str)
    
        begin
            html = YahooSports.fetchurl('http://sports.yahoo.com/nfl/teams/' + str)
        rescue => ex
            puts ex
            return
        end
        
        search = false
        teams = nil
        if /<h1 class="yspseohdln"><\/h1>/.match(html) then
            # invalid 3 letter code was entered, find a matching team name
            search = true
            teams = html.scan(/<option value="\/nfl\/teams\/(.*?)">(.*?)<\/option>/)    
            
        elsif /<title>NFL - Teams - Yahoo! Sports<\/title>/.match(html) then
            # invalid team name entered, see if we can find it
            search = true
            teams = html.scan(%r|<a href="/nfl/teams/(.*?)/">(.*?)</a>|)
            
        end
        
        if search then
            # look for team name
            q = str.downcase
            team = teams.find { |t| 
                t[1].downcase == q or t[1].downcase.include? q 
            }
            
            return nil if not team
            
            # found a likely match, load their page
            return [ team[0], YahooSports.fetchurl('http://sports.yahoo.com/nfl/teams/' + team[0]) ]
            
        end
        
        return [ str, html ]
    
    end
    
    def self.get_team_stats(str)

        (team, html) = find_team_page(str)
        if html.nil? then
            raise sprintf("Can't find team '%s'", str)
        end
        
        
        info_scraper = Scraper.define do
        
            process "h1.yspseohdln:first-child", :name => :text
            process "p.team-standing", :standing => :text
            
            result :name, :standing
            
        end
        
        info = info_scraper.scrape(html)
        
        (schedule, last_game, next_game) = parse_schedule(html)
  
        return OpenStruct.new({:name     => info.name,
                               :standing => info.standing,
                               :last     => last_game,
                               :next     => next_game,
                               :schedule => schedule})
        
    end
    
    def self.last_and_next(schedule)
    
        today = Time.new.strftime("%m/%d/%Y")
        schedule.each_index { |i|
        
            if schedule[i].date.strftime("%m/%d/%Y") == today || 
                schedule[i].date > Time.new then
                # found a game today or the next game
                return [ schedule[i-1], schedule[i] ] # return last, next/current
            end
        
        }
    
    end
    
    def self.parse_schedule(html)
            
        schedule_scraper = Scraper.define do
            array :games
            process "td.ysptblbdr2 tr.ysprow2 > td.yspscores", :games => :text
            process "td.ysptblbdr2 tr.ysprow1  > td.yspscores", :games => :text
            result :games
        end

        sched = schedule_scraper.scrape(html)        
        schedule = []
        
        for i in 1..17 do # only want the first 17 entries
            
            date = YahooSports.strip_tags(sched.shift)
            team = YahooSports.strip_tags(sched.shift)
            time_or_score = YahooSports.strip_tags(sched.shift)
            
            next if team == 'bye'
            
            game = OpenStruct.new
            if team =~ /^(at )?(.*)$/ then
                if $1 then
                    game.away = true
                    game.team = $2
                else
                    game.away = false
                    game.team = $2
                end
            end
            
            if time_or_score =~ /^(W|L).*$/ then
                # score
                game.status = time_or_score
                game.date = Time.parse(date)
            else
                game.status = 'Scheduled'
                game.date = Time.parse("#{date} #{time_or_score}")
            end
            
            schedule << game
            
        end
        
        (last_game, next_game) = last_and_next(schedule)
        
        return [ schedule, last_game, next_game ]
    
    end
    
end

end
