// jshint esversion: 8

// We demonstrate how to write a sample program that uses the high-level HACL*
// API. Run this with `node test2.js`. See `test.html` for a version to be run
// directly from within the browser.

var HaclWasm = require('./api.js');
var loader = require('./loader.js');

// Test helpers
// ------------

const buf2hex = buffer => [...new Uint8Array(buffer)].map(x => `00${x.toString(16)}`.slice(-2)).join('');

function hex2buf(hexString) {
  if (hexString === "")
    return new Uint8Array(0);
  else
    return new Uint8Array(hexString.match(/.{2}/g).map(byte => parseInt(byte, 16)));
}

function assert(b, msg) {
  if (!b)
    throw new Error(msg);
}

// Functional test
// ---------------

const SHA2_256 = 1;

function testEverCryptHash(Hacl) {
  let s = Hacl.EverCrypt_Hash.create(SHA2_256);
  console.log(s);
}

// Initialization
// --------------

// Note: this is an optimization. We demonstrate how to selectively load only a
// subset of the WASM files so as to provide only the functionality one is
// interested in. If packaging the entire set of WASM files is not a problem,
// leave `modules` undefined.
let modules = [
  "WasmSupport",
  "FStar",
  "Hacl_Hash_MD5",
  "Hacl_Hash_SHA1",
  "Hacl_Hash_SHA2",
  "Hacl_Impl_Blake2_Constants",
  "Hacl_Hash_Blake2",
  "Hacl_Hash_Blake2s_128",
  "Hacl_Hash_Blake2b_256",
  "Hacl_SHA3",
  "Vale",
  "EverCrypt",
  "EverCrypt_Hash",
];

// Main test driver
HaclWasm.getInitializedHaclModule(modules).then(function(Hacl) {
  testEverCryptHash(Hacl);
});
