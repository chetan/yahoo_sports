
module YahooSports

class NHL < Base

	def self.get_homepage_games(state = '')
        return super('nhl', state)
	end
	
	def self.find_team_page(str)
	
		begin
			html = YahooSports.fetchurl('http://sports.yahoo.com/nhl/teams/' + str)
		rescue => ex
			print ex.inspect
			print ex.backtrace.join("\n")
			return
		end
		
		search = false
		teams = nil
		if /<h1 class="yspseohdln"><\/h1>/.match(html) then
			# invalid 3 letter code was entered, find a matching team name
			search = true
			teams = html.scan(/<option value="\/nhl\/teams\/(.*?)">(.*?)<\/option>/)	
			
		elsif /<title>NHL - Teams - Yahoo! Sports<\/title>/.match(html) then
			# invalid team name entered, see if we can find it
			search = true
			teams = html.scan(/<a href=\/nhl\/teams\/(.*?)>(.*?)<\/a>/)
			
		end
		
		if search then
			# look for team name
			q = str.downcase
			team = teams.find { |t| 
				t[1].downcase == q or t[1].downcase.include? q 
			}
			
			if not team then
				m.reply sprintf("Can't find team '%s'", str)
				return
			end
			
			# found a likely match, load their page
			team = team[0]
			html = YahooSports.fetchurl('http://sports.yahoo.com/nhl/teams/' + team)

        else
            team = str
    
        end
		
		return [ team, html ]
	
	end
	
	def self.get_team_stats(str)

		(team, html) = find_team_page(str)
		if html.nil? then
			raise sprintf("Can't find team '%s'", str)
		end
		
		info = {}
		
		# get team name and rank
		nm = /<span class="yspsctnhdln">(.*?)<\/span><br><span class="yspartclsrc">(.*?)<\/span>/.match(html)
		info['name'] = nm[1]
		info['rank'] = nm[2]
		
		# get results of last game
		matches = /<td class="yspscores">.*<b>(.*?)(<a href="\/nhl\/teams\/[a-z]+">)(.*?)(<\/a>), <a href="\/nhl\/recap(.*?)">(.*?)<\/a>/m.match(html)
		
		if matches then 
			#m.reply sprintf("%s (%s): %s %s - %s", name, rank, matches[1].strip, matches[3].strip, matches[6].strip)
			
			last_game = {
			    'date' => matches[1].strip,
			    'team' => matches[3].strip,
			    'score' => matches[6].strip
			}
			info['last'] = last_game
			return info
			
		else 
			# could be a game going on now
			scores = html.scan(/<span class="yspscores">(\d+)<\/span>/)
			teams = html.scan(/<b><a href="\/nhl\/teams\/.*?">(.*?)<\/a><\/b>/)
			nm = /<span class="yspsctnhdln">(.*?)<\/span><br><span class="yspartclsrc">(.*?)<\/span>/.match(html)
            info['name'] = nm[1]
            info['rank'] = nm[2]

            live_game = {}
			if not name.include? teams[0][0] then
			    live_game['away'] = 0
			    live_game['team'] = teams[0][0]
			else
			    live_game['away'] = 1
			    live_game['team'] = teams[1][0]
			end
			
			live_game['date'] = Time.now
			live_game['score1'] = scores[0]
			live_game['score2'] = scores[1]
			info['live'] = live_game
			
			return info
			
		end
		
	end

end

end
