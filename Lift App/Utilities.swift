//
//  Utilities.swift
//  Lift App
//
//  Created by Aiden Buter on 11/6/25.
//


// =========================
// File: Utilities.swift
// =========================

import Foundation

/// 1RM prediction (Epley formula)
func predictOneRepMaxEpley(weightlbs: Double, reps: Int) -> Double {
    guard reps > 0 else { return weightlbs }
    return weightlbs * (1.0 + Double(reps) / 30.0)
}

/// Convert kg to lbs and vice versa helpers (small convenience)
extension Double {
    var kgToLbs: Double { return self * 2.20462 }
    var lbsToKg: Double { return self / 2.20462 }
}
