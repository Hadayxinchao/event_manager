require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

NUMBERS = Set.new(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
WEEK_DAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
hour_registrations = {}
week_days = {}
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislator_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_phone_number(phone_number)
  formed_number = ""
  phone_number.split("").each do |char|
    formed_number += char if NUMBERS.include?(char)
  end
  if formed_number.length < 10
    return "Bad Number"
  elsif formed_number.length == 10
    return formed_number
  elsif formed_number.length == 11 && formed_number[0] == "1"
    return formed_number[1..10]
  elsif formed_number.length == 11 && formed_number[0] != "1"
    return "Bad Number"
  else
    return "Bad Number"
  end
end

def get_hour_from_regdate(regdate)
  time = Time.strptime(regdate, "%m/%d/%Y %k:%M")
  hour = time.hour
end

def get_wday_from_regdate(regdate)
  time = Time.strptime(regdate, "%m/%d/%Y %k:%M")
  hour = time.wday
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])

  hour_registration = get_hour_from_regdate(row[:regdate])
  if hour_registrations.key?(hour_registration)
    hour_registrations[hour_registration] += 1
  else
    hour_registrations[hour_registration] = 1
  end

  week_day = get_wday_from_regdate(row[:regdate])
  if week_days.key?(week_day)
    week_days[week_day] += 1
  else
    week_days[week_day] = 1
  end

  legislators = legislator_by_zipcode(zipcode)  

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end
print "The Peak Registration Hours Are: "
hour_registrations.each { |key, value| print "#{key} " if value == hour_registrations.values.max }

print "\nThe Day Of The Week Is: "
week_days.each { |key, value| print "#{WEEK_DAYS[key]} " if value == week_days.values.max }
puts "\n"

