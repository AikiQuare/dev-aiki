// RUN: circt-opt %s --convert-moore-to-core --verify-diagnostics | FileCheck %s

// CHECK-LABEL: hw.module @FuncArgsAndReturns(in 
// CHECK-SAME: %[[IN1:.*]] : i8, in
// CHECK-SAME: %[[IN2:.*]] : i32, in
// CHECK-SAME: %[[IN3:.*]] : i1, out res : i1) {
moore.module @FuncArgsAndReturns {
  %arg0 = moore.port In : !moore.byte
  %arg1 = moore.port In : !moore.int
  %arg2 = moore.port In : !moore.bit
  %res = moore.port Out : !moore.logic

  // CHECK: %[[EXT1:.*]] = comb.extract %[[IN1]] from 1 : (i8) -> i7
  // CHECK: %[[CONST1:.*]] = hw.constant 0 : i7
  // CHECK: %[[ICMP:.*]] = comb.icmp eq %[[EXT1]], %[[CONST1]] : i7
  // CHECK: %[[EXT2:.*]] = comb.extract %[[IN1]] from 0 : (i8) -> i1
  // CHECK: %[[CONST2:.*]] = hw.constant true
  // CHECK: %[[MUX:.*]] = comb.mux %[[ICMP]], %[[EXT2]], %[[CONST2]] : i1
  // CHECK: %[[OUT:.*]] = hw.bitcast %[[MUX]] : (i1) -> i1
  %0 = moore.conversion %arg0 : !moore.byte -> !moore.logic
  moore.mir.cassign %res, %0 : !moore.logic
  // CHECK: hw.output %[[OUT]] : i1
}

// CHECK-LABEL: hw.module @UnrealizedConversionCast(in 
// CHECK-SAME: %[[IN:.*]] : i1, out res : i8) {
moore.module @UnrealizedConversionCast {
  %arg0 = moore.port In : !moore.bit
  %res = moore.port Out : !moore.byte

  // CHECK: %[[CAT1:.*]] = comb.concat %[[IN]], %[[IN]] : i1, i1
  // CHECK: %[[CONST:.*]] = hw.constant 0 : i6
  // CHECK: %[[CAT2:.*]] = comb.concat %[[CONST]], %[[CAT1]] : i6, i2
  %1 = moore.mir.concat %arg0, %arg0 : (!moore.bit, !moore.bit) -> !moore.packed<range<bit, 1:0>>

  // CHECK: %[[OUT:.*]] = hw.bitcast %[[CAT2]] : (i8) -> i8
  %2 = moore.conversion %1 : !moore.packed<range<bit, 1:0>> -> !moore.byte
  moore.mir.cassign %res, %2 : !moore.byte
  // CHECK: hw.output %[[OUT]] : i8
}

// CHECK-LABEL: hw.module @Expressions(in
moore.module @Expressions {
  %arg0 = moore.port In : !moore.bit
  %arg1 = moore.port In : !moore.logic
  %arg2 = moore.port In : !moore.packed<range<bit, 5:0>>
  %arg3 = moore.port In : !moore.packed<range<bit<signed>, 4:0>>
  %arg4 = moore.port In : !moore.bit<signed>

  // CHECK-NEXT: %0 = comb.concat %arg0, %arg0 : i1, i1
  // CHECK-NEXT: %1 = comb.concat %arg1, %arg1 : i1, i1
  %0 = moore.mir.concat %arg0, %arg0 : (!moore.bit, !moore.bit) -> !moore.packed<range<bit, 1:0>>
  %1 = moore.mir.concat %arg1, %arg1 : (!moore.logic, !moore.logic) -> !moore.packed<range<logic, 1:0>>

  // CHECK-NEXT: %[[V0:.+]] = hw.constant 0 : i5
  // CHECK-NEXT: %[[V1:.+]] = comb.concat %[[V0]], %arg0 : i5, i1
  // CHECK-NEXT: comb.shl %arg2, %[[V1]] : i6
  // CHECK-NEXT: %[[V2:.+]] = comb.extract %arg2 from 5 : (i6) -> i1
  // CHECK-NEXT: %[[V3:.+]] = hw.constant false
  // CHECK-NEXT: %[[V4:.+]] = comb.icmp eq %[[V2]], %[[V3]] : i1
  // CHECK-NEXT: %[[V5:.+]] = comb.extract %arg2 from 0 : (i6) -> i5
  // CHECK-NEXT: %[[V6:.+]] = hw.constant -1 : i5
  // CHECK-NEXT: %[[V7:.+]] = comb.mux %[[V4]], %[[V5]], %[[V6]] : i5
  // CHECK-NEXT: comb.shl %arg3, %[[V7]] : i5
  %2 = moore.mir.shl %arg2, %arg0 : !moore.packed<range<bit, 5:0>>, !moore.bit
  %3 = moore.mir.shl arithmetic %arg3, %arg2 : !moore.packed<range<bit<signed>, 4:0>>, !moore.packed<range<bit, 5:0>>

  // CHECK-NEXT: %[[V8:.+]] = hw.constant 0 : i5
  // CHECK-NEXT: %[[V9:.+]] = comb.concat %[[V8]], %arg0 : i5, i1
  // CHECK-NEXT: comb.shru %arg2, %[[V9]] : i6
  // CHECK-NEXT: comb.shru %arg2, %arg2 : i6
  // CHECK-NEXT: %[[V10:.+]] = comb.extract %arg2 from 5 : (i6) -> i1
  // CHECK-NEXT: %[[V11:.+]] = hw.constant false
  // CHECK-NEXT: %[[V12:.+]] = comb.icmp eq %[[V10]], %[[V11]] : i1
  // CHECK-NEXT: %[[V13:.+]] = comb.extract %arg2 from 0 : (i6) -> i5
  // CHECK-NEXT: %[[V14:.+]] = hw.constant -1 : i5
  // CHECK-NEXT: %[[V15:.+]] = comb.mux %[[V12]], %[[V13]], %[[V14]] : i5
  // CHECK-NEXT: comb.shrs %arg3, %[[V15]] : i5
  %4 = moore.mir.shr %arg2, %arg0 : !moore.packed<range<bit, 5:0>>, !moore.bit
  %5 = moore.mir.shr arithmetic %arg2, %arg2 : !moore.packed<range<bit, 5:0>>, !moore.packed<range<bit, 5:0>>
  %6 = moore.mir.shr arithmetic %arg3, %arg2 : !moore.packed<range<bit<signed>, 4:0>>, !moore.packed<range<bit, 5:0>>

  // CHECK-NEXT: comb.add %arg0, %arg0 : i1
  // CHECK-NEXT: comb.sub %arg0, %arg0 : i1
  // CHECK-NEXT: comb.mul %arg0, %arg0 : i1
  // CHECK-NEXT: comb.divu %arg0, %arg0 : i1
  // CHECK-NEXT: comb.modu %arg0, %arg0 : i1
  // CHECK-NEXT: comb.and %arg0, %arg0 : i1
  // CHECK-NEXT: comb.or %arg0, %arg0 : i1
  // CHECK-NEXT: comb.xor %arg0, %arg0 : i1
  %7 = moore.add %arg0, %arg0 : !moore.bit
  %8 = moore.sub %arg0, %arg0 : !moore.bit
  %9 = moore.mul %arg0, %arg0 : !moore.bit
  %10 = moore.div %arg0, %arg0 : !moore.bit
  %12 = moore.mod %arg0, %arg0 : !moore.bit
  %13 = moore.and %arg0, %arg0 : !moore.bit
  %14 = moore.or %arg0, %arg0 : !moore.bit
  %15 = moore.xor %arg0, %arg0 : !moore.bit

  // CHECK-NEXT: comb.icmp ult %arg0, %arg0 : i1
  // CHECK-NEXT: comb.icmp ule %arg0, %arg0 : i1
  // CHECK-NEXT: comb.icmp ugt %arg0, %arg0 : i1
  // CHECK-NEXT: comb.icmp uge %arg0, %arg0 : i1
  %16 = moore.lt %arg0, %arg0 : !moore.bit -> !moore.bit
  %17 = moore.le %arg0, %arg0 : !moore.bit -> !moore.bit
  %18 = moore.gt %arg0, %arg0 : !moore.bit -> !moore.bit
  %19 = moore.ge %arg0, %arg0 : !moore.bit -> !moore.bit

  // CHECK-NEXT: comb.icmp slt %arg4, %arg4 : i1
  // CHECK-NEXT: comb.icmp sle %arg4, %arg4 : i1
  // CHECK-NEXT: comb.icmp sgt %arg4, %arg4 : i1
  // CHECK-NEXT: comb.icmp sge %arg4, %arg4 : i1
  %20 = moore.lt %arg4, %arg4 : !moore.bit<signed> -> !moore.bit
  %21 = moore.le %arg4, %arg4 : !moore.bit<signed> -> !moore.bit
  %22 = moore.gt %arg4, %arg4 : !moore.bit<signed> -> !moore.bit
  %23 = moore.ge %arg4, %arg4 : !moore.bit<signed> -> !moore.bit

  // CHECK-NEXT: comb.icmp eq %arg0, %arg0 : i1
  // CHECK-NEXT: comb.icmp ne %arg0, %arg0 : i1
  // CHECK-NEXT: comb.icmp ceq %arg0, %arg0 : i1
  // CHECK-NEXT: comb.icmp cne %arg0, %arg0 : i1
  // CHECK-NEXT: comb.icmp weq %arg0, %arg0 : i1
  // CHECK-NEXT: comb.icmp wne %arg0, %arg0 : i1
  %24 = moore.eq %arg0, %arg0 : !moore.bit -> !moore.bit
  %25 = moore.ne %arg0, %arg0 : !moore.bit -> !moore.bit
  %26 = moore.case_eq %arg0, %arg0 : !moore.bit 
  %27 = moore.case_ne %arg0, %arg0 : !moore.bit
  %28 = moore.wildcard_eq %arg0, %arg0 : !moore.bit -> !moore.bit
  %29 = moore.wildcard_ne %arg0, %arg0 : !moore.bit -> !moore.bit

  // CHECK-NEXT: comb.extract %arg2 from 2 : (i6) -> i2
  // CHECK-NEXT: comb.extract %arg2 from 2 : (i6) -> i1
  %30 = moore.mir.extract %arg2 from 2 : (!moore.packed<range<bit, 5:0>>) -> !moore.packed<range<bit, 3:2>>
  %31 = moore.mir.extract %arg2 from 2 : (!moore.packed<range<bit, 5:0>>) -> !moore.bit

  // CHECK-NEXT: hw.constant 12 : i32
  // CHECK-NEXT: hw.constant 3 : i6
  %32 = moore.constant 12 : !moore.int
  %33 = moore.constant 3 : !moore.packed<range<bit, 5:0>>

  // CHECK-NEXT: hw.output
}
