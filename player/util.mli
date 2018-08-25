val id : 'a -> 'a
val log: 'a -> unit
val warn : 'a -> unit
val ( $ ) : ('a -> 'b) -> 'a -> 'b
val rev : ('a -> 'b -> 'c) -> 'b -> 'a -> 'c
val window : Dom_html.window Js.t
val document : Dom_html.document Js.t
val scroll_y : unit -> int
val scroll_x : unit -> int
val get_by_id : string -> Dom_html.element Js.t option
val clear : #Dom_html.element Js.t -> unit
val offset_y : #Dom_html.element Js.t -> int
