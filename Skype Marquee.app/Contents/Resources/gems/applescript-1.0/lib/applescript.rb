=begin
name = AppleScript.gets("What's your name?")

AppleScript.puts("Thank you")

choice = AppleScript.choose("Which one of these is your name?", ["Leonard", "Mike", "Lucas", name])

if name == choice
  AppleScript.say "You are right"
  picture = AppleScript.choose_file("Find a picture of yourself")

  if File.exists?(picture)
    AppleScript.say "Thanks, I will now post it on Flickr for you"
    # Exercise for the reader, post it on flickr
  end
else
  AppleScript.say "You are wrong, your name is #{name}"
end
=end

class AppleScriptError < StandardError; end
  
class AppleScript
  class << self
    def execute(script)
      osascript = `which osascript`
      if not osascript.empty? and File.executable?(osascript)
        raise AppleScriptError, "osascript not found, make sure it is in the path"
      else
        result = `osascript -e "#{script.gsub('"', '\"')}" 2>&1`
        if result =~ /execution error/
          raise AppleScriptError, result
        end
        AppleScriptString.new(result)
      end
    end
  
    def say(text)
      execute(%{say "#{text.gsub('"', '\"')}"})
    end

    def gets(text)
      execute(%{
      tell application "Finder"
        activate
        display dialog "#{text.gsub('"', '\"')}" default answer "" buttons {"Cancel", "OK"} default button "OK"
      end tell
      }).answer
    end
  
    def puts(text)
      execute(%{
      tell application "Finder"
        activate
        display dialog "#{text.gsub('"', '\"')}" buttons {"OK"} default button "OK"
      end tell
      }).answer
    end
  
    def choose(text="Choose from the following", choices=[], default=nil)
      default ||= choices[0]
      execute(%{
      tell application "Finder"
        activate
        set choiceList to {#{choices.collect{|c| '"'+c+'"'}.join(",")}}
        choose from list choiceList with prompt "#{text.gsub('"', '\"')}"#{%{ default items "#{default}"} if default}
      end tell
      }).choice
    end

    def choose_file(text="Choose a file", type=nil)
      execute(%{
      tell application "Finder"
        activate
        choose file with prompt "#{text.gsub('"', '\"')}" #{%!of type {"#{type}"}! if type}
      end tell
      }).unix_path
    end
  end
end

class AppleScriptString < String
  def unix_path
    gsub(/^(file|alias).*?:/,"/").gsub(/:/,"/").chomp
  end
  
  def button
    gsub(/(.*?)(button returned:)(.*?)($|,.*)/, "\\3").chomp
  end
  
  def answer
    gsub(/(.*?)(text returned:)(.*?)($|,.*)/, "\\3").chomp
  end

  def choice
    gsub(/(.*?)(\{"*?)(.*?)("*?\}.*)/, "\\3").chomp
  end
end
