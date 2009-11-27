
module YahooSports

class NBA < Base
    
    # Get the NBA scoreboard games. Includes recently completed,
    # live and upcoming games.
    #
    # Source: http://sports.yahoo.com/nba
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
    #
    # @param [String] state         Optionally filter for the given state ("live", "final", or "preview")
    # @return [Array<OpenStruct>] list of games
    def self.get_homepage_games(state = "")
        super("nba", state)
    end
    
    # Retrieves team information for the team
    #
    # Source: http://sports.yahoo.com/nba/teams/<team>
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
    #   game.status     # score for completed games (e.g. "L 20 - 23")
    #   game.away       # boolean value indicating an away game
    #
    # @param [String] str           3-letter team code or partial team name
    # @return [OpenStruct] team info
    def self.get_team_stats(str)
        super("nba", str)
    end

end

end
