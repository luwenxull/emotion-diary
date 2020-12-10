//
//  Group.swift
//  WhatHappend
//
//  Created by 陆雯旭 on 2020/11/24.
//

import Foundation
import Combine

enum WhatEmotion: Int, Codable {
  case happy, unhappy
}

struct WhatTime: Hashable, Codable {
  var date: Date = Date()
  var description: String = ""
}

typealias SimpleWhatGroup = (name: String, emotion: WhatEmotion)

final class WhatGroup: Identifiable, ObservableObject {
  let uuid: UUID
  @Published var name: String
  @Published var emotion: WhatEmotion
  @Published var times: [WhatTime]
  
  // 按月分组数据
  private var _datesGroupedByMonth: [String: [Date]]?
  var datesGroupedByMonth: [String: [Date]] {
    if _datesGroupedByMonth == nil {
      var all = [String: [Date]]()
      for time in times {
        let month = time.date.month
        if all[month] == nil {
          all[month] = []
        }
        all[month]?.append(time.date)
      }
      _datesGroupedByMonth = all
    }
    return _datesGroupedByMonth!
  }
  
  // 按年分组的数据
  private var _countGroupedByYear: [Int: Int]?
  var countGroupedByYear: [Int: Int] {
    if _countGroupedByYear == nil {
      var all = [Int: Int]()
      for time in times {
        let year = time.date.year
        if all[year] == nil {
          all[year] = 0
        }
        all[year]! += 1
      }
      _countGroupedByYear = all
    }
    return _countGroupedByYear!
  }
  
  func addRecord(_ time: WhatTime) -> Void {
    times.append(time)
    _countGroupedByYear = nil
    WhatManager.current.saveAsJson(updateCounts: true, updateNames: false)
  }
  
  func removeRecord(_ index: Int) -> Void {
    times.remove(at: index)
    _countGroupedByYear = nil
    WhatManager.current.saveAsJson(updateCounts: true, updateNames: false)
  }
  
  func updateFrom(_ from: SimpleWhatGroup) {
    name = from.name
    emotion = from.emotion
    WhatManager.current.saveAsJson(updateCounts: false, updateNames: true)
  }
  
  init(name: String, emotion: WhatEmotion, times: [WhatTime], uuid: UUID = UUID()) {
    self.name = name
    self.emotion = emotion
    self.times = times
    self.uuid = uuid
  }
}

extension WhatGroup: Codable {
  enum CodingKeys: CodingKey {
    case name, emotion, times, uuid
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
    try container.encode(emotion, forKey: .emotion)
    try container.encode(times, forKey: .times)
    try container.encode(uuid, forKey: .uuid)
  }
  
   convenience init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let name = try values.decode(String.self, forKey: .name)
    let emotion = try values.decode(WhatEmotion.self, forKey: .emotion)
    let times = try values.decode(Array<WhatTime>.self, forKey: .times)
    let uuid = try values.decode(UUID.self, forKey: .uuid)
    self.init(name: name, emotion: emotion, times: times, uuid: uuid)
  }
}

extension Date {
  var year: Int {
    let components = Calendar.current.dateComponents([.year], from: self)
    return components.year!
  }
  
  var month: String {
    let components = Calendar.current.dateComponents([.year, .month], from: self)
    let month = String(components.month!)
    return String(components.year!) + "-" + (month.count == 2 ? month : "0\(month)")
  }
  
  var day: Int {
    let components = Calendar.current.dateComponents([.day], from: self)
    return components.day!
  }
}

extension Calendar {
  static func lastDayOfMonth(_ date: Date) -> Date {
    let end = Calendar.current.dateInterval(of: .month, for: date)?.end
    return Calendar.current.date(byAdding: .second, value: -1, to: end!)!
  }
}
