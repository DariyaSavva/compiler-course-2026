// RUN: mlir-opt -load-pass-plugin=%mlir_lib_dir//SavvaDariyaCopyToLoopPass_Savva_Dariya_FIIT1_MLIR%shlibext \
// RUN: --pass-pipeline="builtin.module(savva-copy-to-loop)" %s | FileCheck %s


// CHECK-LABEL: func.func @copy_1d

// CHECK: %[[C0:.*]] = arith.constant 0 : index
// CHECK: %[[C4:.*]] = arith.constant 4 : index
// CHECK: %[[C1:.*]] = arith.constant 1 : index

// CHECK: scf.for %[[I:.*]] = %[[C0]] to %[[C4]] step %[[C1]]

// CHECK: %[[VAL:.*]] = memref.load %A[%[[I]]] : memref<4xi32>
// CHECK: memref.store %[[VAL]], %B[%[[I]]] : memref<4xi32>

func.func @copy_1d(%A: memref<4xi32>, %B: memref<4xi32>) {
  memref.copy %A, %B : memref<4xi32> to memref<4xi32>
  return
}


// CHECK-LABEL: func.func @copy_2d

// CHECK: %[[C0:.*]] = arith.constant 0 : index
// CHECK: %[[C2:.*]] = arith.constant 2 : index
// CHECK: %[[C3:.*]] = arith.constant 3 : index
// CHECK: %[[C1:.*]] = arith.constant 1 : index

// CHECK: scf.for %[[I:.*]] = %[[C0]] to %[[C2]] step %[[C1]]
// CHECK:   scf.for %[[J:.*]] = %[[C0]] to %[[C3]] step %[[C1]]

// CHECK: %[[VAL:.*]] = memref.load %A[%[[I]], %[[J]]] : memref<2x3xi32>
// CHECK: memref.store %[[VAL]], %B[%[[I]], %[[J]]] : memref<2x3xi32>

func.func @copy_2d(%A: memref<2x3xi32>, %B: memref<2x3xi32>) {
  memref.copy %A, %B : memref<2x3xi32> to memref<2x3xi32>
  return
}


// CHECK-LABEL: func.func @copy_dynamic

// CHECK: %[[C0:.*]] = arith.constant 0 : index
// CHECK: %[[C1:.*]] = arith.constant 1 : index

// CHECK: %[[DIM:.*]] = memref.dim %A, %[[C0]] : memref<?xi32>

// CHECK: scf.for %[[I:.*]] = %[[C0]] to %[[DIM]] step %[[C1]]

// CHECK: %[[VAL:.*]] = memref.load %A[%[[I]]] : memref<?xi32>
// CHECK: memref.store %[[VAL]], %B[%[[I]]] : memref<?xi32>

func.func @copy_dynamic(%A: memref<?xi32>, %B: memref<?xi32>) {
  memref.copy %A, %B : memref<?xi32> to memref<?xi32>
  return
}


// CHECK-LABEL: func.func @no_copy
// CHECK-NOT: scf.for

func.func @no_copy(%A: memref<4xi32>) {
  %c0 = arith.constant 0 : index
  %0 = memref.load %A[%c0] : memref<4xi32>
  return
}


// CHECK-LABEL: func.func @multi_copy

// CHECK: scf.for %[[I1:.*]] = %[[C0:.*]] to %[[C4:.*]] step %[[C1:.*]]
// CHECK: memref.load %A[%[[I1]]]
// CHECK: memref.store {{.*}}, %B[%[[I1]]]

// CHECK: scf.for %[[I2:.*]] = %[[C0]] to %[[C4]] step %[[C1]]
// CHECK: memref.load %B[%[[I2]]]
// CHECK: memref.store {{.*}}, %C[%[[I2]]]

func.func @multi_copy(%A: memref<4xi32>,
                      %B: memref<4xi32>,
                      %C: memref<4xi32>) {
  memref.copy %A, %B : memref<4xi32> to memref<4xi32>
  memref.copy %B, %C : memref<4xi32> to memref<4xi32>
  return
}