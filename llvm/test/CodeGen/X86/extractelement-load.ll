; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i686-unknown -mattr=+sse2 | FileCheck %s --check-prefix=X86-SSE2
; RUN: llc < %s -mtriple=x86_64-unknown -mattr=+ssse3 | FileCheck %s --check-prefixes=X64,X64-SSSE3
; RUN: llc < %s -mtriple=x86_64-unknown -mattr=+avx  | FileCheck %s --check-prefixes=X64,X64-AVX,X64-AVX1
; RUN: llc < %s -mtriple=x86_64-unknown -mattr=+avx2 | FileCheck %s --check-prefixes=X64,X64-AVX,X64-AVX2

target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

define i32 @t(ptr %val) nounwind  {
; X86-SSE2-LABEL: t:
; X86-SSE2:       # %bb.0:
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-SSE2-NEXT:    movl 8(%eax), %eax
; X86-SSE2-NEXT:    retl
;
; X64-LABEL: t:
; X64:       # %bb.0:
; X64-NEXT:    movl 8(%rdi), %eax
; X64-NEXT:    retq
  %tmp2 = load <2 x i64>, ptr %val, align 16		; <<2 x i64>> [#uses=1]
  %tmp3 = bitcast <2 x i64> %tmp2 to <4 x i32>		; <<4 x i32>> [#uses=1]
  %tmp4 = extractelement <4 x i32> %tmp3, i32 2		; <i32> [#uses=1]
  ret i32 %tmp4
}

; Case where extractelement of load ends up as undef.
; (Making sure this doesn't crash.)
define i32 @t2(ptr %xp) {
; X86-SSE2-LABEL: t2:
; X86-SSE2:       # %bb.0:
; X86-SSE2-NEXT:    retl
;
; X64-LABEL: t2:
; X64:       # %bb.0:
; X64-NEXT:    retq
  %x = load <8 x i32>, ptr %xp
  %Shuff68 = shufflevector <8 x i32> %x, <8 x i32> undef, <8 x i32> <i32 undef, i32 7, i32 9, i32 undef, i32 13, i32 15, i32 1, i32 3>
  %y = extractelement <8 x i32> %Shuff68, i32 0
  ret i32 %y
}

; This case could easily end up inf-looping in the DAG combiner due to an
; low alignment load of the vector which prevents us from reliably forming a
; narrow load.

define void @t3(ptr %a0) {
; X86-SSE2-LABEL: t3:
; X86-SSE2:       # %bb.0: # %bb
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-SSE2-NEXT:    movups (%eax), %xmm0
; X86-SSE2-NEXT:    movhps %xmm0, (%eax)
; X86-SSE2-NEXT:    retl
;
; X64-SSSE3-LABEL: t3:
; X64-SSSE3:       # %bb.0: # %bb
; X64-SSSE3-NEXT:    movsd {{.*#+}} xmm0 = mem[0],zero
; X64-SSSE3-NEXT:    movsd %xmm0, (%rax)
; X64-SSSE3-NEXT:    retq
;
; X64-AVX-LABEL: t3:
; X64-AVX:       # %bb.0: # %bb
; X64-AVX-NEXT:    vmovsd {{.*#+}} xmm0 = mem[0],zero
; X64-AVX-NEXT:    vmovsd %xmm0, (%rax)
; X64-AVX-NEXT:    retq
bb:
  %tmp13 = load <2 x double>, ptr %a0, align 1
  %.sroa.3.24.vec.extract = extractelement <2 x double> %tmp13, i32 1
  store double %.sroa.3.24.vec.extract, ptr undef, align 8
  ret void
}

; Case where a load is unary shuffled, then bitcast (to a type with the same
; number of elements) before extractelement.
; This is testing for an assertion - the extraction was assuming that the undef
; second shuffle operand was a post-bitcast type instead of a pre-bitcast type.
define i64 @t4(ptr %a) {
; X86-SSE2-LABEL: t4:
; X86-SSE2:       # %bb.0:
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-SSE2-NEXT:    movl (%ecx), %eax
; X86-SSE2-NEXT:    movl 4(%ecx), %edx
; X86-SSE2-NEXT:    retl
;
; X64-LABEL: t4:
; X64:       # %bb.0:
; X64-NEXT:    movq (%rdi), %rax
; X64-NEXT:    retq
  %b = load <2 x double>, ptr %a, align 16
  %c = shufflevector <2 x double> %b, <2 x double> %b, <2 x i32> <i32 1, i32 0>
  %d = bitcast <2 x double> %c to <2 x i64>
  %e = extractelement <2 x i64> %d, i32 1
  ret i64 %e
}

; Don't extract from a volatile.
define void @t5(ptr%a0, ptr%a1) {
; X86-SSE2-LABEL: t5:
; X86-SSE2:       # %bb.0:
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-SSE2-NEXT:    movaps (%ecx), %xmm0
; X86-SSE2-NEXT:    movhps %xmm0, (%eax)
; X86-SSE2-NEXT:    retl
;
; X64-SSSE3-LABEL: t5:
; X64-SSSE3:       # %bb.0:
; X64-SSSE3-NEXT:    movaps (%rdi), %xmm0
; X64-SSSE3-NEXT:    movhps %xmm0, (%rsi)
; X64-SSSE3-NEXT:    retq
;
; X64-AVX-LABEL: t5:
; X64-AVX:       # %bb.0:
; X64-AVX-NEXT:    vmovaps (%rdi), %xmm0
; X64-AVX-NEXT:    vmovhps %xmm0, (%rsi)
; X64-AVX-NEXT:    retq
  %vecload = load volatile <2 x double>, ptr %a0, align 16
  %vecext = extractelement <2 x double> %vecload, i32 1
  store volatile double %vecext, ptr %a1, align 8
  ret void
}

; Check for multiuse.
define float @t6(ptr%a0) {
; X86-SSE2-LABEL: t6:
; X86-SSE2:       # %bb.0:
; X86-SSE2-NEXT:    pushl %eax
; X86-SSE2-NEXT:    .cfi_def_cfa_offset 8
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-SSE2-NEXT:    movaps (%eax), %xmm0
; X86-SSE2-NEXT:    shufps {{.*#+}} xmm0 = xmm0[1,1,1,1]
; X86-SSE2-NEXT:    xorps %xmm1, %xmm1
; X86-SSE2-NEXT:    cmpeqss %xmm0, %xmm1
; X86-SSE2-NEXT:    movss {{.*#+}} xmm2 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
; X86-SSE2-NEXT:    andps %xmm1, %xmm2
; X86-SSE2-NEXT:    andnps %xmm0, %xmm1
; X86-SSE2-NEXT:    orps %xmm2, %xmm1
; X86-SSE2-NEXT:    movss %xmm1, (%esp)
; X86-SSE2-NEXT:    flds (%esp)
; X86-SSE2-NEXT:    popl %eax
; X86-SSE2-NEXT:    .cfi_def_cfa_offset 4
; X86-SSE2-NEXT:    retl
;
; X64-SSSE3-LABEL: t6:
; X64-SSSE3:       # %bb.0:
; X64-SSSE3-NEXT:    movshdup {{.*#+}} xmm1 = mem[1,1,3,3]
; X64-SSSE3-NEXT:    xorps %xmm0, %xmm0
; X64-SSSE3-NEXT:    cmpeqss %xmm1, %xmm0
; X64-SSSE3-NEXT:    movss {{.*#+}} xmm2 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
; X64-SSSE3-NEXT:    andps %xmm0, %xmm2
; X64-SSSE3-NEXT:    andnps %xmm1, %xmm0
; X64-SSSE3-NEXT:    orps %xmm2, %xmm0
; X64-SSSE3-NEXT:    retq
;
; X64-AVX1-LABEL: t6:
; X64-AVX1:       # %bb.0:
; X64-AVX1-NEXT:    vmovss {{.*#+}} xmm0 = mem[0],zero,zero,zero
; X64-AVX1-NEXT:    vxorps %xmm1, %xmm1, %xmm1
; X64-AVX1-NEXT:    vcmpeqss %xmm1, %xmm0, %xmm1
; X64-AVX1-NEXT:    vblendvps %xmm1, {{\.?LCPI[0-9]+_[0-9]+}}(%rip), %xmm0, %xmm0
; X64-AVX1-NEXT:    retq
;
; X64-AVX2-LABEL: t6:
; X64-AVX2:       # %bb.0:
; X64-AVX2-NEXT:    vmovss {{.*#+}} xmm0 = mem[0],zero,zero,zero
; X64-AVX2-NEXT:    vxorps %xmm1, %xmm1, %xmm1
; X64-AVX2-NEXT:    vcmpeqss %xmm1, %xmm0, %xmm1
; X64-AVX2-NEXT:    vbroadcastss {{.*#+}} xmm2 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0]
; X64-AVX2-NEXT:    vblendvps %xmm1, %xmm2, %xmm0, %xmm0
; X64-AVX2-NEXT:    retq
  %vecload = load <8 x float>, ptr %a0, align 32
  %vecext = extractelement <8 x float> %vecload, i32 1
  %cmp = fcmp oeq float %vecext, 0.000000e+00
  %cond = select i1 %cmp, float 1.000000e+00, float %vecext
  ret float %cond
}

define void @PR43971(ptr%a0, ptr%a1) {
; X86-SSE2-LABEL: PR43971:
; X86-SSE2:       # %bb.0: # %entry
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-SSE2-NEXT:    movaps 16(%ecx), %xmm0
; X86-SSE2-NEXT:    movhlps {{.*#+}} xmm0 = xmm0[1,1]
; X86-SSE2-NEXT:    xorps %xmm1, %xmm1
; X86-SSE2-NEXT:    cmpltss %xmm0, %xmm1
; X86-SSE2-NEXT:    movss {{.*#+}} xmm2 = mem[0],zero,zero,zero
; X86-SSE2-NEXT:    andps %xmm1, %xmm2
; X86-SSE2-NEXT:    andnps %xmm0, %xmm1
; X86-SSE2-NEXT:    orps %xmm2, %xmm1
; X86-SSE2-NEXT:    movss %xmm1, (%eax)
; X86-SSE2-NEXT:    retl
;
; X64-SSSE3-LABEL: PR43971:
; X64-SSSE3:       # %bb.0: # %entry
; X64-SSSE3-NEXT:    movss {{.*#+}} xmm0 = mem[0],zero,zero,zero
; X64-SSSE3-NEXT:    xorps %xmm1, %xmm1
; X64-SSSE3-NEXT:    cmpltss %xmm0, %xmm1
; X64-SSSE3-NEXT:    movss {{.*#+}} xmm2 = mem[0],zero,zero,zero
; X64-SSSE3-NEXT:    andps %xmm1, %xmm2
; X64-SSSE3-NEXT:    andnps %xmm0, %xmm1
; X64-SSSE3-NEXT:    orps %xmm2, %xmm1
; X64-SSSE3-NEXT:    movss %xmm1, (%rsi)
; X64-SSSE3-NEXT:    retq
;
; X64-AVX-LABEL: PR43971:
; X64-AVX:       # %bb.0: # %entry
; X64-AVX-NEXT:    vmovss {{.*#+}} xmm0 = mem[0],zero,zero,zero
; X64-AVX-NEXT:    vxorps %xmm1, %xmm1, %xmm1
; X64-AVX-NEXT:    vcmpltss %xmm0, %xmm1, %xmm1
; X64-AVX-NEXT:    vmovss {{.*#+}} xmm2 = mem[0],zero,zero,zero
; X64-AVX-NEXT:    vblendvps %xmm1, %xmm2, %xmm0, %xmm0
; X64-AVX-NEXT:    vmovss %xmm0, (%rsi)
; X64-AVX-NEXT:    retq
entry:
  %0 = load <8 x float>, ptr %a0, align 32
  %vecext = extractelement <8 x float> %0, i32 6
  %cmp = fcmp ogt float %vecext, 0.000000e+00
  %1 = load float, ptr %a1, align 4
  %cond = select i1 %cmp, float %1, float %vecext
  store float %cond, ptr %a1, align 4
  ret void
}

define float @PR43971_1(ptr%a0) nounwind {
; X86-SSE2-LABEL: PR43971_1:
; X86-SSE2:       # %bb.0: # %entry
; X86-SSE2-NEXT:    pushl %eax
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-SSE2-NEXT:    movaps (%eax), %xmm0
; X86-SSE2-NEXT:    shufps {{.*#+}} xmm0 = xmm0[1,1,1,1]
; X86-SSE2-NEXT:    xorps %xmm1, %xmm1
; X86-SSE2-NEXT:    cmpeqss %xmm0, %xmm1
; X86-SSE2-NEXT:    movss {{.*#+}} xmm2 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
; X86-SSE2-NEXT:    andps %xmm1, %xmm2
; X86-SSE2-NEXT:    andnps %xmm0, %xmm1
; X86-SSE2-NEXT:    orps %xmm2, %xmm1
; X86-SSE2-NEXT:    movss %xmm1, (%esp)
; X86-SSE2-NEXT:    flds (%esp)
; X86-SSE2-NEXT:    popl %eax
; X86-SSE2-NEXT:    retl
;
; X64-SSSE3-LABEL: PR43971_1:
; X64-SSSE3:       # %bb.0: # %entry
; X64-SSSE3-NEXT:    movshdup {{.*#+}} xmm1 = mem[1,1,3,3]
; X64-SSSE3-NEXT:    xorps %xmm0, %xmm0
; X64-SSSE3-NEXT:    cmpeqss %xmm1, %xmm0
; X64-SSSE3-NEXT:    movss {{.*#+}} xmm2 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
; X64-SSSE3-NEXT:    andps %xmm0, %xmm2
; X64-SSSE3-NEXT:    andnps %xmm1, %xmm0
; X64-SSSE3-NEXT:    orps %xmm2, %xmm0
; X64-SSSE3-NEXT:    retq
;
; X64-AVX1-LABEL: PR43971_1:
; X64-AVX1:       # %bb.0: # %entry
; X64-AVX1-NEXT:    vmovss {{.*#+}} xmm0 = mem[0],zero,zero,zero
; X64-AVX1-NEXT:    vxorps %xmm1, %xmm1, %xmm1
; X64-AVX1-NEXT:    vcmpeqss %xmm1, %xmm0, %xmm1
; X64-AVX1-NEXT:    vblendvps %xmm1, {{\.?LCPI[0-9]+_[0-9]+}}(%rip), %xmm0, %xmm0
; X64-AVX1-NEXT:    retq
;
; X64-AVX2-LABEL: PR43971_1:
; X64-AVX2:       # %bb.0: # %entry
; X64-AVX2-NEXT:    vmovss {{.*#+}} xmm0 = mem[0],zero,zero,zero
; X64-AVX2-NEXT:    vxorps %xmm1, %xmm1, %xmm1
; X64-AVX2-NEXT:    vcmpeqss %xmm1, %xmm0, %xmm1
; X64-AVX2-NEXT:    vbroadcastss {{.*#+}} xmm2 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0]
; X64-AVX2-NEXT:    vblendvps %xmm1, %xmm2, %xmm0, %xmm0
; X64-AVX2-NEXT:    retq
entry:
  %0 = load <8 x float>, ptr %a0, align 32
  %vecext = extractelement <8 x float> %0, i32 1
  %cmp = fcmp oeq float %vecext, 0.000000e+00
  %cond = select i1 %cmp, float 1.000000e+00, float %vecext
  ret float %cond
}

define i32 @PR85419(ptr %p0) {
; X86-SSE2-LABEL: PR85419:
; X86-SSE2:       # %bb.0:
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-SSE2-NEXT:    movl (%ecx), %edx
; X86-SSE2-NEXT:    xorl %eax, %eax
; X86-SSE2-NEXT:    orl 4(%ecx), %edx
; X86-SSE2-NEXT:    je .LBB8_2
; X86-SSE2-NEXT:  # %bb.1:
; X86-SSE2-NEXT:    movl 8(%ecx), %eax
; X86-SSE2-NEXT:  .LBB8_2:
; X86-SSE2-NEXT:    retl
;
; X64-LABEL: PR85419:
; X64:       # %bb.0:
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    cmpq $0, (%rdi)
; X64-NEXT:    je .LBB8_2
; X64-NEXT:  # %bb.1:
; X64-NEXT:    movl 8(%rdi), %eax
; X64-NEXT:  .LBB8_2:
; X64-NEXT:    retq
  %load = load <2 x i64>, ptr %p0, align 16
  %vecext.i = extractelement <2 x i64> %load, i64 0
  %cmp = icmp eq i64 %vecext.i, 0
  %.cast = bitcast <2 x i64> %load to <4 x i32>
  %vecext.i2 = extractelement <4 x i32> %.cast, i64 2
  %retval.0 = select i1 %cmp, i32 0, i32 %vecext.i2
  ret i32 %retval.0
}

; Test for bad extractions from a VBROADCAST_LOAD of the <2 x i16> non-uniform constant bitcast as <4 x i32>.
define void @subextract_broadcast_load_constant(ptr nocapture %0, ptr nocapture %1, ptr nocapture %2) nounwind {
; X86-SSE2-LABEL: subextract_broadcast_load_constant:
; X86-SSE2:       # %bb.0:
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %edx
; X86-SSE2-NEXT:    movl $-1583308898, (%edx) # imm = 0xA1A09F9E
; X86-SSE2-NEXT:    movw $-24674, (%ecx) # imm = 0x9F9E
; X86-SSE2-NEXT:    movw $-24160, (%eax) # imm = 0xA1A0
; X86-SSE2-NEXT:    retl
;
; X64-LABEL: subextract_broadcast_load_constant:
; X64:       # %bb.0:
; X64-NEXT:    movl $-1583308898, (%rdi) # imm = 0xA1A09F9E
; X64-NEXT:    movw $-24674, (%rsi) # imm = 0x9F9E
; X64-NEXT:    movw $-24160, (%rdx) # imm = 0xA1A0
; X64-NEXT:    retq
  store i8 -98, ptr %0, align 1
  %4 = getelementptr inbounds i8, ptr %0, i64 1
  store i8 -97, ptr %4, align 1
  %5 = getelementptr inbounds i8, ptr %0, i64 2
  store i8 -96, ptr %5, align 1
  %6 = getelementptr inbounds i8, ptr %0, i64 3
  store i8 -95, ptr %6, align 1
  %7 = load <2 x i16>, ptr %0, align 4
  %8 = extractelement <2 x i16> %7, i32 0
  store i16 %8, ptr %1, align 2
  %9 = extractelement <2 x i16> %7, i32 1
  store i16 %9, ptr %2, align 2
  ret void
}

; A scalar load is favored over a XMM->GPR register transfer in this example.

define i32 @multi_use_load_scalarization(ptr %p) nounwind {
; X86-SSE2-LABEL: multi_use_load_scalarization:
; X86-SSE2:       # %bb.0:
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-SSE2-NEXT:    movl (%ecx), %eax
; X86-SSE2-NEXT:    movdqu (%ecx), %xmm0
; X86-SSE2-NEXT:    pcmpeqd %xmm1, %xmm1
; X86-SSE2-NEXT:    psubd %xmm1, %xmm0
; X86-SSE2-NEXT:    movdqa %xmm0, (%ecx)
; X86-SSE2-NEXT:    retl
;
; X64-SSSE3-LABEL: multi_use_load_scalarization:
; X64-SSSE3:       # %bb.0:
; X64-SSSE3-NEXT:    movl (%rdi), %eax
; X64-SSSE3-NEXT:    movdqu (%rdi), %xmm0
; X64-SSSE3-NEXT:    pcmpeqd %xmm1, %xmm1
; X64-SSSE3-NEXT:    psubd %xmm1, %xmm0
; X64-SSSE3-NEXT:    movdqa %xmm0, (%rdi)
; X64-SSSE3-NEXT:    retq
;
; X64-AVX-LABEL: multi_use_load_scalarization:
; X64-AVX:       # %bb.0:
; X64-AVX-NEXT:    movl (%rdi), %eax
; X64-AVX-NEXT:    vmovdqu (%rdi), %xmm0
; X64-AVX-NEXT:    vpcmpeqd %xmm1, %xmm1, %xmm1
; X64-AVX-NEXT:    vpsubd %xmm1, %xmm0, %xmm0
; X64-AVX-NEXT:    vmovdqa %xmm0, (%rdi)
; X64-AVX-NEXT:    retq
  %v = load <4 x i32>, ptr %p, align 1
  %v1 = add <4 x i32> %v, <i32 1, i32 1, i32 1, i32 1>
  store <4 x i32> %v1, ptr %p
  %r = extractelement <4 x i32> %v, i64 0
  ret i32 %r
}

define i32 @multi_use_volatile_load_scalarization(ptr %p) nounwind {
; X86-SSE2-LABEL: multi_use_volatile_load_scalarization:
; X86-SSE2:       # %bb.0:
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-SSE2-NEXT:    movdqu (%ecx), %xmm0
; X86-SSE2-NEXT:    pcmpeqd %xmm1, %xmm1
; X86-SSE2-NEXT:    movd %xmm0, %eax
; X86-SSE2-NEXT:    psubd %xmm1, %xmm0
; X86-SSE2-NEXT:    movdqa %xmm0, (%ecx)
; X86-SSE2-NEXT:    retl
;
; X64-SSSE3-LABEL: multi_use_volatile_load_scalarization:
; X64-SSSE3:       # %bb.0:
; X64-SSSE3-NEXT:    movdqu (%rdi), %xmm0
; X64-SSSE3-NEXT:    pcmpeqd %xmm1, %xmm1
; X64-SSSE3-NEXT:    movd %xmm0, %eax
; X64-SSSE3-NEXT:    psubd %xmm1, %xmm0
; X64-SSSE3-NEXT:    movdqa %xmm0, (%rdi)
; X64-SSSE3-NEXT:    retq
;
; X64-AVX-LABEL: multi_use_volatile_load_scalarization:
; X64-AVX:       # %bb.0:
; X64-AVX-NEXT:    vmovdqu (%rdi), %xmm0
; X64-AVX-NEXT:    vpcmpeqd %xmm1, %xmm1, %xmm1
; X64-AVX-NEXT:    vpsubd %xmm1, %xmm0, %xmm1
; X64-AVX-NEXT:    vmovdqa %xmm1, (%rdi)
; X64-AVX-NEXT:    vmovd %xmm0, %eax
; X64-AVX-NEXT:    retq
  %v = load volatile <4 x i32>, ptr %p, align 1
  %v1 = add <4 x i32> %v, <i32 1, i32 1, i32 1, i32 1>
  store <4 x i32> %v1, ptr %p
  %r = extractelement <4 x i32> %v, i64 0
  ret i32 %r
}

; This test is reduced from a C source example that showed a miscompile:
; https://github.com/llvm/llvm-project/issues/53695
; The scalarized loads from 'zero' in the AVX asm must occur before
; the vector store to 'zero' overwrites the values.
; If compiled to a binary, this test should return 0 if correct.

@n1 = local_unnamed_addr global <8 x i32> <i32 0, i32 42, i32 6, i32 0, i32 0, i32 0, i32 0, i32 0>, align 32
@zero = internal unnamed_addr global <8 x i32> zeroinitializer, align 32

define i32 @main() nounwind {
; X86-SSE2-LABEL: main:
; X86-SSE2:       # %bb.0:
; X86-SSE2-NEXT:    pushl %ebp
; X86-SSE2-NEXT:    movl %esp, %ebp
; X86-SSE2-NEXT:    pushl %edi
; X86-SSE2-NEXT:    pushl %esi
; X86-SSE2-NEXT:    andl $-32, %esp
; X86-SSE2-NEXT:    subl $64, %esp
; X86-SSE2-NEXT:    movaps n1+16, %xmm0
; X86-SSE2-NEXT:    movaps n1, %xmm1
; X86-SSE2-NEXT:    movl zero+4, %ecx
; X86-SSE2-NEXT:    movl zero+8, %eax
; X86-SSE2-NEXT:    movaps %xmm1, zero
; X86-SSE2-NEXT:    movaps %xmm0, zero+16
; X86-SSE2-NEXT:    movaps {{.*#+}} xmm0 = [2,2,2,2]
; X86-SSE2-NEXT:    movaps %xmm0, {{[0-9]+}}(%esp)
; X86-SSE2-NEXT:    movaps %xmm0, (%esp)
; X86-SSE2-NEXT:    movdqa (%esp), %xmm0
; X86-SSE2-NEXT:    movaps {{[0-9]+}}(%esp), %xmm1
; X86-SSE2-NEXT:    pshufd {{.*#+}} xmm1 = xmm0[2,3,2,3]
; X86-SSE2-NEXT:    movd %xmm1, %esi
; X86-SSE2-NEXT:    xorl %edx, %edx
; X86-SSE2-NEXT:    divl %esi
; X86-SSE2-NEXT:    movl %eax, %esi
; X86-SSE2-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[1,1,1,1]
; X86-SSE2-NEXT:    movd %xmm0, %edi
; X86-SSE2-NEXT:    movl %ecx, %eax
; X86-SSE2-NEXT:    xorl %edx, %edx
; X86-SSE2-NEXT:    divl %edi
; X86-SSE2-NEXT:    addl %esi, %eax
; X86-SSE2-NEXT:    leal -8(%ebp), %esp
; X86-SSE2-NEXT:    popl %esi
; X86-SSE2-NEXT:    popl %edi
; X86-SSE2-NEXT:    popl %ebp
; X86-SSE2-NEXT:    retl
;
; X64-SSSE3-LABEL: main:
; X64-SSSE3:       # %bb.0:
; X64-SSSE3-NEXT:    pushq %rbp
; X64-SSSE3-NEXT:    movq %rsp, %rbp
; X64-SSSE3-NEXT:    andq $-32, %rsp
; X64-SSSE3-NEXT:    subq $64, %rsp
; X64-SSSE3-NEXT:    movq n1@GOTPCREL(%rip), %rax
; X64-SSSE3-NEXT:    movaps (%rax), %xmm0
; X64-SSSE3-NEXT:    movaps 16(%rax), %xmm1
; X64-SSSE3-NEXT:    movl zero+4(%rip), %ecx
; X64-SSSE3-NEXT:    movl zero+8(%rip), %eax
; X64-SSSE3-NEXT:    movaps %xmm0, zero(%rip)
; X64-SSSE3-NEXT:    movaps %xmm1, zero+16(%rip)
; X64-SSSE3-NEXT:    movaps {{.*#+}} xmm0 = [2,2,2,2]
; X64-SSSE3-NEXT:    movaps %xmm0, {{[0-9]+}}(%rsp)
; X64-SSSE3-NEXT:    movaps %xmm0, (%rsp)
; X64-SSSE3-NEXT:    movdqa (%rsp), %xmm0
; X64-SSSE3-NEXT:    movaps {{[0-9]+}}(%rsp), %xmm1
; X64-SSSE3-NEXT:    pshufd {{.*#+}} xmm1 = xmm0[2,3,2,3]
; X64-SSSE3-NEXT:    movd %xmm1, %esi
; X64-SSSE3-NEXT:    xorl %edx, %edx
; X64-SSSE3-NEXT:    divl %esi
; X64-SSSE3-NEXT:    movl %eax, %esi
; X64-SSSE3-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[1,1,1,1]
; X64-SSSE3-NEXT:    movd %xmm0, %edi
; X64-SSSE3-NEXT:    movl %ecx, %eax
; X64-SSSE3-NEXT:    xorl %edx, %edx
; X64-SSSE3-NEXT:    divl %edi
; X64-SSSE3-NEXT:    addl %esi, %eax
; X64-SSSE3-NEXT:    movq %rbp, %rsp
; X64-SSSE3-NEXT:    popq %rbp
; X64-SSSE3-NEXT:    retq
;
; X64-AVX-LABEL: main:
; X64-AVX:       # %bb.0:
; X64-AVX-NEXT:    pushq %rbp
; X64-AVX-NEXT:    movq %rsp, %rbp
; X64-AVX-NEXT:    andq $-32, %rsp
; X64-AVX-NEXT:    subq $64, %rsp
; X64-AVX-NEXT:    movq n1@GOTPCREL(%rip), %rax
; X64-AVX-NEXT:    vmovaps (%rax), %ymm0
; X64-AVX-NEXT:    movl zero+4(%rip), %ecx
; X64-AVX-NEXT:    movl zero+8(%rip), %eax
; X64-AVX-NEXT:    vmovaps %ymm0, zero(%rip)
; X64-AVX-NEXT:    vbroadcastss {{.*#+}} ymm0 = [2,2,2,2,2,2,2,2]
; X64-AVX-NEXT:    vmovaps %ymm0, (%rsp)
; X64-AVX-NEXT:    vmovaps (%rsp), %ymm0
; X64-AVX-NEXT:    vextractps $2, %xmm0, %esi
; X64-AVX-NEXT:    xorl %edx, %edx
; X64-AVX-NEXT:    divl %esi
; X64-AVX-NEXT:    movl %eax, %esi
; X64-AVX-NEXT:    vextractps $1, %xmm0, %edi
; X64-AVX-NEXT:    movl %ecx, %eax
; X64-AVX-NEXT:    xorl %edx, %edx
; X64-AVX-NEXT:    divl %edi
; X64-AVX-NEXT:    addl %esi, %eax
; X64-AVX-NEXT:    movq %rbp, %rsp
; X64-AVX-NEXT:    popq %rbp
; X64-AVX-NEXT:    vzeroupper
; X64-AVX-NEXT:    retq
  %stackptr = alloca <8 x i32>, align 32
  %z = load <8 x i32>, ptr @zero, align 32
  %t1 = load <8 x i32>, ptr @n1, align 32
  store <8 x i32> %t1, ptr @zero, align 32
  store volatile <8 x i32> <i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2>, ptr %stackptr, align 32
  %stackload = load volatile <8 x i32>, ptr %stackptr, align 32
  %div = udiv <8 x i32> %z, %stackload
  %e1 = extractelement <8 x i32> %div, i64 1
  %e2 = extractelement <8 x i32> %div, i64 2
  %r = add i32 %e1, %e2
  ret i32 %r
}

; A test for incorrect combine for single value extraction from VBROADCAST_LOAD.
; Wrong combine makes the second call (%t8) use the stored result in the
; previous instructions instead of %t4.
declare <2 x float> @ccosf(<2 x float>)
define dso_local <2 x float> @multiuse_of_single_value_from_vbroadcast_load(ptr %p, ptr %arr) nounwind {
; X86-SSE2-LABEL: multiuse_of_single_value_from_vbroadcast_load:
; X86-SSE2:       # %bb.0:
; X86-SSE2-NEXT:    pushl %esi
; X86-SSE2-NEXT:    subl $16, %esp
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %esi
; X86-SSE2-NEXT:    movups 24(%esi), %xmm0
; X86-SSE2-NEXT:    movups %xmm0, (%esp) # 16-byte Spill
; X86-SSE2-NEXT:    movhps %xmm0, (%eax)
; X86-SSE2-NEXT:    movaps 32(%esi), %xmm0
; X86-SSE2-NEXT:    calll ccosf@PLT
; X86-SSE2-NEXT:    movlps %xmm0, 32(%esi)
; X86-SSE2-NEXT:    movups (%esp), %xmm0 # 16-byte Reload
; X86-SSE2-NEXT:    movhlps {{.*#+}} xmm0 = xmm0[1,1]
; X86-SSE2-NEXT:    calll ccosf@PLT
; X86-SSE2-NEXT:    addl $16, %esp
; X86-SSE2-NEXT:    popl %esi
; X86-SSE2-NEXT:    retl
;
; X64-SSSE3-LABEL: multiuse_of_single_value_from_vbroadcast_load:
; X64-SSSE3:       # %bb.0:
; X64-SSSE3-NEXT:    pushq %rbx
; X64-SSSE3-NEXT:    subq $16, %rsp
; X64-SSSE3-NEXT:    movq %rsi, %rbx
; X64-SSSE3-NEXT:    movddup {{.*#+}} xmm0 = mem[0,0]
; X64-SSSE3-NEXT:    movapd %xmm0, (%rsp) # 16-byte Spill
; X64-SSSE3-NEXT:    movlpd %xmm0, (%rdi)
; X64-SSSE3-NEXT:    movaps 32(%rsi), %xmm0
; X64-SSSE3-NEXT:    callq ccosf@PLT
; X64-SSSE3-NEXT:    movlps %xmm0, 32(%rbx)
; X64-SSSE3-NEXT:    movaps (%rsp), %xmm0 # 16-byte Reload
; X64-SSSE3-NEXT:    callq ccosf@PLT
; X64-SSSE3-NEXT:    addq $16, %rsp
; X64-SSSE3-NEXT:    popq %rbx
; X64-SSSE3-NEXT:    retq
;
; X64-AVX-LABEL: multiuse_of_single_value_from_vbroadcast_load:
; X64-AVX:       # %bb.0:
; X64-AVX-NEXT:    pushq %rbx
; X64-AVX-NEXT:    movq %rsi, %rbx
; X64-AVX-NEXT:    vmovsd 32(%rsi), %xmm0 # xmm0 = mem[0],zero
; X64-AVX-NEXT:    vmovsd %xmm0, (%rdi)
; X64-AVX-NEXT:    vmovaps 32(%rsi), %xmm0
; X64-AVX-NEXT:    callq ccosf@PLT
; X64-AVX-NEXT:    vmovlps %xmm0, 32(%rbx)
; X64-AVX-NEXT:    vmovddup 32(%rbx), %xmm0 # xmm0 = mem[0,0]
; X64-AVX-NEXT:    callq ccosf@PLT
; X64-AVX-NEXT:    popq %rbx
; X64-AVX-NEXT:    retq
  %p1 = getelementptr [5 x <2 x float>], ptr %arr, i64 0, i64 3
  %p2 = getelementptr inbounds [5 x <2 x float>], ptr %arr, i64 0, i64 4, i32 0
  %t3 = load <4 x float>, ptr %p1, align 8
  %t4 = shufflevector <4 x float> %t3, <4 x float> poison, <2 x i32> <i32 2, i32 3>
  store <2 x float> %t4, ptr %p, align 16
  %t5 = load <4 x float>, ptr %p2, align 32
  %t6 = shufflevector <4 x float> %t5, <4 x float> poison, <2 x i32> <i32 0, i32 1>
  %t7 = call <2 x float> @ccosf(<2 x float> %t6)
  store <2 x float> %t7, ptr %p2, align 32
  %t8 = call <2 x float> @ccosf(<2 x float> %t4)
  ret <2 x float> %t8
}
