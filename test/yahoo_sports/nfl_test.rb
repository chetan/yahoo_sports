require File.dirname(__FILE__) + '/../test_helper.rb'

class NFL_Test < Test::Unit::TestCase
  
    def test_get_homepage_games    
        YahooSports::NFL.get_homepage_games
    end
    
    def test_get_team_stats
        YahooSports::NFL.get_team_stats("NYJ")
    end
    
end
