let () = 
  let control = GPIO_Controller.init () in
  Printf.printf "Number of GPIO pins : %i\n%!" (GPIO_Controller.ngpio control);
  Printf.printf "Base : %i\n%!" (GPIO_Controller.base control);
  while true do
    let (pin, v) = Scanf.scanf "%i %i\n" (fun p v -> p,v) in
    if not (GPIO_Controller.exported control pin) then begin
      Printf.printf "Exporting pin %i\n%!" pin;
      GPIO_Controller.export control pin;
    end;
    if GPIO_Controller.direction control pin = `In then begin
      Printf.printf "Toggling direction of pin %i\n%!" pin;
      GPIO_Controller.set_direction control pin `Out
    end;
    if v <> 0 then begin
      Printf.printf "Setting pin %i to ON\n%!" pin;
      GPIO_Controller.set_value control pin `On
    end else begin
      Printf.printf "Setting pin %i to OFF\n%!" pin;
      GPIO_Controller.set_value control pin `Off
    end
  done
