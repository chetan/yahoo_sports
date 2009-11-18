
module YahooSports

class NBA < Base

    def self.get_homepage_games(state = "")
        super("nba", state)
    end
    
    def self.get_team_stats(str)
        super("nba", str)
    end

end

end
