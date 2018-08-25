let id x = x

module type REQ_OPTION =
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
end

module type OPTION =
sig
  include REQ_OPTION
  val to_bool : 'a t -> bool

  module Infix :
  sig
    val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
    val (>|=) : 'a t -> ('a -> 'b) -> 'b t
    val (>>!) : 'a t -> (unit -> 'a) -> 'a
  end
  include module type of Infix
end

module MakeOpt (F : REQ_OPTION) : OPTION with type 'a t = 'a F.t =
struct
  include F

  let to_bool x  =
    case x (fun () -> false) (fun _ -> true)

  module Infix =
  struct
    let (>>=) = F.bind
    let (>|=) = F.map
    let (>>!) = get
  end
  include Infix
end


module Option : OPTION with type 'a t = 'a option = MakeOpt(struct
    type 'a t = 'a option

    let empty = None
    let return x = Some x

    let map opt f =
      match opt with
      | Some x -> Some (f x)
      | None -> None

    let bind opt f =
      match opt with
      | Some x -> f x
      | None -> None

    let test = function
      | None -> false
      | Some _ -> true

    let iter opt f =
      match opt with
      | Some x -> f x
      | None -> ()

    let case opt elseN ifS =
      match opt with
      | Some x -> ifS x
      | None -> elseN ()

    let get opt f =
      match opt with
      | Some x -> x
      | None -> f ()

    let to_option, of_option = id, id
    let to_optdef, of_optdef = Js.Optdef.(option, to_option)
    let to_opt, of_opt = Js.Opt.(option, to_option)

  end)

module Opt : OPTION with type 'a t = 'a Js.opt = MakeOpt(struct

    include Js.Opt

    let to_opt = id
    let of_opt = id
    let of_option = option

    let to_optdef opt =
      match to_option opt with
      | Some x -> Js.Optdef.return x
      | None -> Js.Optdef.empty

    let of_optdef optdef =
      match Js.Optdef.to_option optdef with
      | Some x -> return x
      | None -> empty
  end)


module Optdef : OPTION with type 'a t = 'a Js.optdef = MakeOpt(struct
    include Js.Optdef

    let to_optdef = id
    let of_optdef = id
    let of_option = option

    let to_opt opt =
      match to_option opt with
      | Some x -> Js.Opt.return x
      | None -> Js.Opt.empty

    let of_opt optdef =
      match Js.Opt.to_option optdef with
      | Some x -> return x
      | None -> empty
  end)
