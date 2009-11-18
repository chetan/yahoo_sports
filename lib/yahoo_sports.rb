$:.unshift(File.dirname(__FILE__)) unless
    $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module YahooSports
    
    autoload :Base, "yahoo_sports/base"
    autoload :MLB, "yahoo_sports/mlb"
    autoload :NBA, "yahoo_sports/nba"
    autoload :NFL, "yahoo_sports/nfl"
    autoload :NHL, "yahoo_sports/nhl"
    
end