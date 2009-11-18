require File.dirname(__FILE__) + '/../test_helper.rb'

class NBA_Test < Test::Unit::TestCase
  
    def test_get_homepage_games    
        YahooSports::NBA.get_homepage_games
    end
    
    def test_get_team_stats
        YahooSports::NBA.get_team_stats("NYK")
    end
    
end
