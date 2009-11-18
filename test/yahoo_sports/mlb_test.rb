require File.dirname(__FILE__) + '/../test_helper.rb'

class MLB_Test < Test::Unit::TestCase
  
    def test_get_homepage_games    
        YahooSports::MLB.get_homepage_games
    end
    
    def test_get_team_stats
        YahooSports::MLB.get_team_stats("NYY")
    end
    
end
