# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :reservation do
    begin "2013-11-08 23:55:48"
    end "2013-11-08 23:55:48"
    status "MyString"
    user nil
    place nil
  end
end
