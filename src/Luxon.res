module DateTime = {
  type iso8601String = string
  type timeinfo = {
    year: int,
    month: int,
    day: int,
    hour: int,
    minute: int,
    second: int,
    millisecond: int,
  }

  type datetime = {
    ts: int,
    c: timeinfo,
    o: int,
    isLuxonDateTime: bool,
  }

  type text = string
  type format = string
  @module("luxon") @scope("DateTime")
  external fromFormat: (text, format) => datetime = "fromFormat"

  @module("luxon") @scope("DateTime")
  external fromISO: iso8601String => datetime = "fromISO"

  @module("luxon") @scope("DateTime")
  external fromObject: 'obj => datetime = "fromObject"

  @module("luxon") @scope("DateTime")
  external fromJSDate: Js.Date.t => datetime = "fromJSDate"

  @module("luxon") @scope("DateTime")
  external local: unit => datetime = "local"

  @send external toJSDate: 'datetime => 'jsDate = "toJSDate"

  @send external toISODate: 'datetime => string = "toISODate"

  @send external toString: 'datetime => string = "toString"

  @send external setZone: (datetime, string) => datetime = "setZone"

  @send external minus: ('dateTimeModel, 'days) => datetime = "minus"

  @send external plus: ('dateTimeModel, 'days) => datetime = "plus"

  @send external toFormat: (datetime, string) => string = "toFormat"
}

module Custom = {
  let fromISOtoJsDate = date => date->DateTime.fromISO->DateTime.toJSDate

  let fromISOtoOnlyDate = date => date->DateTime.fromISO->DateTime.toFormat("yyyy-MM-dd")

  let fromObjecttoOnlyKoreanDate = date =>
    date->DateTime.fromObject->DateTime.toFormat(`yyyy년 M월 d일`)
}
