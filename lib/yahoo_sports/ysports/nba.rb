
require 'scrapi'

module YahooSports

class NBA < Base

	def self.get_homepage_games(state = '')
        return super('nba', state)
	end
	
	def self.find_team_page(str)
	
		begin
			html = YahooSports.fetchurl('http://sports.yahoo.com/nba/teams/' + str)
		rescue => ex
			#debug ex.inspect
			#debug ex.backtrace.join("\n")
			return
		end
		
		search = false
		teams = nil
		if /<h1 class="yspseohdln"><\/h1>/.match(html) then
			# invalid 3 letter code was entered, find a matching team name
			search = true
			teams = html.scan(/<option value="\/nba\/teams\/(.*?)">(.*?)<\/option>/)	
			
		elsif /<title>NBA - Teams - Yahoo! Sports<\/title>/.match(html) then
			# invalid team name entered, see if we can find it
			search = true
			teams = html.scan(/<a href=\/nba\/teams\/(.*?)>(.*?)<\/a>/)
			
		end
		
		if search then
			# look for team name
			q = str.downcase
			team = teams.find { |t| 
				t[1].downcase == q or t[1].downcase.include? q 
			}
			
			return nil if not team
			
			# found a likely match, load their page
			return [ team[0], YahooSports.fetchurl('http://sports.yahoo.com/nba/teams/' + team[0]) ]
			
		end
		
		return [ str, html ]
	
	end
	
	def self.get_team_stats(str)

		(team, html) = find_team_page(str)
		if html.nil? then
			raise sprintf("Can't find team '%s'", str)
		end
		
		# already got html and team name?
		
		info = {}

		team_scraper = Scraper.define do
		    process_first "h1.yspseohdln", :name => :text
		    process_first "p.team-standing", :rank => :text
		end

	    team = team_scraper.scrape(html)
	    info['name'] = team.name
	    info['rank'] = team.rank

        # TODO: replace with scrapi		
		# get last 5 games and next 5 games
		
		games = html.scan(%r_<tr class="ysprow\d"><td class=yspscores>&nbsp;(.*?)</td><td class=yspscores nowrap>(.*?)<a href="/\w{3}/teams/.*?">(.*?)</a></td><td align=right class=yspscores nowrap>((<a href=/\w{3}/\w+\?gid=\d+>(.*?)</a>)|(.*?)&nbsp;</td></tr>)_)
		
		last5 = []
		next5 = []
		
		games.each { |g|

		    game = { 'date' => Time.parse(g[0]),
		             'away' => g[1].strip == 'at' ? 1 : 0,
		             'team' => g[2].strip }

		    if g[3].include? 'recap' then
		        # last 5 games
		        game['score'] = g[5]
		        last5 << game
		    else
                # next 5
                if g[3].include? 'preview' then
                    game['time'] = g[5].strip
                else
                    game['time'] = g[6].strip
                end
                next5 << game
		    end
		}
		
		info['last5'] = last5
		info['next5'] = next5
        
        last_game = info['last5'][-1]
        
        last_game['team'] = 'at ' + last_game['team'] if last_game['at']
        
        info['last'] = last_game
        
        return info
		
		# get results of last game
		matches = /<td colspan="2" style="padding-bottom: 4px;" class="yspscores">.*<b>(.*?)(<a href="\/nba\/teams\/[a-z]+">)(.*?)(<\/a>), <a href="\/nba\/recap(.*?)">(.*?)<\/a>&nbsp;.*<\/b>.*<\/td>/m.match(html)
		
		if matches then 
		    info['date'] = Time.parse(matches[1].strip)
		    info['vs']   = matches[3].strip
		    info['score'] = matches[6].strip
		    
		    #debug info.to_yaml
		    
			return sprintf("%s (%s): %s %s - %s", info['name'], info['rank'], matches[1].strip, matches[3].strip, matches[6].strip)
			

		else 
			# could be a game going on now
			scores = html.scan(/<span class="yspscores">(\d+)<\/span>/)
			teams = html.scan(/<b><a href="\/nba\/teams\/.*?">(.*?)<\/a><\/b>/)
			# get time left in game/quarter/etc
			times = html.scan(/<td align="right" class="ysptblclbg6"><span class="yspscores">(.*?)<\/span>&nbsp;<\/td>/)
			nm = /<span class="yspsctnhdln">(.*?)<\/span>(<br><span class="yspartclsrc">(.*?)<\/span>)?<br><span class=yspartclsrc>(.*?)<\/span>/.match(html)
			name = nm[1]
			if not nm[3].nil? then
				rank = nm[3] # during playoffs, conference ranking
			else
				rank = nm[4]
			end
			
			if not name.include? teams[0][0] then
				vs = 'vs ' + teams[0][0]
				scores[1][0] += '*'
			else
				vs = 'at ' + teams[1][0]
				scores[0][0] += '*'
			end
			
			sprintf("%s (%s): %s %s %s - %s (live, %s %s)", name, rank, Time.now.strftime("%b %d, %Y"), vs, scores[0], scores[1], times[0], times[1])
		end
		
	end

end

end
