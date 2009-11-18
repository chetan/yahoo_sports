require File.dirname(__FILE__) + '/../test_helper.rb'

class YahooSports_Test < Test::Unit::TestCase
  
    def test_get_homepage_games_sport_check
        
        begin
            YahooSports::Base.get_homepage_games("MLB")
        rescue RuntimeError => e
            if e.message =~ /Invalid param/ then
                flunk("no exception should have been raised")
            end
        end
        
    end
    
end
