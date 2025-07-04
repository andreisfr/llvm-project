; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 5
; RUN: opt -p loop-vectorize -S %s | FileCheck %s

target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-linux-gnu"

; Test case for https://github.com/llvm/llvm-project/issues/106417.
define void @skip_free_iv_truncate(i16 %x, ptr %A) #0 {
; CHECK-LABEL: define void @skip_free_iv_truncate(
; CHECK-SAME: i16 [[X:%.*]], ptr [[A:%.*]]) #[[ATTR0:[0-9]+]] {
; CHECK-NEXT:  [[ENTRY:.*]]:
; CHECK-NEXT:    [[X_I32:%.*]] = sext i16 [[X]] to i32
; CHECK-NEXT:    [[X_I64:%.*]] = sext i16 [[X]] to i64
; CHECK-NEXT:    [[INVARIANT_GEP:%.*]] = getelementptr i8, ptr [[A]], i64 -8
; CHECK-NEXT:    [[SMAX20:%.*]] = call i64 @llvm.smax.i64(i64 [[X_I64]], i64 99)
; CHECK-NEXT:    [[TMP0:%.*]] = sub i64 [[SMAX20]], [[X_I64]]
; CHECK-NEXT:    [[UMIN21:%.*]] = call i64 @llvm.umin.i64(i64 [[TMP0]], i64 1)
; CHECK-NEXT:    [[TMP1:%.*]] = sub i64 [[SMAX20]], [[UMIN21]]
; CHECK-NEXT:    [[TMP2:%.*]] = sub i64 [[TMP1]], [[X_I64]]
; CHECK-NEXT:    [[TMP3:%.*]] = udiv i64 [[TMP2]], 3
; CHECK-NEXT:    [[TMP4:%.*]] = add i64 [[UMIN21]], [[TMP3]]
; CHECK-NEXT:    [[TMP5:%.*]] = add i64 [[TMP4]], 1
; CHECK-NEXT:    [[TMP6:%.*]] = call i64 @llvm.vscale.i64()
; CHECK-NEXT:    [[TMP7:%.*]] = mul nuw i64 [[TMP6]], 8
; CHECK-NEXT:    [[TMP8:%.*]] = call i64 @llvm.umax.i64(i64 128, i64 [[TMP7]])
; CHECK-NEXT:    [[MIN_ITERS_CHECK:%.*]] = icmp ule i64 [[TMP5]], [[TMP8]]
; CHECK-NEXT:    br i1 [[MIN_ITERS_CHECK]], label %[[SCALAR_PH:.*]], label %[[VECTOR_MEMCHECK:.*]]
; CHECK:       [[VECTOR_MEMCHECK]]:
; CHECK-NEXT:    [[TMP31:%.*]] = shl nsw i64 [[X_I64]], 1
; CHECK-NEXT:    [[SCEVGEP9:%.*]] = getelementptr i8, ptr [[A]], i64 [[TMP31]]
; CHECK-NEXT:    [[SMAX10:%.*]] = call i64 @llvm.smax.i64(i64 [[X_I64]], i64 99)
; CHECK-NEXT:    [[TMP32:%.*]] = sub i64 [[SMAX10]], [[X_I64]]
; CHECK-NEXT:    [[UMIN11:%.*]] = call i64 @llvm.umin.i64(i64 [[TMP32]], i64 1)
; CHECK-NEXT:    [[TMP33:%.*]] = sub i64 [[SMAX10]], [[UMIN11]]
; CHECK-NEXT:    [[TMP34:%.*]] = sub i64 [[TMP33]], [[X_I64]]
; CHECK-NEXT:    [[TMP35:%.*]] = udiv i64 [[TMP34]], 3
; CHECK-NEXT:    [[TMP36:%.*]] = add i64 [[UMIN11]], [[TMP35]]
; CHECK-NEXT:    [[TMP37:%.*]] = mul i64 [[TMP36]], 6
; CHECK-NEXT:    [[TMP38:%.*]] = add i64 [[TMP37]], [[TMP31]]
; CHECK-NEXT:    [[TMP39:%.*]] = add i64 [[TMP38]], 2
; CHECK-NEXT:    [[SCEVGEP12:%.*]] = getelementptr i8, ptr [[A]], i64 [[TMP39]]
; CHECK-NEXT:    [[TMP40:%.*]] = shl nsw i64 [[X_I64]], 3
; CHECK-NEXT:    [[SCEVGEP13:%.*]] = getelementptr i8, ptr [[A]], i64 [[TMP40]]
; CHECK-NEXT:    [[TMP41:%.*]] = mul i64 [[TMP36]], 24
; CHECK-NEXT:    [[TMP42:%.*]] = add i64 [[TMP41]], [[TMP40]]
; CHECK-NEXT:    [[TMP43:%.*]] = add i64 [[TMP42]], 8
; CHECK-NEXT:    [[SCEVGEP14:%.*]] = getelementptr i8, ptr [[A]], i64 [[TMP43]]
; CHECK-NEXT:    [[TMP44:%.*]] = add nsw i64 [[TMP40]], -8
; CHECK-NEXT:    [[SCEVGEP15:%.*]] = getelementptr i8, ptr [[A]], i64 [[TMP44]]
; CHECK-NEXT:    [[SCEVGEP16:%.*]] = getelementptr i8, ptr [[A]], i64 [[TMP42]]
; CHECK-NEXT:    [[BOUND0:%.*]] = icmp ult ptr [[SCEVGEP9]], [[SCEVGEP14]]
; CHECK-NEXT:    [[BOUND1:%.*]] = icmp ult ptr [[SCEVGEP13]], [[SCEVGEP12]]
; CHECK-NEXT:    [[FOUND_CONFLICT:%.*]] = and i1 [[BOUND0]], [[BOUND1]]
; CHECK-NEXT:    [[BOUND017:%.*]] = icmp ult ptr [[SCEVGEP9]], [[SCEVGEP16]]
; CHECK-NEXT:    [[BOUND118:%.*]] = icmp ult ptr [[SCEVGEP15]], [[SCEVGEP12]]
; CHECK-NEXT:    [[FOUND_CONFLICT19:%.*]] = and i1 [[BOUND017]], [[BOUND118]]
; CHECK-NEXT:    [[CONFLICT_RDX:%.*]] = or i1 [[FOUND_CONFLICT]], [[FOUND_CONFLICT19]]
; CHECK-NEXT:    br i1 [[CONFLICT_RDX]], label %[[SCALAR_PH]], label %[[VECTOR_PH:.*]]
; CHECK:       [[VECTOR_PH]]:
; CHECK-NEXT:    [[TMP45:%.*]] = call i64 @llvm.vscale.i64()
; CHECK-NEXT:    [[TMP46:%.*]] = mul nuw i64 [[TMP45]], 8
; CHECK-NEXT:    [[N_MOD_VF:%.*]] = urem i64 [[TMP5]], [[TMP46]]
; CHECK-NEXT:    [[TMP47:%.*]] = icmp eq i64 [[N_MOD_VF]], 0
; CHECK-NEXT:    [[TMP48:%.*]] = select i1 [[TMP47]], i64 [[TMP46]], i64 [[N_MOD_VF]]
; CHECK-NEXT:    [[N_VEC:%.*]] = sub i64 [[TMP5]], [[TMP48]]
; CHECK-NEXT:    [[TMP51:%.*]] = call i64 @llvm.vscale.i64()
; CHECK-NEXT:    [[TMP52:%.*]] = mul nuw i64 [[TMP51]], 8
; CHECK-NEXT:    [[TMP49:%.*]] = mul i64 [[N_VEC]], 3
; CHECK-NEXT:    [[IND_END:%.*]] = add i64 [[X_I64]], [[TMP49]]
; CHECK-NEXT:    [[DOTCAST:%.*]] = trunc i64 [[N_VEC]] to i32
; CHECK-NEXT:    [[TMP50:%.*]] = mul i32 [[DOTCAST]], 3
; CHECK-NEXT:    [[IND_END22:%.*]] = add i32 [[X_I32]], [[TMP50]]
; CHECK-NEXT:    [[TMP53:%.*]] = call <vscale x 8 x i64> @llvm.stepvector.nxv8i64()
; CHECK-NEXT:    [[DOTSPLATINSERT:%.*]] = insertelement <vscale x 8 x i64> poison, i64 [[X_I64]], i64 0
; CHECK-NEXT:    [[DOTSPLAT:%.*]] = shufflevector <vscale x 8 x i64> [[DOTSPLATINSERT]], <vscale x 8 x i64> poison, <vscale x 8 x i32> zeroinitializer
; CHECK-NEXT:    [[TMP55:%.*]] = mul <vscale x 8 x i64> [[TMP53]], splat (i64 3)
; CHECK-NEXT:    [[INDUCTION:%.*]] = add <vscale x 8 x i64> [[DOTSPLAT]], [[TMP55]]
; CHECK-NEXT:    [[TMP58:%.*]] = mul i64 3, [[TMP52]]
; CHECK-NEXT:    [[DOTSPLATINSERT24:%.*]] = insertelement <vscale x 8 x i64> poison, i64 [[TMP58]], i64 0
; CHECK-NEXT:    [[DOTSPLAT25:%.*]] = shufflevector <vscale x 8 x i64> [[DOTSPLATINSERT24]], <vscale x 8 x i64> poison, <vscale x 8 x i32> zeroinitializer
; CHECK-NEXT:    br label %[[VECTOR_BODY:.*]]
; CHECK:       [[VECTOR_BODY]]:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i64 [ 0, %[[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], %[[VECTOR_BODY]] ]
; CHECK-NEXT:    [[VEC_IND:%.*]] = phi <vscale x 8 x i64> [ [[INDUCTION]], %[[VECTOR_PH]] ], [ [[VEC_IND_NEXT:%.*]], %[[VECTOR_BODY]] ]
; CHECK-NEXT:    [[TMP59:%.*]] = getelementptr i16, ptr [[A]], <vscale x 8 x i64> [[VEC_IND]]
; CHECK-NEXT:    call void @llvm.masked.scatter.nxv8i16.nxv8p0(<vscale x 8 x i16> zeroinitializer, <vscale x 8 x ptr> [[TMP59]], i32 2, <vscale x 8 x i1> splat (i1 true)), !alias.scope [[META0:![0-9]+]], !noalias [[META3:![0-9]+]]
; CHECK-NEXT:    [[INDEX_NEXT]] = add nuw i64 [[INDEX]], [[TMP52]]
; CHECK-NEXT:    [[VEC_IND_NEXT]] = add <vscale x 8 x i64> [[VEC_IND]], [[DOTSPLAT25]]
; CHECK-NEXT:    [[TMP60:%.*]] = icmp eq i64 [[INDEX_NEXT]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[TMP60]], label %[[MIDDLE_BLOCK:.*]], label %[[VECTOR_BODY]], !llvm.loop [[LOOP6:![0-9]+]]
; CHECK:       [[MIDDLE_BLOCK]]:
; CHECK-NEXT:    br label %[[SCALAR_PH]]
; CHECK:       [[SCALAR_PH]]:
; CHECK-NEXT:    [[BC_RESUME_VAL:%.*]] = phi i64 [ [[IND_END]], %[[MIDDLE_BLOCK]] ], [ [[X_I64]], %[[ENTRY]] ], [ [[X_I64]], %[[VECTOR_MEMCHECK]] ]
; CHECK-NEXT:    [[BC_RESUME_VAL13:%.*]] = phi i32 [ [[IND_END22]], %[[MIDDLE_BLOCK]] ], [ [[X_I32]], %[[ENTRY]] ], [ [[X_I32]], %[[VECTOR_MEMCHECK]] ]
; CHECK-NEXT:    br label %[[LOOP:.*]]
; CHECK:       [[LOOP]]:
; CHECK-NEXT:    [[IV:%.*]] = phi i64 [ [[BC_RESUME_VAL]], %[[SCALAR_PH]] ], [ [[IV_NEXT:%.*]], %[[LOOP]] ]
; CHECK-NEXT:    [[IV_CONV:%.*]] = phi i32 [ [[BC_RESUME_VAL13]], %[[SCALAR_PH]] ], [ [[TMP64:%.*]], %[[LOOP]] ]
; CHECK-NEXT:    [[GEP_I64:%.*]] = getelementptr i64, ptr [[A]], i64 [[IV]]
; CHECK-NEXT:    [[TMP61:%.*]] = load i64, ptr [[GEP_I64]], align 8
; CHECK-NEXT:    [[TMP62:%.*]] = sext i32 [[IV_CONV]] to i64
; CHECK-NEXT:    [[GEP_CONV:%.*]] = getelementptr i64, ptr [[INVARIANT_GEP]], i64 [[TMP62]]
; CHECK-NEXT:    [[TMP63:%.*]] = load i64, ptr [[GEP_CONV]], align 8
; CHECK-NEXT:    [[GEP_I16:%.*]] = getelementptr i16, ptr [[A]], i64 [[IV]]
; CHECK-NEXT:    store i16 0, ptr [[GEP_I16]], align 2
; CHECK-NEXT:    [[IV_NEXT]] = add i64 [[IV]], 3
; CHECK-NEXT:    [[TMP64]] = trunc i64 [[IV_NEXT]] to i32
; CHECK-NEXT:    [[C:%.*]] = icmp slt i64 [[IV]], 99
; CHECK-NEXT:    br i1 [[C]], label %[[LOOP]], label %[[EXIT:.*]], !llvm.loop [[LOOP9:![0-9]+]]
; CHECK:       [[EXIT]]:
; CHECK-NEXT:    ret void
;
entry:
  %x.i32 = sext i16 %x to i32
  %x.i64 = sext i16 %x to i64
  %invariant.gep = getelementptr i8, ptr %A, i64 -8
  br label %loop

loop:
  %iv = phi i64 [ %x.i64, %entry ], [ %iv.next, %loop ]
  %iv.conv = phi i32 [ %x.i32, %entry ], [ %5, %loop ]
  %gep.i64 = getelementptr i64, ptr %A, i64 %iv
  %2 = load i64, ptr %gep.i64, align 8
  %3 = sext i32 %iv.conv to i64
  %gep.conv = getelementptr i64, ptr %invariant.gep, i64 %3
  %4 = load i64, ptr %gep.conv, align 8
  %gep.i16 = getelementptr i16, ptr %A, i64 %iv
  store i16 0, ptr %gep.i16, align 2
  %iv.next = add i64 %iv, 3
  %5 = trunc i64 %iv.next to i32
  %c = icmp slt i64 %iv, 99
  br i1 %c, label %loop, label %exit

exit:
  ret void
}

attributes #0 = { "target-features"="+64bit,+v,+zvl256b" }
;.
; CHECK: [[META0]] = !{[[META1:![0-9]+]]}
; CHECK: [[META1]] = distinct !{[[META1]], [[META2:![0-9]+]]}
; CHECK: [[META2]] = distinct !{[[META2]], !"LVerDomain"}
; CHECK: [[META3]] = !{[[META4:![0-9]+]], [[META5:![0-9]+]]}
; CHECK: [[META4]] = distinct !{[[META4]], [[META2]]}
; CHECK: [[META5]] = distinct !{[[META5]], [[META2]]}
; CHECK: [[LOOP6]] = distinct !{[[LOOP6]], [[META7:![0-9]+]], [[META8:![0-9]+]]}
; CHECK: [[META7]] = !{!"llvm.loop.isvectorized", i32 1}
; CHECK: [[META8]] = !{!"llvm.loop.unroll.runtime.disable"}
; CHECK: [[LOOP9]] = distinct !{[[LOOP9]], [[META7]]}
;.
