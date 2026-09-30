import ballerina/time;

// ============================================================
// timestamps.bal — Minimal ISO-8601 ("...Z") to epoch-seconds
// conversion.
//
// Every service stamps records with time:utcToString(time:utcNow()),
// which always yields the fixed-width form
// YYYY-MM-DDThh:mm:ss.SSSZ. Delivery performance reports need the
// gap between two such stamps, so the conversion is done with
// plain integer maths (Howard Hinnant's days-from-civil algorithm)
// rather than pulling in format parsing. Returns () for anything
// that is not a well-formed stamp, so callers can simply skip
// unusable records instead of failing the whole report.
// ============================================================

const int SECONDS_PER_DAY = 86400;

// Floor division: Ballerina's / truncates towards zero.
function floorDiv(int dividend, int divisor) returns int {
    int quotient = dividend / divisor;
    int remainder = dividend % divisor;
    if remainder != 0 && ((remainder < 0) != (divisor < 0)) {
        return quotient - 1;
    }
    return quotient;
}

// Days between 1970-01-01 and the given proleptic Gregorian date.
function daysFromCivil(int year, int month, int day) returns int {
    int adjustedYear = month <= 2 ? year - 1 : year;
    int era = floorDiv(adjustedYear, 400);
    int yearOfEra = adjustedYear - era * 400;
    int shiftedMonth = month + (month > 2 ? -3 : 9);
    int dayOfYear = floorDiv(153 * shiftedMonth + 2, 5) + day - 1;
    int dayOfEra = yearOfEra * 365 + floorDiv(yearOfEra, 4) - floorDiv(yearOfEra, 100) + dayOfYear;
    return era * 146097 + dayOfEra - 719468;
}

// Reads a fixed-width run of digits, or -1 if it is not a number.
function digitAt(string value, int offset, int length) returns int {
    if offset < 0 || offset + length > value.length() {
        return -1;
    }
    int|error parsed = int:fromString(value.substring(offset, offset + length));
    if parsed is error {
        return -1;
    }
    return parsed;
}

function parseUtcSeconds(string timestamp) returns int? {
    if timestamp.length() < 19 {
        return;
    }
    int year = digitAt(timestamp, 0, 4);
    int month = digitAt(timestamp, 5, 2);
    int day = digitAt(timestamp, 8, 2);
    int hour = digitAt(timestamp, 11, 2);
    int minute = digitAt(timestamp, 14, 2);
    int second = digitAt(timestamp, 17, 2);
    if year < 0 || month < 1 || month > 12 || day < 1 || day > 31 || hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 60 {
        return;
    }
    return daysFromCivil(year, month, day) * SECONDS_PER_DAY + hour * 3600 + minute * 60 + second;
}

function currentUtcSeconds() returns int {
    return parseUtcSeconds(time:utcToString(time:utcNow())) ?: 0;
}

// UTC hour of day (0-23) an order was placed; used for the
// peak-meal-time breakdown.
function utcHourOfDay(string timestamp) returns int? {
    int? epoch = parseUtcSeconds(timestamp);
    if epoch is () {
        return;
    }
    return (epoch / 3600) % 24;
}

// Minutes past midnight (0-1439) for a "HH:MM" wall-clock string.
function minutesOfDay(string hhmm) returns int? {
    if hhmm.length() < 5 {
        return;
    }
    int hours = digitAt(hhmm, 0, 2);
    int minutes = digitAt(hhmm, 3, 2);
    if hours < 0 || hours > 23 || minutes < 0 || minutes > 59 {
        return;
    }
    return hours * 60 + minutes;
}
