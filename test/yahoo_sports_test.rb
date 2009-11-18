require File.dirname(__FILE__) + '/test_helper.rb'

class YahooSports_Test < Test::Unit::TestCase
  
    def test_autoload_classes
        
        assert YahooSports::MLB
        assert YahooSports::NBA
        assert YahooSports::NFL
        assert YahooSports::NHL
        
    end
    
end
