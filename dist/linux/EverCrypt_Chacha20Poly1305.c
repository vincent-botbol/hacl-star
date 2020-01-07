/* MIT License
 *
 * Copyright (c) 2016-2020 INRIA, CMU and Microsoft Corporation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */


#include "EverCrypt_Chacha20Poly1305.h"

void
EverCrypt_Chacha20Poly1305_aead_encrypt(
  u8 *k,
  u8 *n1,
  u32 aadlen,
  u8 *aad,
  u32 mlen,
  u8 *m,
  u8 *cipher,
  u8 *tag
)
{
  bool avx2 = EverCrypt_AutoConfig2_has_avx2();
  bool avx = EverCrypt_AutoConfig2_has_avx();
  #if EVERCRYPT_TARGETCONFIG_X64
  if (avx2)
  {
    Hacl_Chacha20Poly1305_256_aead_encrypt(k, n1, aadlen, aad, mlen, m, cipher, tag);
    return;
  }
  #endif
  #if EVERCRYPT_TARGETCONFIG_X64
  if (avx)
  {
    Hacl_Chacha20Poly1305_128_aead_encrypt(k, n1, aadlen, aad, mlen, m, cipher, tag);
    return;
  }
  #endif
  Hacl_Chacha20Poly1305_32_aead_encrypt(k, n1, aadlen, aad, mlen, m, cipher, tag);
}

u32
EverCrypt_Chacha20Poly1305_aead_decrypt(
  u8 *k,
  u8 *n1,
  u32 aadlen,
  u8 *aad,
  u32 mlen,
  u8 *m,
  u8 *cipher,
  u8 *tag
)
{
  bool avx2 = EverCrypt_AutoConfig2_has_avx2();
  bool avx = EverCrypt_AutoConfig2_has_avx();
  #if EVERCRYPT_TARGETCONFIG_X64
  if (avx2)
  {
    return Hacl_Chacha20Poly1305_256_aead_decrypt(k, n1, aadlen, aad, mlen, m, cipher, tag);
  }
  #endif
  #if EVERCRYPT_TARGETCONFIG_X64
  if (avx)
  {
    return Hacl_Chacha20Poly1305_128_aead_decrypt(k, n1, aadlen, aad, mlen, m, cipher, tag);
  }
  #endif
  return Hacl_Chacha20Poly1305_32_aead_decrypt(k, n1, aadlen, aad, mlen, m, cipher, tag);
}

