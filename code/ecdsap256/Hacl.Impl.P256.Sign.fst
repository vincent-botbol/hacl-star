module Hacl.Impl.P256.Sign

open FStar.Mul
open FStar.HyperStack.All
open FStar.HyperStack
module ST = FStar.HyperStack.ST

open Lib.IntTypes
open Lib.Buffer

open Hacl.Impl.P256.Bignum
open Hacl.Impl.P256.Scalar
open Hacl.Impl.P256.Point
open Hacl.Impl.P256.PointMul

open Spec.Hash.Definitions
open Hacl.Hash.SHA2

module LSeq = Lib.Sequence
module BSeq = Lib.ByteSequence

module S = Spec.P256
module SM = Hacl.Spec.P256.Montgomery
module QI = Hacl.Impl.P256.Qinv
module BB = Hacl.Bignum.Base

#set-options "--z3rlimit 50 --ifuel 0 --fuel 0"

inline_for_extraction noextract
let lbytes len = lbuffer uint8 len

val msg_as_felem:
    alg:S.hash_alg_ecdsa
  -> msg_len:size_t{v msg_len >= S.min_input_length alg}
  -> msg:lbytes msg_len
  -> res:felem ->
  Stack unit
  (requires fun h ->
    live h msg /\ live h res /\ disjoint msg res)
  (ensures fun h0 _ h1 -> modifies (loc res) h0 h1 /\
    (let hashM = S.hash_ecdsa alg (v msg_len) (as_seq h0 msg) in
    as_nat h1 res = BSeq.nat_from_bytes_be (LSeq.sub hashM 0 32) % S.order))

[@CInline]
let msg_as_felem alg msg_len msg res =
  push_frame ();

  let sz: size_t =
    match alg with
    | S.NoHash -> 32ul
    | S.Hash a -> Hacl.Hash.Definitions.hash_len a in

  let mHash = create sz (u8 0) in

  begin
  match alg with
    | S.NoHash -> copy mHash (sub msg 0ul 32ul)
    | S.Hash a -> match a with
      | SHA2_256 -> hash_256 msg msg_len mHash
      | SHA2_384 -> hash_384 msg msg_len mHash
      | SHA2_512 -> hash_512 msg msg_len mHash
  end;

  let mHash32 = sub mHash 0ul 32ul in
  bn_from_bytes_be4 res mHash32;
  qmod_short res res;
  pop_frame ()


inline_for_extraction noextract
val ecdsa_sign_r (r k:felem) : Stack unit
  (requires fun h ->
    live h r /\ live h k /\ disjoint r k /\
    as_nat h k < S.order)
  (ensures fun h0 _ h1 -> modifies (loc r) h0 h1 /\
   (let x, _, _ = S.norm_jacob_point (S.point_mul_g (as_nat h0 k)) in
    as_nat h1 r == x % S.order))

let ecdsa_sign_r r k =
  push_frame ();
  let p = create_point () in
  point_mul_g p k; // p = [k]G
  norm_jacob_point_x p r;
  qmod_short r r;
  pop_frame ()


inline_for_extraction noextract
val ecdsa_sign_s (s k r d_a m:felem) : Stack unit
  (requires fun h ->
    live h s /\ live h m /\ live h d_a /\ live h k /\ live h r /\
    disjoint s r /\ disjoint s k /\ disjoint r k /\
    disjoint s d_a /\ disjoint r d_a /\ disjoint m s /\

    0 < as_nat h k /\ as_nat h k < S.order /\
    as_nat h r < S.order /\ as_nat h m < S.order /\
    0 < as_nat h d_a /\ as_nat h d_a < S.order)
  (ensures fun h0 _ h1 -> modifies (loc s |+| loc m) h0 h1 /\
   (let kinv = S.qinv (as_nat h0 k) in
    as_nat h1 s == S.qmul kinv (S.qadd (as_nat h0 m) (S.qmul (as_nat h0 r) (as_nat h0 d_a)))))

let ecdsa_sign_s s k r d_a m =
  push_frame ();
  let h0 = ST.get () in
  let kinv = create_felem () in
  QI.qinv kinv k;
  let h1 = ST.get () in
  assert (qmont_as_nat h1 kinv == S.qinv (qmont_as_nat h0 k));
  SM.lemma_mont_qinv (as_nat h0 k);
  assert (qmont_as_nat h1 kinv == S.qinv (as_nat h0 k) * SM.qmont_R % S.order);

  qmul s r d_a;  // s = r * d_a
  let h2 = ST.get () in
  assert (as_nat h2 s == (as_nat h0 r * as_nat h0 d_a * SM.qmont_R_inv) % S.order);
  from_qmont m m;
  let h3 = ST.get () in
  assert (as_nat h3 m == as_nat h2 m * SM.qmont_R_inv % S.order);
  qadd s m s;    // s = z + s
  let h4 = ST.get () in
  assert (as_nat h4 s == (as_nat h3 m + as_nat h2 s) % S.order);
  qmul s kinv s; // s = kinv * s
  let h5 = ST.get () in
  assert (as_nat h5 s == (as_nat h1 kinv * as_nat h4 s * SM.qmont_R_inv) % S.order);
  SM.lemma_ecdsa_sign_s
    (as_nat h0 k) (as_nat h1 kinv) (as_nat h0 r) (as_nat h0 d_a) (as_nat h0 m);
  pop_frame ()


// TODO: add check for nonce and private_key
inline_for_extraction noextract
val ecdsa_sign_load (d_a k_q:felem) (private_key nonce:lbytes 32ul) : Stack unit
  (requires fun h ->
    live h private_key /\ live h nonce /\ live h d_a /\ live h k_q /\
    disjoint d_a k_q /\ disjoint d_a private_key /\ disjoint d_a nonce /\
    disjoint k_q private_key /\ disjoint k_q nonce /\

    0 < BSeq.nat_from_bytes_be (as_seq h private_key) /\
    BSeq.nat_from_bytes_be (as_seq h private_key) < S.order /\
    0 < BSeq.nat_from_bytes_be (as_seq h nonce) /\
    BSeq.nat_from_bytes_be (as_seq h nonce) < S.order)
  (ensures fun h0 _ h1 -> modifies (loc d_a |+| loc k_q) h0 h1 /\
   (let d_a_nat = BSeq.nat_from_bytes_be (as_seq h0 private_key) in
    let k_nat = BSeq.nat_from_bytes_be (as_seq h0 nonce) in
    as_nat h1 d_a = d_a_nat /\ as_nat h1 k_q = k_nat))

let ecdsa_sign_load d_a k_q private_key nonce =
  bn_from_bytes_be4 d_a private_key;
  bn_from_bytes_be4 k_q nonce


inline_for_extraction noextract
val check_signature: r_q:felem -> s_q:felem -> Stack bool
  (requires fun h ->
    live h r_q /\ live h s_q /\ disjoint r_q s_q)
  (ensures fun h0 res h1 -> modifies0 h0 h1 /\
    res == ((0 < as_nat h0 r_q) && (0 < as_nat h0 s_q)))

let check_signature r_q s_q =
  let h0 = ST.get () in
  let is_r_zero = bn_is_zero_mask4 r_q in
  let is_s_zero = bn_is_zero_mask4 s_q in
  [@inline_let] let m0 = lognot is_r_zero in
  [@inline_let] let m1 = lognot is_s_zero in
  [@inline_let] let m2 = m0 &. m1 in
  lognot_lemma is_r_zero;
  lognot_lemma is_s_zero;
  logand_lemma m0 m1;
  BB.unsafe_bool_of_limb m2


inline_for_extraction noextract
val ecdsa_signature:
    alg:S.hash_alg_ecdsa
  -> signature:lbuffer uint8 64ul
  -> msg_len:size_t{v msg_len >= S.min_input_length alg}
  -> msg:lbuffer uint8 msg_len
  -> private_key:lbuffer uint8 32ul
  -> nonce:lbuffer uint8 32ul ->
  Stack bool
  (requires fun h ->
    live h signature /\ live h msg /\ live h private_key /\ live h nonce /\
    disjoint signature msg /\ disjoint signature private_key /\ disjoint signature nonce /\

    0 < BSeq.nat_from_bytes_be (as_seq h private_key) /\
    BSeq.nat_from_bytes_be (as_seq h private_key) < S.order /\
    0 < BSeq.nat_from_bytes_be (as_seq h nonce) /\
    BSeq.nat_from_bytes_be (as_seq h nonce) < S.order)
  (ensures fun h0 flag h1 -> modifies (loc signature) h0 h1 /\
    (let sgnt = S.ecdsa_signature_agile alg (v msg_len)
      (as_seq h0 msg) (as_seq h0 private_key) (as_seq h0 nonce) in
     (flag <==> Some? sgnt) /\ (flag ==> (as_seq h1 signature == Some?.v sgnt))))

let ecdsa_signature alg signature msg_len msg private_key nonce =
  push_frame ();
  let rsdk_q = create 20ul (u64 0) in
  let r_q = sub rsdk_q 0ul 4ul in
  let s_q = sub rsdk_q 4ul 4ul in
  let d_a = sub rsdk_q 8ul 4ul in
  let k_q = sub rsdk_q 12ul 4ul in
  let m_q = sub rsdk_q 16ul 4ul in
  ecdsa_sign_load d_a k_q private_key nonce;
  msg_as_felem alg msg_len msg m_q;
  ecdsa_sign_r r_q k_q;
  ecdsa_sign_s s_q k_q r_q d_a m_q;
  bn2_to_bytes_be4 signature r_q s_q;
  let res = check_signature r_q s_q in
  pop_frame ();
  res
