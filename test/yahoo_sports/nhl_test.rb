require File.dirname(__FILE__) + '/../test_helper.rb'

class NHL_Test < Test::Unit::TestCase
  
    def test_get_homepage_games    
        YahooSports::NHL.get_homepage_games
    end
    
    def test_get_team_stats
        YahooSports::NHL.get_team_stats("NYR")
    end
    
end
