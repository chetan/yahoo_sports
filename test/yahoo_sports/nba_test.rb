require File.dirname(__FILE__) + '/../test_helper.rb'

class NBA_Test < Test::Unit::TestCase
  
    def test_get_homepage_games    
        YahooSports::NBA.get_homepage_games
    end
    
    def test_get_team_stats
        run_test("NYK")
    end
    
    def test_get_team_stats_by_name
        run_test("knicks")
    end
    
    private
    
    def run_test(str)
        team = YahooSports::NBA.get_team_stats(str)
        assert(team.name)
        assert_equal("New York Knicks", team.name)
        assert(team.standing)
        assert(team.standing =~ /^\d+\-\d+$/)
        assert(team.position)
        assert((not (team.last5.empty? and team.next5.empty?)), "last 5 and next 5 games")
        assert(team.next5)
    end
    
end
