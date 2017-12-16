require 'pm_25/version'

require 'nokogiri'
require 'json'
require 'open-uri'
require 'rest_client'
require 'time-lord'

module PM25
  # Yes, pm25.in requires a token but uses http!
  API_base = 'http://www.pm25.in/api/querys/'

  module_function

  # Use environment variable or the value
  # from config at the current directory.
  # If all failed, use the default value.
  #
  # @param [String] constant_name
  # @param [String] default_value
  # @return [String]
  def get_config(constant_name, default_value=nil)
    if ENV[constant_name]
      ENV[constant_name]
    elsif File.exist?('config.json')
      open('config.json') do |f|
        JSON.parse(f.read)[constant_name]
      end
    else
      default_value
    end
  end

  # Use environment variable PM25_IN_TOKEN
  # or the value from config at the current directory.
  # If all failed, use the test token.
  # You can apply a token at pm25.in:
  # http://www.pm25.in/api_doc
  #
  # @return [String] token
  def get_token
    test_token= '5j1znBVAsnSf5xQyNQyq'
    get_config('PM25_IN_TOKEN', test_token)
  end

  # Use environment variable PM25_IN_CITY
  # or the value from config at the current directory.
  #
  # @return [String] city
  def get_default_city
    get_config('PM25_IN_CITY')
  end

  # @param [String] interface of api
  # @param [Hash] params (additional) options
  # @return [Hash] result
  # @return [Fixnum] error code
  # TODO pm25.in tends to 502, need to email complaints and handle this.
  def access_api(interface, params={})
    params[:token] ||= get_token
    res = RestClient.get(API_base + interface, {params: params})
    if res.code == 200
      JSON.parse res.body
    else
      res.code
    end
  end


  # Get PM 2.5 info of all stations in the specified city.
  # API frequency limit: 500 per hour.
  #
  # @param [String] city You can use
  # - Chinese (e.g. 广州)
  # - area code (e.g. 020)
  # - Pinyin (e.g. guangzhou)
  # If there is ambiguity in Pinyin, use `shi` as postfix, for example:
  # 泰州 is taizhoushi, and 台州 is taizhou.
  # For more information, see http://www.pm25.in/
  # @return [Array<Hash>] an array of all stations
  # Every station includes:
  # * aqi (according to CN standard)
  # * area
  # * pm2_5
  # * pm2_5_24h (moving average)
  # * position_name (station name)
  # * primary_pollutant
  # * quality (优、良、轻度污染、中度污染、重度污染、严重污染 according to CN standard)
  # * station_code
  # * time_point (publish time of air condition)
  #
  # Example:
  #
  #   pm25('zhuhai')
  #
  # [
  #     {
  #         "aqi"=> 82,
  #         "area"=> "珠海",
  #         "pm2_5"=> 31,
  #         "pm2_5_24h"=> 60,
  #         "position_name"=> "吉大",
  #         "primary_pollutant"=> "颗粒物(PM2.5)",
  #         "quality"=> "良",
  #         "station_code"=> "1367A",
  #         "time_point"=> "2013-03-07T19:00:00Z"
  #     },
  #     ...
  #     ...
  #     ...
  #     {
  #         "aqi"=> 108,
  #         "area"=> "珠海",
  #         "pm2_5"=> 0,
  #         "pm2_5_24h"=> 53,
  #         "position_name"=> "斗门",
  #         "primary_pollutant"=> "臭氧8小时",
  #         "quality"=> "轻度污染",
  #         "station_code"=> "1370A",
  #         "time_point"=> "2013-03-07T19:00:00Z"
  #     },
  #     {
  #         "aqi"=> 99,
  #         "area"=> "珠海",
  #         "pm2_5"=> 39,
  #         "pm2_5_24h"=> 67,
  #         "position_name"=> null,
  #         "primary_pollutant"=> null,
  #         "quality"=> "良",
  #         "station_code"=> null,
  #         "time_point"=> "2013-03-07T19:00:00Z"
  #     }
  # ]
  def pm25(city=get_default_city, token=nil)
    access_api('pm2_5.json', city: city, token: token)
  end

  # Get a list of cites providing PM 2.5 data.
  # API frequency limit: 10 per hour.
  # @param [String] token
  # @return [Array] city list
  # @return [Fixnum] error code
  def available_cities(token=get_token)
    res = RestClient.get 'http://www.pm25.in/api/querys.json', {params: {token: token}}
    if res.code == 200
      JSON.parse(res.body)['cities']
    else
      res.code
    end
  end

  # Get PM 2.5 data for all cities.
  # API frequency limit: 5 per hour.
  # @param [String] token
  # @return [Hash]
  # @return [Fixnum] error code
  def all_cities(token=nil)
    access_api('all_cities.json', token: token)
  end

  # Get average data for all cities. (Cities are sorted by AQI.)
  # API frequency limit: 15 per hour.
  # @param [String] token
  # @return [Hash]
  # @return [Fixnum] error code
  def aqi_ranking(token=nil)
    access_api('aqi_ranking.json', token: token)
  end


  # Get PM 2.5 from bing.com
  # @param [String] city only accept Chinese
  # @return [Fixnum] PM 25 value
  def bing_pm25(city)
    city = URI.encode(city)
    bing_url = "http://cn.bing.com/search?q=#{city}+pm2.5"
    html = Nokogiri.parse(open(bing_url).read)
    html.at('#msn_pm25rt .b_xlText').content.to_i
  end

  # Get PM 2.5 value for city.
  # Fallback to bing.com.
  # Return PM 2.5 value only.
  # @param [String] city only accept Chinese
  # @param [String] token
  # @return [Fixnum] average PM 2.5 value for stations
  def just_pm25(city=get_default_city, token=nil)
    result = pm25(city, token)
    # error on pm25.in api
    if result.is_a? Fixnum
      bing_pm25(city)
    elsif result.include? 'error'
      bing_pm25(city)
    else
      publish_time = Time.parse(result[-1]['time_point'])
      # Data on pm25.in is too old.
      # According to GB 3095-2013, PM 2.5 should have hourly
      # average values for at least 20 hours a day.
      # http://hbj.shanghang.gov.cn/hjjc/gldt/201411/P020141110361645902554.pdf
      if Time.now - publish_time > 2.hours
        bing_pm25(city)
      else
        result[-1]['pm2_5']
      end
    end
  end


  # Get AQI category, meaning and action according to US standard.
  # @param [Fixnum]
  # @return [Hash{Symbol: Fixnum, Symbol: String, Symbol: String, Symbol: String}]
  def pm25_level(pm25)
    if pm25 <= 12
      aqi_category = 'Good'
      aqi_meaning = 'Air quality is considered satisfactory, and air pollution poses little or no risk.'
      aqi_action = 'None'
    elsif pm25 <= 35.4
      aqi_category = 'Moderate'
      aqi_meaning = 'Air quality is acceptable; however, for some pollutants there may be a moderate health concern for a very small number of people who are unusually sensitive to air pollution.'
      aqi_action = 'Unusually sensitive people should consider reducing prolonged or heavy exertion.'
    elsif pm25 <= 55.4
      aqi_category = 'Unhealthy for sensitive Groups'
      aqi_meaning = 'Members of sensitive groups may experience health effects. The general public is not likely to be affected.'
      aqi_action = 'People with heart or lung disease, children and older adults should reduce prolonged or heavy exertion'
    elsif pm25 <= 150.4
      aqi_category = 'Unhealthy'
      aqi_meaning = 'Everyone may begin to experience health effects; members of sensitive groups may experience more serious health effects.'
      aqi_action = 'People with heart or lung disease, children and older adults should avoid prolonged or heavy exertion. Everyone else should reduce prolonged or heavy exertion.'
    elsif pm25 <= 250.4
      aqi_category = 'Very Unhealthy'
      aqi_meaning = 'Health warnings of emergency conditions. The entire population is more likely to be affected.'
      aqi_action = 'People with heart or lung disease, children and older adults should avoid all physical activity outdoors. Everyone else should avoid prolonged or heavy exertion.'
    else
      aqi_category = 'Hazardous'
      aqi_meaning = 'Health alert: everyone may experience more serious health effects'
      aqi_action = 'Avoid all physical activity outdoors.'
    end
  {pm25: pm25,
   category: aqi_category,
   meaning: aqi_meaning,
   action: aqi_action}
  end
end
