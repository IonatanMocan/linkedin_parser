require 'pry'
require 'watir'
require 'nokogiri'
require 'json'
require 'date'
require 'time'
require 'io/console'
require 'csv'

class PersonFinder
  BASE_URL = 'https://www.linkedin.com/'.freeze

  def execute
    define_credentials
    open_browser
    authenticate
    search_and_export

    @browser.close
  end

  private

  def define_credentials
    @login = "your_linkedin_login"
    @password = "your_linkedin_password"
  end

  def open_browser
    @browser = Watir::Browser.new
    @browser.goto(BASE_URL)
    sleep 2
  end

  def authenticate
    @browser.text_fields(class: "input__field--with-label")[0].set(@login)
    @browser.text_fields(class: "input__field--with-label")[1].set(@password)
    @browser.send_keys:enter
    sleep 7
  end

  def search_and_export
    people_list = CSV.parse(File.read("list_of_names_you_want_to_find.csv"), headers: true)
    people_names = people_list.by_col["name"]

    people_list.each do |person|
      @browser.text_field(class: "search-global-typeahead__input").set(person["name"])
      sleep 1
      @browser.send_keys:enter
      sleep 2

      binding.pry

      if @browser.h3(text: "Showing 1 result").present? ||
         @browser.lis(class: "search-result").size == 1
        profile_link = @browser.div(class: "search-result__info").link.href

        CSV.open("search_result.csv", "a") do |csv|
          csv << [person["name"], "FOUND", profile_link, @browser.url]
        end
      elsif @browser.lis(class: "search-result").size > 1 && special_case?(person)
        CSV.open("search_result.csv", "a") do |csv|
          csv << [person["name"], "special case", @browser.url]
        end
      else
        CSV.open("search_result.csv", "a") do |csv|
          csv << [person["name"], "-"]
        end
      end
    end
  end

  def special_case?(person)
    names_list = []
    
    @browser.spans(class: "name").each do |item|
      names_list << item.text
    end
    
    if names_list.count(person["name"]) == 1
      return true
    elsif names_list.count(person["name"]) == 0 &&
          !names_list.grep(/^#{person["name"]}/).empty?
      return true
    else
      return false
    end
  end
end

finding_process = PersonFinder.new
finding_process.execute
