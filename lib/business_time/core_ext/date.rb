# Add workday and weekday concepts to the Date class
class Date
  include BusinessTime::TimeExtensions
  type :month, "() -> %integer m {{ m >= 1 && m <= 12 }}", modular: true, pure: true
  type :year, "() -> %integer y", modular: true, pure: true
  type :yday, "() -> %integer d {{ d >= 1 && d <= 366 }}", modular: true, pure: true
  type BusinessTime::Config, 'self.fiscal_month_offset', "() -> %integer fm {{ fm >= 1 && fm <= 12 }}", modular: true, pure: true
  type Time, 'self.days_in_month', '(%integer m, %integer y) -> %integer d {{ d >= 28 && d <= 31 }}', modular: true, pure: true
  
  def business_days_until(to_date, inclusive = false)
    business_dates_until(to_date, inclusive).size
  end

  def business_dates_until(to_date, inclusive = false)
    if inclusive
      (self..to_date).select(&:workday?)
    else
      (self...to_date).select(&:workday?)
    end
  end

  # Adapted from:
  # https://github.com/activewarehouse/activewarehouse/blob/master/lib/active_warehouse/core_ext/time/calculations.rb

  type '() -> %integer w {{ w >= 1 && w <= 52 }}', verify: :later
  def week
    cyw = ((yday - 1) / 7) + 1
    cyw = 52 if cyw == 53
    cyw
  end

  type '() -> %integer q {{ q >= 1 && q <= 4 }}', verify: :later
  def quarter
    ((month - 1) / 3) + 1
  end

  type '() -> %integer i {{ i >= 1 && i <=12 }}', verify: :later
  def fiscal_month_offset
    BusinessTime::Config.fiscal_month_offset
  end

  type '() -> %integer w {{ w >= 1 && w <= 52 }}', verify: :later
  def fiscal_year_week
    fyw = ((fiscal_year_yday - 1) / 7) + 1
    fyw = 52 if fyw == 53
    fyw
  end

  type '() -> %integer fym {{ fym >=1 && fym <= 12 }}', verify: :later, assumes: true
  def fiscal_year_month
    shifted_month = month - (fiscal_month_offset - 1)
    shifted_month += 12 if shifted_month <= 0
    shifted_month
  end
  
  type '() -> %integer fyq {{ fyq >=1 && fyq <= 4 }}', verify: :later, assumes: true
  def fiscal_year_quarter
    ((fiscal_year_month - 1) / 3) + 1
  end

  type '() -> %integer i {{ if (month >= fiscal_month_offset) then i == year + 1 end }}', verify: :later, assumes:true
  def fiscal_year
    month >= fiscal_month_offset ? year + 1 : year
  end

  type :fiscal_year_yday, '() -> %integer i {{ i >= 1 && i <= 366 }}', verify: :attempt, assumes: true, modular: true, pure: true
  def fiscal_year_yday
    var_type :offset_days, "%integer"
    offset_days = 0
    #1.upto(fiscal_month_offset - 1) { |m| offset_days += ::Time.days_in_month(m, year) }
    # ::Time not currently supported by RDL type checker. Changing to Time. Effectively the same
    1.upto(fiscal_month_offset - 1) { |m| offset_days += Time.days_in_month(m, year) }
    shifted_year_day = yday - offset_days
    shifted_year_day += 365 if shifted_year_day <= 0
    shifted_year_day
  end
end
