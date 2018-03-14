type token =
  | Right
  | Left
  | Incr
  | Decr
  | Print
  | Read
  | Loop of token list


let parse stream =
  let rec parse acc =
    match Stream.next stream with
    | '>' -> parse (Right :: acc)
    | '<' -> parse (Left :: acc)
    | '+' -> parse (Incr :: acc)
    | '-' -> parse (Decr :: acc)
    | '.' -> parse (Print :: acc)
    | ',' -> parse (Read :: acc)
    | '[' ->
       let loop = parse [] in
       parse ((Loop loop) :: acc)
    | ']' -> List.rev acc
    | _ -> parse acc
    | exception Stream.Failure -> List.rev acc
  in parse []
