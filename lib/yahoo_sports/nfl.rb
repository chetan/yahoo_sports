
module YahooSports

class NFL < Base

    def self.get_homepage_games(state = "")
        return super("nfl", state)
    end
    
    def self.get_team_stats(str)
        super("nfl", str)
    end
    
end

end
