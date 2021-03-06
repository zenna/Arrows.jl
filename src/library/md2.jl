struct MD2SBoxArrow <: PrimArrow end
struct InverseMD2SBoxArrow <: PrimArrow end

name(::MD2SBoxArrow)::Symbol = :md2box
function props(::MD2SBoxArrow)
  [Props(true, :x, Any),
   Props(false, :y, Any)]
 end

abinterprets(::MD2SBoxArrow) = [sizeprop]
interpret(::MD2SBoxArrow, idx) = (md2box(idx),)

name(::InverseMD2SBoxArrow)::Symbol = :inverse_md2box
function props(::InverseMD2SBoxArrow)
  [Props(true, :x, Any),
   Props(false, :y, Any)]
 end

abinterprets(::InverseMD2SBoxArrow) = [sizeprop]

function inv(arr::MD2SBoxArrow, sarr::SubArrow, abvals::IdAbValues)
  unary_inv(arr, const_in(arr, abvals), InverseMD2SBoxArrow)
end

function inv(arr::InverseMD2SBoxArrow, sarr::SubArrow, abvals::IdAbValues)
  unary_inv(arr, const_in(arr, abvals), MD2SBoxArrow)
end




function md2box(idx::Arrows.AbstractPort)
  res = Arrows.compose!(vcat(idx), MD2SBoxArrow())[1]
end


function inverse_md2box(idx::Arrows.AbstractPort)
  res = Arrows.compose!(vcat(idx), InverseMD2SBoxArrow())[1]
end

function md2box(idx)
  _SBOX = [  # A permutation of the 256 byte values, from 0x00 to 0xFF
  0x29, 0x2E, 0x43, 0xC9, 0xA2, 0xD8, 0x7C, 0x01, 0x3D, 0x36, 0x54, 0xA1, 0xEC, 0xF0, 0x06, 0x13,
  0x62, 0xA7, 0x05, 0xF3, 0xC0, 0xC7, 0x73, 0x8C, 0x98, 0x93, 0x2B, 0xD9, 0xBC, 0x4C, 0x82, 0xCA,
  0x1E, 0x9B, 0x57, 0x3C, 0xFD, 0xD4, 0xE0, 0x16, 0x67, 0x42, 0x6F, 0x18, 0x8A, 0x17, 0xE5, 0x12,
  0xBE, 0x4E, 0xC4, 0xD6, 0xDA, 0x9E, 0xDE, 0x49, 0xA0, 0xFB, 0xF5, 0x8E, 0xBB, 0x2F, 0xEE, 0x7A,
  0xA9, 0x68, 0x79, 0x91, 0x15, 0xB2, 0x07, 0x3F, 0x94, 0xC2, 0x10, 0x89, 0x0B, 0x22, 0x5F, 0x21,
  0x80, 0x7F, 0x5D, 0x9A, 0x5A, 0x90, 0x32, 0x27, 0x35, 0x3E, 0xCC, 0xE7, 0xBF, 0xF7, 0x97, 0x03,
  0xFF, 0x19, 0x30, 0xB3, 0x48, 0xA5, 0xB5, 0xD1, 0xD7, 0x5E, 0x92, 0x2A, 0xAC, 0x56, 0xAA, 0xC6,
  0x4F, 0xB8, 0x38, 0xD2, 0x96, 0xA4, 0x7D, 0xB6, 0x76, 0xFC, 0x6B, 0xE2, 0x9C, 0x74, 0x04, 0xF1,
  0x45, 0x9D, 0x70, 0x59, 0x64, 0x71, 0x87, 0x20, 0x86, 0x5B, 0xCF, 0x65, 0xE6, 0x2D, 0xA8, 0x02,
  0x1B, 0x60, 0x25, 0xAD, 0xAE, 0xB0, 0xB9, 0xF6, 0x1C, 0x46, 0x61, 0x69, 0x34, 0x40, 0x7E, 0x0F,
  0x55, 0x47, 0xA3, 0x23, 0xDD, 0x51, 0xAF, 0x3A, 0xC3, 0x5C, 0xF9, 0xCE, 0xBA, 0xC5, 0xEA, 0x26,
  0x2C, 0x53, 0x0D, 0x6E, 0x85, 0x28, 0x84, 0x09, 0xD3, 0xDF, 0xCD, 0xF4, 0x41, 0x81, 0x4D, 0x52,
  0x6A, 0xDC, 0x37, 0xC8, 0x6C, 0xC1, 0xAB, 0xFA, 0x24, 0xE1, 0x7B, 0x08, 0x0C, 0xBD, 0xB1, 0x4A,
  0x78, 0x88, 0x95, 0x8B, 0xE3, 0x63, 0xE8, 0x6D, 0xE9, 0xCB, 0xD5, 0xFE, 0x3B, 0x00, 0x1D, 0x39,
  0xF2, 0xEF, 0xB7, 0x0E, 0x66, 0x58, 0xD0, 0xE4, 0xA6, 0x77, 0x72, 0xF8, 0xEB, 0x75, 0x4B, 0x0A,
  0x31, 0x44, 0x50, 0xB4, 0x8F, 0xED, 0x1F, 0x1A, 0xDB, 0x99, 0x8D, 0x33, 0x9F, 0x11, 0x83, 0x14,
  ];
  _SBOX[idx + 1]
end

function inverse_md2box(idx)
  _SBOX = [  # A permutation of the 256 byte values, from 0x00 to 0xFF
  0xdd, 0x07, 0x8f, 0x5f, 0x7e, 0x12, 0x0e, 0x46, 0xcb, 0xb7, 0xef, 0x4c, 0xcc, 0xb2, 0xe3, 0x9f,
  0x4a, 0xfd, 0x2f, 0x0f, 0xff, 0x44, 0x27, 0x2d, 0x2b, 0x61, 0xf7, 0x90, 0x98, 0xde, 0x20, 0xf6,
  0x87, 0x4f, 0x4d, 0xa3, 0xc8, 0x92, 0xaf, 0x57, 0xb5, 0x00, 0x6b, 0x1a, 0xb0, 0x8d, 0x01, 0x3d,
  0x62, 0xf0, 0x56, 0xfb, 0x9c, 0x58, 0x09, 0xc2, 0x72, 0xdf, 0xa7, 0xdc, 0x23, 0x08, 0x59, 0x47,
  0x9d, 0xbc, 0x29, 0x02, 0xf1, 0x80, 0x99, 0xa1, 0x64, 0x37, 0xcf, 0xee, 0x1d, 0xbe, 0x31, 0x70,
  0xf2, 0xa5, 0xbf, 0xb1, 0x0a, 0xa0, 0x6d, 0x22, 0xe5, 0x83, 0x54, 0x89, 0xa9, 0x52, 0x69, 0x4e,
  0x91, 0x9a, 0x10, 0xd5, 0x84, 0x8b, 0xe4, 0x28, 0x41, 0x9b, 0xc0, 0x7a, 0xc4, 0xd7, 0xb3, 0x2a,
  0x82, 0x85, 0xea, 0x16, 0x7d, 0xed, 0x78, 0xe9, 0xd0, 0x42, 0x3f, 0xca, 0x06, 0x76, 0x9e, 0x51,
  0x50, 0xbd, 0x1e, 0xfe, 0xb6, 0xb4, 0x88, 0x86, 0xd1, 0x4b, 0x2c, 0xd3, 0x17, 0xfa, 0x3b, 0xf4,
  0x55, 0x43, 0x6a, 0x19, 0x48, 0xd2, 0x74, 0x5e, 0x18, 0xf9, 0x53, 0x21, 0x7c, 0x81, 0x35, 0xfc,
  0x38, 0x0b, 0x04, 0xa2, 0x75, 0x65, 0xe8, 0x11, 0x8e, 0x40, 0x6e, 0xc6, 0x6c, 0x93, 0x94, 0xa6,
  0x95, 0xce, 0x45, 0x63, 0xf3, 0x66, 0x77, 0xe2, 0x71, 0x96, 0xac, 0x3c, 0x1c, 0xcd, 0x30, 0x5c,
  0x14, 0xc5, 0x49, 0xa8, 0x32, 0xad, 0x6f, 0x15, 0xc3, 0x03, 0x1f, 0xd9, 0x5a, 0xba, 0xab, 0x8a,
  0xe6, 0x67, 0x73, 0xb8, 0x25, 0xda, 0x33, 0x68, 0x05, 0x1b, 0x34, 0xf8, 0xc1, 0xa4, 0x36, 0xb9,
  0x26, 0xc9, 0x7b, 0xd4, 0xe7, 0x2e, 0x8c, 0x5b, 0xd6, 0xd8, 0xae, 0xec, 0x0c, 0xf5, 0x3e, 0xe1,
  0x0d, 0x7f, 0xe0, 0x13, 0xbb, 0x3a, 0x97, 0x5d, 0xeb, 0xaa, 0xc7, 0x39, 0x79, 0x24, 0xdb, 0x60
  ];
  _SBOX[idx + 1]
end
