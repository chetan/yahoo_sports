require File.dirname(__FILE__) + '/../test_helper.rb'

class MLB_Test < MiniTest::Unit::TestCase

    def test_get_homepage_games
        games = YahooSports::MLB.get_homepage_games
        assert games
        refute_empty games
    end

    def test_get_team_stats
        run_test("NYY")
    end

    def test_get_team_stats_by_name
        run_test("yankees")
    end

    private

    def run_test(str)
        team = YahooSports::MLB.get_team_stats(str)
        assert(team.name)
        assert_equal("New York Yankees", team.name)
        assert(team.standing)
        assert(team.standing =~ /^\d+\-\d+$/)
        assert(team.position)
        assert((not (team.last5.empty? and team.next5.empty?)), "last 5 and next 5 games")
        assert(team.next5)
    end

end
