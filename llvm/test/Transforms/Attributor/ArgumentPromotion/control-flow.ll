; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --check-attributes --check-globals
; RUN: opt -aa-pipeline=basic-aa -passes=attributor -attributor-manifest-internal  -attributor-annotate-decl-cs  -S < %s | FileCheck %s --check-prefixes=CHECK,TUNIT
; RUN: opt -aa-pipeline=basic-aa -passes=attributor-cgscc -attributor-manifest-internal  -attributor-annotate-decl-cs -S < %s | FileCheck %s --check-prefixes=CHECK,CGSCC

; Don't promote around control flow.
define internal i32 @callee(i1 %C, ptr %P) {
; CHECK: Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read)
; CHECK-LABEL: define {{[^@]+}}@callee
; CHECK-SAME: (i1 noundef [[C:%.*]], ptr nofree readonly captures(none) [[P:%.*]]) #[[ATTR0:[0-9]+]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[C]], label [[T:%.*]], label [[F:%.*]]
; CHECK:       T:
; CHECK-NEXT:    ret i32 17
; CHECK:       F:
; CHECK-NEXT:    [[X:%.*]] = load i32, ptr [[P]], align 4
; CHECK-NEXT:    ret i32 [[X]]
;
entry:
  br i1 %C, label %T, label %F

T:
  ret i32 17

F:
  %X = load i32, ptr %P
  ret i32 %X
}

define i32 @foo(i1 %C, ptr %P) {
; TUNIT: Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read)
; TUNIT-LABEL: define {{[^@]+}}@foo
; TUNIT-SAME: (i1 [[C:%.*]], ptr nofree readonly captures(none) [[P:%.*]]) #[[ATTR0]] {
; TUNIT-NEXT:  entry:
; TUNIT-NEXT:    [[X:%.*]] = call i32 @callee(i1 noundef [[C]], ptr nofree readonly captures(none) [[P]]) #[[ATTR1:[0-9]+]]
; TUNIT-NEXT:    ret i32 [[X]]
;
; CGSCC: Function Attrs: mustprogress nofree nosync nounwind willreturn memory(argmem: read)
; CGSCC-LABEL: define {{[^@]+}}@foo
; CGSCC-SAME: (i1 noundef [[C:%.*]], ptr nofree readonly captures(none) [[P:%.*]]) #[[ATTR1:[0-9]+]] {
; CGSCC-NEXT:  entry:
; CGSCC-NEXT:    [[X:%.*]] = call i32 @callee(i1 noundef [[C]], ptr nofree readonly captures(none) [[P]]) #[[ATTR2:[0-9]+]]
; CGSCC-NEXT:    ret i32 [[X]]
;
entry:
  %X = call i32 @callee(i1 %C, ptr %P)
  ret i32 %X
}

;.
; TUNIT: attributes #[[ATTR0]] = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) }
; TUNIT: attributes #[[ATTR1]] = { nofree nosync nounwind willreturn memory(read) }
;.
; CGSCC: attributes #[[ATTR0]] = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) }
; CGSCC: attributes #[[ATTR1]] = { mustprogress nofree nosync nounwind willreturn memory(argmem: read) }
; CGSCC: attributes #[[ATTR2]] = { nofree willreturn memory(read) }
;.
