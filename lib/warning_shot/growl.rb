module WarningShot
  class Growl
    
    def Growl.say(msg)
      img = File.join(WarningShot.dir_for(:images),'warning_shot.png')

      gmsg = %{growlnotify -t "WarningShot" -n "WarningShot" -m "#{msg}"}
      gmsg += %{ --image #{img}} unless img.nil?

      %x{#{gmsg}}
    end

  end
end
