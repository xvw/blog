open Js_of_ocaml
    
module type OPTION =
sig
  type 'a t
  val empty : 'a t
  val return : 'a -> 'a t
  val map : 'a t -> ('a -> 'b) -> 'b t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
  val test : 'a t -> bool
  val iter : 'a t -> ('a -> unit) -> unit
  val case : 'a t -> (unit -> 'b) -> ('a -> 'b) -> 'b
  val get : 'a t -> (unit -> 'a) -> 'a
  val of_opt : 'a Js.Opt.t -> 'a t
  val of_optdef : 'a Js.Optdef.t -> 'a t
  val of_option : 'a option -> 'a t
  val to_opt : 'a t -> 'a Js.Opt.t
  val to_optdef : 'a t -> 'a Js.Optdef.t
  val to_option : 'a t -> 'a option
  val to_bool : 'a t -> bool

  module Infix :
  sig
    val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
    val (>|=) : 'a t -> ('a -> 'b) -> 'b t
    val (>>!) : 'a t -> (unit -> 'a) -> 'a
  end

  include module type of Infix
end

module Option : OPTION with type 'a t = 'a option
module Opt : OPTION with type 'a t = 'a Js.opt
module Optdef : OPTION with type 'a t = 'a Js.optdef
