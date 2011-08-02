#include "spr_defs.h"

#define DATA_START 0x200
#define DATA_END   0x300
#define DATA_LOC   0x400

.section	.vectors, "ax"	

  /* reset */
.org 0x100
_reset:
  l.nop
  l.nop
  l.nop
  l.nop

	/* go into supervisor mode */
	l.addi	r3,r0,SPR_SR_SM
	l.mtspr r0,r3,SPR_SR

  /* copy some data around */

	l.movhi r2, hi(DATA_START)
	l.ori   r2,r2,lo(DATA_START)
	l.movhi r3, hi(DATA_END)
	l.ori   r3,r3,lo(DATA_END)
	l.movhi r4, hi(DATA_LOC)
	l.ori   r4,r4,lo(DATA_LOC)
data_copy_start:
	l.sfgeu r2,r3
	l.bf    data_copy_end
	l.nop
	l.lwz	r5,0(r4)
	l.sw	0(r2),r5
	l.addi	r2,r2,4
	l.addi  r4,r4,4
	l.bnf	data_copy_start
  l.nop
data_copy_end:

  /* signal end to bench */
  l.movhi r2,hi(0x0)
  l.ori   r2,r2,lo(0x0)
  l.movhi r3,hi(0xdeadbeef)
  l.ori   r3,r3,lo(0xdeadbeef)
  l.sw 0(r2),r3
end:
  l.j end
  l.nop

