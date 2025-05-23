// RUN: mlir-opt %s -split-input-file -test-decompose-call-graph-types | FileCheck %s

// Test case: Most basic case of a 1:N decomposition, an identity function.

// CHECK-LABEL:   func @identity(
// CHECK-SAME:                   %[[ARG0:.*]]: i1,
// CHECK-SAME:                   %[[ARG1:.*]]: i32) -> (i1, i32) {
// CHECK:           return %[[ARG0]], %[[ARG1]] : i1, i32
func.func @identity(%arg0: tuple<i1, i32>) -> tuple<i1, i32> {
  return %arg0 : tuple<i1, i32>
}

// -----

// Test case: Ensure no materializations in the case of 1:1 decomposition.

// CHECK-LABEL:   func @identity_1_to_1_no_materializations(
// CHECK-SAME:                                              %[[ARG0:.*]]: i1) -> i1 {
// CHECK:           return %[[ARG0]] : i1
func.func @identity_1_to_1_no_materializations(%arg0: tuple<i1>) -> tuple<i1> {
  return %arg0 : tuple<i1>
}

// -----

// Test case: Type that needs to be recursively decomposed.

// CHECK-LABEL:   func @recursive_decomposition(
// CHECK-SAME:                                   %[[ARG0:.*]]: i1) -> i1 {
// CHECK:           return %[[ARG0]] : i1
func.func @recursive_decomposition(%arg0: tuple<tuple<tuple<i1>>>) -> tuple<tuple<tuple<i1>>> {
  return %arg0 : tuple<tuple<tuple<i1>>>
}

// -----

// Test case: Type that needs to be recursively decomposed at different recursion depths.

// CHECK-LABEL:   func @mixed_recursive_decomposition(
// CHECK-SAME:                 %[[ARG0:.*]]: i1,
// CHECK-SAME:                 %[[ARG1:.*]]: i2) -> (i1, i2) {
// CHECK:           return %[[ARG0]], %[[ARG1]] : i1, i2
func.func @mixed_recursive_decomposition(%arg0: tuple<tuple<>, tuple<i1>, tuple<tuple<i2>>>) -> tuple<tuple<>, tuple<i1>, tuple<tuple<i2>>> {
  return %arg0 : tuple<tuple<>, tuple<i1>, tuple<tuple<i2>>>
}

// -----

// Test case: Check decomposition of calls.

// CHECK-LABEL:   func private @callee(i1, i32) -> (i1, i32)
func.func private @callee(tuple<i1, i32>) -> tuple<i1, i32>

// CHECK-LABEL:   func @caller(
// CHECK-SAME:                 %[[ARG0:.*]]: i1,
// CHECK-SAME:                 %[[ARG1:.*]]: i32) -> (i1, i32) {
// CHECK:           %[[V0:.*]]:2 = call @callee(%[[ARG0]], %[[ARG1]]) : (i1, i32) -> (i1, i32)
// CHECK:           return %[[V0]]#0, %[[V0]]#1 : i1, i32
func.func @caller(%arg0: tuple<i1, i32>) -> tuple<i1, i32> {
  %0 = call @callee(%arg0) : (tuple<i1, i32>) -> tuple<i1, i32>
  return %0 : tuple<i1, i32>
}

// -----

// Test case: Type that decomposes to nothing (that is, a 1:0 decomposition).

// CHECK-LABEL:   func private @callee()
func.func private @callee(tuple<>) -> tuple<>

// CHECK-LABEL:   func @caller() {
// CHECK:           call @callee() : () -> ()
// CHECK:           return
func.func @caller(%arg0: tuple<>) -> tuple<> {
  %0 = call @callee(%arg0) : (tuple<>) -> (tuple<>)
  return %0 : tuple<>
}

// -----

// Test case: Ensure decompositions are inserted properly around results of
// unconverted ops.

// CHECK-LABEL:   func @unconverted_op_result() -> (i1, i32) {
// CHECK:           %[[UNCONVERTED_VALUE:.*]] = "test.source"() : () -> tuple<i1, i32>
// CHECK:           %[[RET0:.*]] = "test.get_tuple_element"(%[[UNCONVERTED_VALUE]]) <{index = 0 : i32}> : (tuple<i1, i32>) -> i1
// CHECK:           %[[RET1:.*]] = "test.get_tuple_element"(%[[UNCONVERTED_VALUE]]) <{index = 1 : i32}> : (tuple<i1, i32>) -> i32
// CHECK:           return %[[RET0]], %[[RET1]] : i1, i32
func.func @unconverted_op_result() -> tuple<i1, i32> {
  %0 = "test.source"() : () -> (tuple<i1, i32>)
  return %0 : tuple<i1, i32>
}

// -----

// Test case: Ensure decompositions are inserted properly around results of
// unconverted ops in the case of different nesting levels.

// CHECK-LABEL:   func @nested_unconverted_op_result(
// CHECK-SAME:                 %[[ARG0:.*]]: i1,
// CHECK-SAME:                 %[[ARG1:.*]]: i32) -> (i1, i32) {
// CHECK:           %[[V0:.*]] = "test.make_tuple"(%[[ARG1]]) : (i32) -> tuple<i32>
// CHECK:           %[[V1:.*]] = "test.make_tuple"(%[[ARG0]], %[[V0]]) : (i1, tuple<i32>) -> tuple<i1, tuple<i32>>
// CHECK:           %[[V2:.*]] = "test.op"(%[[V1]]) : (tuple<i1, tuple<i32>>) -> tuple<i1, tuple<i32>>
// CHECK:           %[[V3:.*]] = "test.get_tuple_element"(%[[V2]]) <{index = 0 : i32}> : (tuple<i1, tuple<i32>>) -> i1
// CHECK:           %[[V4:.*]] = "test.get_tuple_element"(%[[V2]]) <{index = 1 : i32}> : (tuple<i1, tuple<i32>>) -> tuple<i32>
// CHECK:           %[[V5:.*]] = "test.get_tuple_element"(%[[V4]]) <{index = 0 : i32}> : (tuple<i32>) -> i32
// CHECK:           return %[[V3]], %[[V5]] : i1, i32
func.func @nested_unconverted_op_result(%arg: tuple<i1, tuple<i32>>) -> tuple<i1, tuple<i32>> {
  %0 = "test.op"(%arg) : (tuple<i1, tuple<i32>>) -> (tuple<i1, tuple<i32>>)
  return %0 : tuple<i1, tuple<i32>>
}

// -----

// Test case: Check mixed decomposed and non-decomposed args.
// This makes sure to test the cases if 1:0, 1:1, and 1:N decompositions.

// CHECK-LABEL:   func private @callee(i1, i2, i3, i4, i5, i6) -> (i1, i2, i3, i4, i5, i6)
func.func private @callee(tuple<>, i1, tuple<i2>, i3, tuple<i4, i5>, i6) -> (tuple<>, i1, tuple<i2>, i3, tuple<i4, i5>, i6)

// CHECK-LABEL:   func @caller(
// CHECK-SAME:                 %[[I1:.*]]: i1,
// CHECK-SAME:                 %[[I2:.*]]: i2,
// CHECK-SAME:                 %[[I3:.*]]: i3,
// CHECK-SAME:                 %[[I4:.*]]: i4,
// CHECK-SAME:                 %[[I5:.*]]: i5,
// CHECK-SAME:                 %[[I6:.*]]: i6) -> (i1, i2, i3, i4, i5, i6) {
// CHECK:           %[[CALL:.*]]:6 = call @callee(%[[I1]], %[[I2]], %[[I3]], %[[I4]], %[[I5]], %[[I6]]) : (i1, i2, i3, i4, i5, i6) -> (i1, i2, i3, i4, i5, i6)
// CHECK:           return %[[CALL]]#0, %[[CALL]]#1, %[[CALL]]#2, %[[CALL]]#3, %[[CALL]]#4, %[[CALL]]#5 : i1, i2, i3, i4, i5, i6
func.func @caller(%arg0: tuple<>, %arg1: i1, %arg2: tuple<i2>, %arg3: i3, %arg4: tuple<i4, i5>, %arg5: i6) -> (tuple<>, i1, tuple<i2>, i3, tuple<i4, i5>, i6) {
  %0, %1, %2, %3, %4, %5 = call @callee(%arg0, %arg1, %arg2, %arg3, %arg4, %arg5) : (tuple<>, i1, tuple<i2>, i3, tuple<i4, i5>, i6) -> (tuple<>, i1, tuple<i2>, i3, tuple<i4, i5>, i6)
  return %0, %1, %2, %3, %4, %5 : tuple<>, i1, tuple<i2>, i3, tuple<i4, i5>, i6
}
