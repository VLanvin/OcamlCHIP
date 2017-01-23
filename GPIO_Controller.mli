
type t

val init : unit -> t

val ngpio : t -> int

val base : t -> int

val export : t -> int -> unit

val unexport : t -> int -> unit

val exported : t -> int -> bool

val direction : t -> int -> [`In | `Out]

val set_direction : t -> int -> [`In | `Out] -> unit

val value : t -> int -> [`On | `Off]

val set_value : t -> int -> [`On | `Off] -> unit

