
module YahooSports

class NHL < Base

    def self.get_homepage_games(state = "")
        super("nhl", state)
    end
    
    def self.get_team_stats(str)
        super("nhl", str)
    end

end

end
