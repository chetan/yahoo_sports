
module YahooSports

class MLB < Base

    def self.get_homepage_games(state = "")
        super("mlb", state)
    end
    
    def self.get_team_stats(str)
        super("mlb", str)
    end

end

end
