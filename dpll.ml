open List

(* fonctions utilitaires *********************************************)
(* filter_map : ('a -> 'b option) -> 'a list -> 'b list
   disponible depuis la version 4.08.0 de OCaml dans le module List :
   pour chaque élément de `list', appliquer `filter' :
   - si le résultat est `Some e', ajouter `e' au résultat ;
   - si le résultat est `None', ne rien ajouter au résultat.
   Attention, cette implémentation inverse l'ordre de la liste *)
let filter_map filter list =
  let rec aux list ret =
    match list with
    | []   -> ret
    | h::t -> match (filter h) with
      | None   -> aux t ret
      | Some e -> aux t (e::ret)
  in aux list []

(* print_modele : int list option -> unit
   affichage du résultat *)
let print_modele: int list option -> unit = function
  | None   -> print_string "UNSAT\n"
  | Some modele -> print_string "SAT\n";
     let modele2 = sort (fun i j -> (abs i) - (abs j)) modele in
     List.iter (fun i -> print_int i; print_string " ") modele2;
     print_string "0\n"

(* ensembles de clauses de test *)
let exemple_3_12 = [[1;2;-3];[2;3];[-1;-2;3];[-1;-3];[1;-2]]
let exemple_7_2 = [[1;-1;-3];[-2;3];[-2]]
let exemple_7_4 = [[1;2;3];[-1;2;3];[3];[1;-2;-3];[-1;-2;-3];[-3]]
let exemple_7_8 = [[1;-2;3];[1;-3];[2;3];[1;-2]]
let systeme = [[-1;2];[1;-2];[1;-3];[1;2;3];[-1;-2]]
let coloriage = [[1;2;3];[4;5;6];[7;8;9];[10;11;12];[13;14;15];[16;17;18];[19;20;21];[-1;-2];[-1;-3];[-2;-3];[-4;-5];[-4;-6];[-5;-6];[-7;-8];[-7;-9];[-8;-9];[-10;-11];[-10;-12];[-11;-12];[-13;-14];[-13;-15];[-14;-15];[-16;-17];[-16;-18];[-17;-18];[-19;-20];[-19;-21];[-20;-21];[-1;-4];[-2;-5];[-3;-6];[-1;-7];[-2;-8];[-3;-9];[-4;-7];[-5;-8];[-6;-9];[-4;-10];[-5;-11];[-6;-12];[-7;-10];[-8;-11];[-9;-12];[-7;-13];[-8;-14];[-9;-15];[-7;-16];[-8;-17];[-9;-18];[-10;-13];[-11;-14];[-12;-15];[-13;-16];[-14;-17];[-15;-18]]

(********************************************************************)

(* simpl_clauses : (a' -> b' option) -> 'c -> int list list -> int list list 
   applique la simplification à chaque clause de la CNF *)
  let rec simpl_clauses filter i clauses =
  match clauses with
  | []      -> []
  | a::tail -> (filter_map filter a)::(simpl_clauses filter i tail) 

(* simplifie : int -> int list list -> int list list 
   applique la simplification de l'ensemble des clauses en mettant
   le littéral i à vrai *)
let rec simplifie i clauses =
  let f_clause arr = if (List.mem i arr) then None else Some arr in
  let f_List k = if k = -i then None else Some k in
  filter_map f_clause (simpl_clauses f_List i clauses)


(* solveur_split : int list list -> int list -> int list option
   exemple d'utilisation de `simplifie' *)
let rec solveur_split clauses interpretation =
  (* l'ensemble vide de clauses est satisfiable *)
  if clauses = [] then Some interpretation else
  (* un clause vide est insatisfiable *)
  if mem [] clauses then None else
  (* branchement *) 
  let l = hd (hd clauses) in
  let branche = solveur_split (simplifie l clauses) (l::interpretation) in
  match branche with
  | None -> solveur_split (simplifie (-l) clauses) ((-l)::interpretation)
  | _    -> branche

(* tests *)
(* let () = print_modele (solveur_split systeme []) *)
(* let () = print_modele (solveur_split coloriage []) *)

(* solveur dpll récursif *)

(*--------------- Unitaire --------------*)  
(* get_litteral : a' list -> a'
      fonction auxiliaire pour - retourne le littéral d'une clause unitaire *)
let get_litteral clause =
  match clause with
  | []      -> failwith ("Not found")
  | [a]     -> a
  | _::tail -> failwith ("Not found")

(* unitaire : int list list -> int
    - si `clauses' contient au moins une clause unitaire, retourne
      le littéral de cette clause unitaire ;
    - sinon, lève une exception `Not_found' *)
let rec unitaire clauses =   
  let l = List.hd clauses in   
  if (List.length l = 1) then get_litteral l else unitaire (List.tl clauses)

(*--------------- Pur --------------*)
  
(* union_sans_doublons : a' list -> a' list -> a' list
      fonction auxiliaire pour 'get_list_litteral', retourne l'union sans doublons des littéraux des deux listes *)
  let rec union_sans_doublons l1 l2 = 
  match l1,l2 with 
  | _,[] -> l1
  | [],_ -> l2
  | a1::l1', a2::l2' ->
      if a1 < a2 then a1::(union_sans_doublons l1' l2) else 
      if a2 < a1 then a2::(union_sans_doublons l1 l2') else a1::(union_sans_doublons l1' l2')


(* get_list_litteral : a' list list -> a' list
    fonction auxiliaire pour pur - retourne la liste des literraux d'une CNF *)
let rec get_list_litteral clauses =
  match clauses with
  | []      -> []
  | a::[]   -> union_sans_doublons a (List.tl a)
  | a::tail -> union_sans_doublons ( union_sans_doublons a (List.tl a)) (get_list_litteral tail)

(* pur : int list list -> int
 - si `clauses' contient au moins un littéral pur, retourne ce littéral ;
 - sinon, lève une exception `Failure "pas de littéral pur"*) 
let rec pur clauses =
  let l = get_list_litteral clauses in
  match l with
  | []      -> failwith "pas de litteral pur"
  | a::tail -> if List.mem (- a) l then pur (List.tl clauses) 
      else a

     
(*--------------- Solveur DPLL --------------*)    

let rec solveur_dpll_rec clauses interpretation =
  match clauses with
  | [] -> Some interpretation
  | _ ->
    match (mem [] clauses) with
    | true -> None
    | false -> try let l = unitaire clauses in
          solveur_dpll_rec (simplifie l clauses) (l::interpretation)
          with _ -> 
          try let l1 = pur clauses in 
          solveur_dpll_rec (simplifie l1 clauses) (l1::interpretation)
          with Failure _->
              let l2 = hd (hd clauses) in
              let branche = solveur_dpll_rec (simplifie l2 clauses) (l2::interpretation) in 
              match branche with
              | None -> solveur_dpll_rec (simplifie (-l2) clauses) ((-l2)::interpretation) 
              | _ -> branche

(* tests *)
(* let () = print_modele (solveur_dpll_rec systeme []);; *)
(* let () = print_modele (solveur_dpll_rec coloriage []) *)

let () =
  let clauses = Dimacs.parse Sys.argv.(1) in
  print_modele (solveur_dpll_rec clauses [])
