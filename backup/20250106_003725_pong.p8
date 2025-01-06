pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
#include pong.lua
__gfx__
00000000007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000070000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700700070070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000700007070000000000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700070000007000800000b0b00b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700700000070080800000b00b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000007000070000000000b0b0bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006660000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000060000000000000000000000050000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000666000000000000000000000555000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000060000000000000000000000050000000000000000000000000000000000000005000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055500000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006660000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000ddd0000000000000000000000000000000000050aa000000000000000000000000000000000000000000000000
000000000000000000000000000000ccc00000d0d00000000000000000000000000000bbb00555a0a00000000000000000000000000000000000000000000000
000000000000000000000000000000c0c00060ddd00000000000000000000000000000b0b00050a0a00000000000000000000000000000000000000000000000
000000000000000000000000000000ccc00666d0d000000dd000000000000000000000bbb00000a0a00000aa0000000000000000000000000000000000000000
00000000000000000000000bb00000c0000060d0d00000d000000000000000ccc00000b0b00000aaa00000a0a0000000000000bbb00000000000000000000000
0000000000000000000005b0000000c000055500000000d0000000ddd00000c0c00000b0b0000000000000a0a00000a0000000b0000000000000000000000000
0000000000000000000055bbb000000000005000000000d0000000d0000000ccc000000000000000000000a0a00000a0000000bb000000000000000000000000
000000000000000000000500b0000000000000000000000dd00000dd000000c00000000000000000000000aaa00000a0000000b0000000000000000000000000
0000000000000000000000bb000000000000000000000000000000d0000000c0000000000000000000000000000000a0000000bbb00000000000000000000000
000000000000000000000000000000000000000000000000000000ddd0000000000000000000000000000000000000aaa0000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000005550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000006606600660006606060066000006660066000006660066060606660000000000000000000000000000000000000
00000000000000000000000000000000000060606060606060606060600000000600606000006660606060606600000000000000000000000000000000000000
00000000000000000000000000000000000066606600660060606660006000000600606000006060606066606000000000000000000000000000000000000000
00000000000000000000000000000000000060606060606066006660660000000600660000006060660006000660000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000000
00000000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000555000000000000000
00000000000000000000000000000000000000000000000060000000000000600005550000000000000000000000000000000000000000050050000000000000
00000000000000000000000000000000000000000000000666000000000006660000500000005000000000000000000000000000000000000555000000000000
00000000000000000000000000000000000000000000000060000000000000600000000000055500000000000000000000000000000000000050000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000
00000000000000000000000000000000066066006660066006600000606000006660066000000660666006606600666000000000000000000000000000000000
00000000000000000000000000000000606060606600600060000000060000000600606000006000060060606060060000000000000000000000000000000000
00000000000000000000000000000000666066006000006000600000060000000600606000000060060066606600060000000000000000000000000000000000
00000000000000000000000000000000600060600660660066000000606000060600660000006600060060606060060000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000666000000000000000000000000000000000000000000000000000060000000000
00000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000050000000000000666000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555000000000000060000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000666000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000555000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000005550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000070700770700070007770707000000770777070707760777007700770000000000000000000000000000000000000
00000000000000000000000000000000000070707070700070007700777000007000070070707676070070707000000000000000000000000000000000000000
00000000000000000000000000000000000077707770700070007000007000000070070070707070070070700070000000000000000000000000000000000000
00000000000000000000000000000000000007007070077007700770770000007700070007707700777077007766000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000055500000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000066600000666000000000000000000000000000000000000000000000000000000000
00000000000000500000000000000000000000000000000000000000606060600000006000000000000000000000000000000000000000000000000000000000
00000000000005550000000000000000000000000000000000000000606060600000666000000000000000000000000000000000000000000000000000000000
00000000000000500000000000000000000000000000000000000000666060600000600000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000050000060066600600666000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000555000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000
60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005550000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000005550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
010100002f0302b03025030000001d0300000016030000000f0300a03006030030300003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000a0300c0300f0301303017030000001a0301d0302003022030250302c0302a0002c0002e0002f00000000000000000000000000000000000000000000000000000000000000000000000000000000000
010900003212031120201201e1201a120141200e12009120001200012000120000001d100181001610015100151000000012100000000d1000000009100000000410000100000000000000000000000000000000
610800000d030000000f0301a00011030000001403000000190300000019020000001901000000190100000019010000001900000000000000000000000000000000000000000000000000000000000000000000
910600000003000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4d1300200fb500db000000000000346150000003000030320fb50000000000000000346150000000000000000fb50000000000000000346150000003050346150fb5000000000000000034615000000000000000
010a00001954200000185420000017542000001654200000155420000015532000001552200000155120000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0220e022100221302215022180221a0221c0221f0222102226022280222f0222f0122f01200000
__music__
00 41424344
03 05424344
00 06074344
00 41424344
00 41424344
03 05424344
