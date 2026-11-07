import Foundation

/// Kalan süreyi "H:MM" biçiminde döndürür; dakika aşağı yuvarlanır (floor).
/// 3:04:05 -> "3:04", 0:45:59 -> "0:45", 0:00:30 -> "0:00".
func formatRemaining(_ seconds: TimeInterval) -> String {
    let totalMinutes = max(0, Int((seconds / 60).rounded(.down)))
    let h = totalMinutes / 60
    let m = totalMinutes % 60
    return "\(h):" + (m < 10 ? "0\(m)" : "\(m)")
}
