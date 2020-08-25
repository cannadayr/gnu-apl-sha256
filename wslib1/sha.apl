#!/usr/local/bin/apl --script --

trav ← {⊃(⍶ {⍺(⍶ trav ⍹)⍵} ⍹)⍨/⌽(⊂⍺ ⍶ ⍵),⍺ ⍹ ⍵} ⍝ dfs
nest ← {(⊂⍵)⊣⍣(⍺≠≡⍵)⊢⍵} ⍝ nests to depth ⍺

shr ← {(⍺⍴0),(⍺-⍨≢⍵)↑⍵}                         ⍝ shift right
rotr ← {⌽⍺⌽⌽⍵}                                  ⍝ rotate
add ← { ⍺ {2⊥⊃⍵} {(32⍴2)⊤(2*32)|(⍶ ⍺)+⍶ ⍵} ⍵}   ⍝ modular arithmetic

⍝ base cryptographic fns
s0 ← {(3 shr ⍵)≠(18 rotr ⍵)≠7 rotr ⍵}
s1 ← {(10 shr ⍵)≠(19 rotr ⍵)≠17 rotr ⍵}
S0 ← {(22 rotr ⍵)≠(13 rotr ⍵)≠2 rotr ⍵}
S1 ← {(25 rotr ⍵)≠(11 rotr ⍵)≠6 rotr ⍵}
ch ← {(⍵[2;]∧⍵[1;])≠⍵[3;]∧~⍵[1;]}
maj ← {(⍵[3;]∧⍵[2;])≠(⍵[3;]∧⍵[1;])≠⍵[2;]∧⍵[1;]}

⍝ UCS conversion
conv ← {,({⍵⊤⍨8/2}⍤0)⎕UCS ⍵}

⍝ initial padding
pad1 ← {((64/2)⊤≢∈⍵),⍨ {⍵,0⍴⍨|¯512|(≢⍵)+64} {1,⍨⍵} ⍵ } ⍝ add 1; pad to next (512-64) size, append 64 bit size
pad2 ← {⍵⊂⍨512/⍳512÷⍨≢⍵} ⍝ section into blocks
pad ← { pad2 pad1 ⍵ }

⍝ naive primes generator.
primes ← {{⍵/⍨~⍵∈∘.×⍨⍵}{1↓⍳⍵} ⍵}

⍝ constant value generator
cvg ← {({(¯1↓⍵),⌊¯1↑⍵}⍤1)⍉(32⍴2)⊤(2*32)×1|(÷⍺)*⍨primes ⍵}

⍝ initial constants
⍝ see nums.apl for constants pre-computed using ⊃10 ⎕CR 'h'
h ← {2 cvg 19} ⍝ hash values
k ← {3 cvg 311} ⍝ round constants

⍝ msg schedule
msg_sched1 ← { (s1 (⍺-2) ⊃⍵) add ((⍺-7)⊃⍵) add (s0 (⍺-15)⊃⍵) add (⍺-16)⊃⍵ }
msg_sched2 ← {((-64-⍺)↑⍵),⍨(⊂ ⍺ msg_sched1 ⍵),⍨(¯1+⍺)↑⍵}
msg_sched  ← { ⍵ {(1↑1 nest ⍵) msg_sched2 ⍺} trav {⍺⊢1↓1 nest ⍵} 16↓⍳64 }

⍝ compression
T1 ← {(⊃⍵[χ]) add k[χ;] add (ch ⍺[5 6 7;]) add (S1 ⍺[5;]) add ⍺[8;]}
T2 ← {(maj ⍵[1 2 3;]) add S0 ⍵[1;]}
T3 ← {(T2 ⍺) add ⍺ T1[χ] ⍵}
T4 ← {⍺[4;] add ⍺ T1[χ] ⍵}

compress_pad ← {{⍵,48⍴⊂32⍴0} (32/⍳16)⊂⍵}
compress1 ← {⊖(⍺ T3[χ] ⍵)⍪⍺[1 2 3;]⍪(⍺ T4[χ] ⍵)⍪⍺[5 6 7;]} ⍝ next hash value
dbg1 ← {⍵⊣⎕DL 0.1⊣⎕←4 ⎕CR " █"[1+1⊃⍵]}
⍝compress2 ← {⍺ (add⍤1) 1⊃⍺ { ((⊂⍺),⊂⍵) {dbg1(⊂⊖(1⊃⍺) compress1[⍬⍴1↑1 nest ⍵] 2⊃⍺),⊂2⊃⍺} trav {⍺⊢1↓1 nest ⍵} ⍳64} ⍵} ⍝ compress the block
compress2 ← {⍺ (add⍤1) 1⊃⍺ { ((⊂⍺),⊂⍵) {(⊂⊖(1⊃⍺) compress1[⍬⍴1↑1 nest ⍵] 2⊃⍺),⊂2⊃⍺} trav {⍺⊢1↓1 nest ⍵} ⍳64} ⍵} ⍝ compress the block
dbg2 ← {⍵⊣⎕←4 ⎕CR " █"[1+⍵]}
⍝compress  ← { h {dbg2 ⍺ compress2 msg_sched compress_pad ,⊃1↑2 nest ⍵} trav {⍺⊢1↓2 nest ⍵} ⍵ } ⍝ compress every block
compress  ← { h {⍺ compress2 msg_sched compress_pad ,⊃1↑2 nest ⍵} trav {⍺⊢1↓2 nest ⍵} ⍵ } ⍝ compress every block

hex_bin ← { 6 ⎕CR ,({({+/128 64 32 16 8 4 2 1×⊃⍵}⍤0)(8/⍳4)⊂⍵}⍤2) ⍵}
hash    ← { hex_bin compress pad conv ⍵ }

⍝ hashing a binary file
⍝ maybe endian-ness is different?
⍝ z← ⎕FIO[26] '/tmp/wtvr'
⍝ hash z

