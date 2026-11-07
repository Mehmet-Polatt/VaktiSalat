import WidgetKit
import SwiftUI

private let appGroup = "group.com.mehmetpolat.vaktisalat"
private let dataKey = "prayer_days"
private let names = ["İmsak", "Güneş", "Öğle", "İkindi", "Akşam", "Yatsı"]
private let keys = ["imsak", "gunes", "ogle", "ikindi", "aksam", "yatsi"]

struct PrayerPoint {
    let name: String
    let date: Date
}

struct PrayerEntry: TimelineEntry {
    let date: Date
    let current: PrayerPoint?
    let next: PrayerPoint?
    let hasData: Bool
    var remaining: String = ""
}

private func loadPoints() -> [PrayerPoint] {
    guard let defaults = UserDefaults(suiteName: appGroup),
          let json = defaults.string(forKey: dataKey),
          let data = json.data(using: .utf8),
          let days = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { return [] }
    var points: [PrayerPoint] = []
    for day in days {
        guard let times = day["times"] as? [String: Any] else { continue }
        for (i, k) in keys.enumerated() {
            if let secs = (times[k] as? NSNumber)?.doubleValue {
                points.append(PrayerPoint(name: names[i], date: Date(timeIntervalSince1970: secs)))
            }
        }
    }
    return points.sorted { $0.date < $1.date }
}

private let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "tr_TR")
    f.timeZone = TimeZone(identifier: "Europe/Istanbul")
    f.dateFormat = "HH:mm"
    return f
}()

private func hm(_ d: Date) -> String { timeFormatter.string(from: d) }

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry {
        let now = Date()
        return PrayerEntry(
            date: now,
            current: PrayerPoint(name: "İkindi", date: now.addingTimeInterval(-3600)),
            next: PrayerPoint(name: "Akşam", date: now.addingTimeInterval(5400)),
            hasData: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(makeEntries(from: Date()).first ?? placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        let entries = makeEntries(from: Date())
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func makeEntries(from now: Date) -> [PrayerEntry] {
        let points = loadPoints()
        guard let firstFutureIdx = points.firstIndex(where: { $0.date > now }) else {
            return [PrayerEntry(date: now, current: nil, next: nil, hasData: false)]
        }
        // Şu an + sonraki 12 saat için dakika sınırları + her vakit anı.
        let horizon = now.addingTimeInterval(12 * 3600)
        var times: Set<TimeInterval> = [now.timeIntervalSince1970]
        var t = (floor(now.timeIntervalSince1970 / 60) + 1) * 60
        while t <= horizon.timeIntervalSince1970 {
            times.insert(t)
            t += 60
        }
        for p in points[firstFutureIdx...] where p.date <= horizon {
            times.insert(p.date.timeIntervalSince1970)
        }
        var entries: [PrayerEntry] = []
        var idx = firstFutureIdx
        for ts in times.sorted() {
            let d = Date(timeIntervalSince1970: ts)
            while idx < points.count && points[idx].date <= d { idx += 1 }
            if idx >= points.count {
                // Veri bitti: "Uygulamayı açın" göster.
                entries.append(PrayerEntry(date: d, current: nil, next: nil, hasData: false))
                break
            }
            let next = points[idx]
            let current: PrayerPoint? = idx > 0 ? points[idx - 1] : nil
            // Ardışık iki vakit arasında 14 saatten fazla boşluk varsa arada veri eksiktir;
            // süre uydurmak yerine "veri yok" durumunu göster.
            if let c = current, next.date.timeIntervalSince(c.date) > 14 * 3600 {
                entries.append(PrayerEntry(date: d, current: nil, next: nil, hasData: false))
                continue
            }
            // Giriş, d ile d+60 sn arasını temsil eder; o aralıktaki aşağı yuvarlanmış değeri göster.
            entries.append(PrayerEntry(date: d, current: current, next: next, hasData: true,
                                       remaining: formatRemaining(next.date.timeIntervalSince(d) - 1)))
        }
        return entries
    }
}

private let gold = Color(red: 0.83, green: 0.69, blue: 0.22)

struct PrayerWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: PrayerEntry

    var body: some View {
        switch family {
        case .accessoryInline: inline
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        default: small
        }
    }

    @ViewBuilder var inline: some View {
        if let n = entry.next {
            Text("\(n.name) \(hm(n.date))")
        } else {
            Text("Uygulamayı açın")
        }
    }

    @ViewBuilder var circular: some View {
        if let n = entry.next {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text(n.name)
                        .font(.system(size: 12, weight: .medium))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text(entry.remaining)
                        .font(.system(size: 19, weight: .semibold))
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .padding(.horizontal, 2)
                .widgetAccentable()
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Text("Aç").font(.system(size: 15, weight: .semibold))
            }
        }
    }

    @ViewBuilder var rectangular: some View {
        if let n = entry.next {
            VStack(alignment: .leading, spacing: 2) {
                Text(n.name).font(.headline).widgetAccentable()
                Text(entry.remaining)
                    .font(.system(size: 24, weight: .semibold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text("Uygulamayı açın").font(.headline)
        }
    }

    @ViewBuilder var small: some View {
        if let n = entry.next {
            VStack(alignment: .leading, spacing: 4) {
                Text("TOKAT").font(.system(size: 10, weight: .bold)).tracking(2)
                    .foregroundStyle(gold.opacity(0.8))
                Spacer(minLength: 0)
                Text(n.name).font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(red: 0.91, green: 0.82, blue: 0.54))
                Text(hm(n.date)).font(.system(size: 17, weight: .bold)).foregroundStyle(gold)
                Text(entry.remaining)
                    .font(.system(size: 15)).monospacedDigit()
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else {
            Text("Uygulamayı açın").foregroundStyle(.white)
        }
    }

    private var progressValue: Double {
        guard let c = entry.current, let n = entry.next else { return 0 }
        let total = n.date.timeIntervalSince(c.date)
        guard total > 0 else { return 0 }
        return min(max(entry.date.timeIntervalSince(c.date) / total, 0), 1)
    }
}

struct PrayerWidget: Widget {
    let kind = "PrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PrayerWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [Color(red: 0.04, green: 0.06, blue: 0.13),
                                            Color(red: 0.09, green: 0.11, blue: 0.23)],
                                   startPoint: .top, endPoint: .bottom)
                }
        }
        .configurationDisplayName("Vakt-i Salât")
        .description("Sıradaki namaz vaktini ve kalan süreyi gösterir.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline, .systemSmall])
    }
}

@main
struct PrayerWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrayerWidget()
    }
}
