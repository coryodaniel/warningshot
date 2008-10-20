module WarningShot
  class Growl
    
    def Growl.say(msg)
      img = WarningShot.dir_for(:images) / 'warning_shot_sml.png'

      gmsg = %{growlnotify -t "WarningShot" -n "WarningShot" -m "#{msg}"}
      gmsg += %{ --image #{img}} unless img.nil?

      %x{#{gmsg}}
    end

  end
end
