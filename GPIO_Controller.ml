
type t = {
  ngpio : int;
  path : string;
  base : int
}

let read_file path name = 
  let full_path = Printf.sprintf "%s/%s" path name in
  if Sys.file_exists full_path then begin
    let input = open_in full_path in
    let data = input_line input in
    close_in input;
    data
  end else ""

let init () = 
  if Unix.getuid () <> 0 then begin
    Printf.eprintf "[ERROR] The GPIO interface requires root privileges.\n";
    Printf.eprintf "        Please run this program as super user\n%!";
    exit 2
  end;
  let gpios = Sys.readdir "/sys/class/gpio/" in
  let rec find_gpio i = 
    if i >= Array.length gpios then begin
      Printf.eprintf "[ERROR] C.H.I.P. kernel version not found.\n%!";
      exit 2
    end;
    let path = Printf.sprintf "/sys/class/gpio/%s" gpios.(i) in
    if Sys.is_directory path && read_file path "label" = "pcf8574a" then begin
      let ngpio = int_of_string (read_file path "ngpio") in
      let base = int_of_string (read_file path "base") in
      {path; ngpio; base}
    end else
      find_gpio (i+1)
  in
  find_gpio 0

let ngpio t = t.ngpio

let base t = t.base

let export t i = 
  if i >= t.ngpio || i < 0 then begin
    Printf.eprintf "[WARN] Cannot export GPIO pin n°%i (Out of bounds)\n%!" i;
  end else begin
    let cmd = Printf.sprintf "echo %i > /sys/class/gpio/export" (t.base + i) in
    Unix.system cmd |> ignore
  end

let unexport t i = 
  if i >= t.ngpio || i < 0 then begin
    Printf.eprintf "[WARN] Cannot unexport GPIO pin n°%i (Out of bounds)\n%!" i;
  end else begin
    let cmd = Printf.sprintf "echo %i > /sys/class/gpio/unexport" (t.base + i) in
    Unix.system cmd |> ignore
  end

let exported t i = 
  if i >= t.ngpio || i < 0 then begin
    Printf.eprintf "[ERROR] Cannot get status of GPIO pin n°%i (Out of bounds)\n%!" i;
    exit 2
  end else begin
    let dir = Printf.sprintf "/sys/class/gpio/gpio%i" (t.base + i) in
    Sys.file_exists dir
  end

let direction t i = 
  if i >= t.ngpio || i < 0 then begin
    Printf.eprintf "[ERROR] Cannot get direction of GPIO pin n°%i (Out of bounds)\n%!" i;
    exit 2
  end else if not (exported t i) then begin
    Printf.eprintf "[ERROR] Cannot get direction of GPIO pin n°%i (Not exported)\n%!" i;
    exit 2
  end else begin
    let dir = Printf.sprintf "/sys/class/gpio/gpio%i" (t.base + i) in
    let dat = read_file dir "direction" in
    if dat = "out" then `Out
    else if dat = "in" then `In
    else begin
      Printf.eprintf "[ERROR] Cannot get direction of GPIO pin n°%i (Unknown error)\n%!" i;
      exit 2
    end
  end

let set_direction t i v = 
  if i >= t.ngpio || i < 0 then begin
    Printf.eprintf "[WARN] Cannot set direction of GPIO pin n°%i (Out of bounds)\n%!" i;
  end else if not (exported t i) then begin
    Printf.eprintf "[WARN] Cannot set direction of GPIO pin n°%i (Not exported)\n%!" i;
  end else begin
    let dir = Printf.sprintf "/sys/class/gpio/gpio%i/direction" (t.base + i) in
    let cmd = Printf.sprintf "echo %s > %s" 
      (match v with
       | `Out -> "out"
       | `In  -> "in")
      dir
    in
    Unix.system cmd |> ignore
  end

let value t i = 
  if i >= t.ngpio || i < 0 then begin
    Printf.eprintf "[ERROR] Cannot get value of GPIO pin n°%i (Out of bounds)\n%!" i;
    exit 2
  end else if not (exported t i) then begin
    Printf.eprintf "[ERROR] Cannot get value of GPIO pin n°%i (Not exported)\n%!" i;
    exit 2
  end else begin
    let dir = Printf.sprintf "/sys/class/gpio/gpio%i" (t.base + i) in
    let dat = read_file dir "value" in
    if dat = "0" then `Off
    else if dat = "1" then `On
    else begin
      Printf.eprintf "[ERROR] Cannot get value of GPIO pin n°%i (Unknown error)\n%!" i;
      exit 2
    end
  end

let set_value t i v = 
  if i >= t.ngpio || i < 0 then begin
    Printf.eprintf "[WARN] Cannot set value of GPIO pin n°%i (Out of bounds)\n%!" i;
  end else if not (exported t i) then begin
    Printf.eprintf "[WARN] Cannot set value of GPIO pin n°%i (Not exported)\n%!" i;
  end else if (direction t i) = `In then begin
    Printf.eprintf "[WARN] Cannot set value of GPIO pin n°%i (Direction = IN)\n%!" i;
  end else begin
    let dir = Printf.sprintf "/sys/class/gpio/gpio%i/value" (t.base + i) in
    let cmd = Printf.sprintf "echo %i > %s" 
      (match v with
       | `Off -> 0
       | `On  -> 1) 
      dir 
    in
    Unix.system cmd |> ignore
  end

