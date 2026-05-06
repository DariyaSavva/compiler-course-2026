// RUN: mlir-opt -load-pass-plugin=%mlir_lib_dir//SavvaDariyaCopyToLoopPass_Savva_Dariya_FIIT1_MLIR_MLIR%shlibext \
// RUN: --pass-pipeline="builtin.module(/savva-copy-to-loop)" %s | FileCheck %s


// CHECK-LABEL: func.func @copy_1d
// CHECK: scf.for
// CHECK: memref.load
// CHECK: memref.store
func.func @copy_1d(%A: memref<4xi32>, %B: memref<4xi32>) {
  memref.copy %A, %B : memref<4xi32> to memref<4xi32>
  return
}


// CHECK-LABEL: func.func @copy_2d
// CHECK: scf.for
// CHECK: scf.for
// CHECK: memref.load
// CHECK: memref.store
func.func @copy_2d(%A: memref<2x3xi32>, %B: memref<2x3xi32>) {
  memref.copy %A, %B : memref<2x3xi32> to memref<2x3xi32>
  return
}


// CHECK-LABEL: func.func @copy_dynamic
// CHECK: memref.dim
// CHECK: scf.for
// CHECK: memref.load
// CHECK: memref.store
func.func @copy_dynamic(%A: memref<?xi32>, %B: memref<?xi32>) {
  memref.copy %A, %B : memref<?xi32> to memref<?xi32>
  return
}


// CHECK-LABEL: func.func @no_copy
// CHECK-NOT: scf.for
func.func @no_copy(%A: memref<4xi32>) {
  %0 = memref.load %A[0] : memref<4xi32>
  return
}

// CHECK-LABEL: func.func @multi_copy
// CHECK: scf.for
// CHECK: scf.for
func.func @multi_copy(%A: memref<4xi32>, %B: memref<4xi32>, %C: memref<4xi32>) {
  memref.copy %A, %B : memref<4xi32> to memref<4xi32>
  memref.copy %B, %C : memref<4xi32> to memref<4xi32>
  return
}