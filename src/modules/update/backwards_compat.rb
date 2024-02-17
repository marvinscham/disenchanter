# frozen_string_literal: true

def backwards_compat
  # Doinb 400CS backwards compatibility hack
  updater_processes = `tasklist | find /I /C "disenchanter_up.exe"`

  kill_disenchanter if updater_processes.to_i > 2

  `tasklist|findstr "disenchanter.exe" >nul 2>&1 \
   && echo Backwards compatibility: popping out into separate process... \
   && start cmd.exe @cmd /k "disenchanter_up.exe" \
   && exit`
  sleep(1)
  kill_disenchanter
end

def kill_disenchanter
  puts 'Killing Disenchanter...'
  `taskkill /IM "disenchanter.exe" /F /T >nul 2>&1 && exit`
end
