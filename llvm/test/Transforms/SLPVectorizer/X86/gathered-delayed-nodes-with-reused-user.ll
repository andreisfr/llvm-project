; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 4
; RUN: opt -passes=slp-vectorizer -S -slp-threshold=-9999 < %s | FileCheck %s
; RUN: opt -passes=slp-vectorizer -S -slp-threshold=-9999\
; RUN: -slp-skip-early-profitability-check < %s | FileCheck %s --check-prefixes=FORCED

define i64 @foo() {
; CHECK-LABEL: define i64 @foo() {
; CHECK-NEXT:  bb:
; CHECK-NEXT:    [[ADD7:%.*]] = add i64 0, 0
; CHECK-NEXT:    br label [[BB3:%.*]]
; CHECK:       bb1:
; CHECK-NEXT:    [[TMP1:%.*]] = phi <2 x i64> [ [[TMP5:%.*]], [[BB3]] ]
; CHECK-NEXT:    ret i64 0
; CHECK:       bb3:
; CHECK-NEXT:    [[PHI4:%.*]] = phi i64 [ 0, [[BB:%.*]] ], [ 0, [[BB3]] ]
; CHECK-NEXT:    [[TMP0:%.*]] = phi <2 x i64> [ zeroinitializer, [[BB]] ], [ [[TMP3:%.*]], [[BB3]] ]
; CHECK-NEXT:    [[TMP4:%.*]] = shufflevector <2 x i64> [[TMP0]], <2 x i64> <i64 poison, i64 0>, <2 x i32> <i32 0, i32 3>
; CHECK-NEXT:    [[TMP2:%.*]] = insertelement <2 x i64> <i64 poison, i64 0>, i64 [[PHI4]], i32 0
; CHECK-NEXT:    [[TMP3]] = add <2 x i64> [[TMP4]], [[TMP2]]
; CHECK-NEXT:    [[TMP5]] = add <2 x i64> [[TMP0]], [[TMP2]]
; CHECK-NEXT:    [[GETELEMENTPTR:%.*]] = getelementptr i64, ptr addrspace(1) null, i64 [[ADD7]]
; CHECK-NEXT:    [[OR:%.*]] = extractelement <2 x i64> [[TMP5]], i32 1
; CHECK-NEXT:    [[ICMP:%.*]] = icmp ult i64 [[OR]], 0
; CHECK-NEXT:    br i1 false, label [[BB3]], label [[BB1:%.*]]
;
; FORCED-LABEL: define i64 @foo() {
; FORCED-NEXT:  bb:
; FORCED-NEXT:    [[ADD7:%.*]] = add i64 0, 0
; FORCED-NEXT:    br label [[BB3:%.*]]
; FORCED:       bb1:
; FORCED-NEXT:    [[TMP0:%.*]] = phi <2 x i64> [ [[TMP5:%.*]], [[BB3]] ]
; FORCED-NEXT:    ret i64 0
; FORCED:       bb3:
; FORCED-NEXT:    [[PHI5:%.*]] = phi i64 [ 0, [[BB:%.*]] ], [ 0, [[BB3]] ]
; FORCED-NEXT:    [[TMP1:%.*]] = phi <2 x i64> [ zeroinitializer, [[BB]] ], [ [[TMP7:%.*]], [[BB3]] ]
; FORCED-NEXT:    [[TMP6:%.*]] = shufflevector <2 x i64> [[TMP1]], <2 x i64> <i64 poison, i64 0>, <2 x i32> <i32 0, i32 3>
; FORCED-NEXT:    [[TMP2:%.*]] = insertelement <2 x i64> <i64 poison, i64 0>, i64 [[PHI5]], i32 0
; FORCED-NEXT:    [[TMP7]] = add <2 x i64> [[TMP6]], [[TMP2]]
; FORCED-NEXT:    [[TMP5]] = add <2 x i64> [[TMP1]], [[TMP2]]
; FORCED-NEXT:    [[GETELEMENTPTR:%.*]] = getelementptr i64, ptr addrspace(1) null, i64 [[ADD7]]
; FORCED-NEXT:    [[TMP8:%.*]] = extractelement <2 x i64> [[TMP5]], i32 1
; FORCED-NEXT:    [[ICMP:%.*]] = icmp ult i64 [[TMP8]], 0
; FORCED-NEXT:    br i1 false, label [[BB3]], label [[BB1:%.*]]
;
bb:
  br label %bb3

bb1:
  %phi = phi i64 [ %add, %bb3 ]
  %phi2 = phi i64 [ %or, %bb3 ]
  ret i64 0

bb3:
  %phi4 = phi i64 [ 0, %bb ], [ %add7, %bb3 ]
  %phi5 = phi i64 [ 0, %bb ], [ 0, %bb3 ]
  %phi6 = phi i64 [ 0, %bb ], [ %add, %bb3 ]
  %add = add i64 %phi6, %phi5
  %add7 = add i64 0, 0
  %getelementptr = getelementptr i64, ptr addrspace(1) null, i64 %add7
  %or = or i64 %phi4, 0
  %icmp = icmp ult i64 %or, 0
  br i1 false, label %bb3, label %bb1
}

