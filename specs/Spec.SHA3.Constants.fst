module Spec.SHA3.Constants

open Lib.IntTypes

#reset-options "--z3rlimit 50 --max_fuel 0 --max_ifuel 0"

unfold let rotc_list: list uint32 =
  [u32 1; u32 3; u32 6; u32 10; u32 15; u32 21; u32 28; u32 36;
   u32 45; u32 55; u32 2; u32 14; u32 27; u32 41; u32 56; u32 8;
   u32 25; u32 43; u32 62; u32 18; u32 39; u32 61; u32 20; u32 44]

unfold let piln_list: list size_t =
  [size 10; size 7; size 11; size 17; size 18; size 3; size 5; size 16;
   size 8; size 21; size 24; size 4; size 15; size 23; size 19; size 13;
   size 12; size 2; size 20; size 14; size 22; size 9; size 6; size 1]

unfold let rndc_list: list uint64 =
  [u64 0x0000000000000001; u64 0x0000000000008082; u64 0x800000000000808a; u64 0x8000000080008000;
   u64 0x000000000000808b; u64 0x0000000080000001; u64 0x8000000080008081; u64 0x8000000000008009;
   u64 0x000000000000008a; u64 0x0000000000000088; u64 0x0000000080008009; u64 0x000000008000000a;
   u64 0x000000008000808b; u64 0x800000000000008b; u64 0x8000000000008089; u64 0x8000000000008003;
   u64 0x8000000000008002; u64 0x8000000000000080; u64 0x000000000000800a; u64 0x800000008000000a;
   u64 0x8000000080008081; u64 0x8000000000008080; u64 0x0000000080000001; u64 0x8000000080008008]

val lemma_rotc_list:
     i:size_nat{i < List.Tot.length rotc_list}
  -> Lemma (0 < uint_v (List.Tot.index rotc_list i) && uint_v (List.Tot.index rotc_list i) < 64)
let lemma_rotc_list i = admit()

val lemma_piln_list:
     i:size_nat{i < List.Tot.length piln_list}
  -> Lemma (size_v (List.Tot.index piln_list i) < 25)
let lemma_piln_list i = admit()
