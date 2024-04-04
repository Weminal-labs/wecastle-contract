module weather::game {
    use sui::event;
    use sui::object::{Self, UID};
    use std::string::{Self, String};
    use sui::tx_context::{Self, TxContext, sender};
    use weather::weather as weather_oracle;

    struct AdminCap has key {
        id: UID
    }

    struct CityWeather has drop, copy  {
        id: u32,
        city_name: String,
        country: String,
        temp: u32, 
        visibility: u16, 
        wind_speed: u16,
        wind_deg: String, 
        clouds: u8, 
        is_rain: bool,
        rain_fall: String
    }

    // fun init(ctx: &mut TxContext) {
    //    let admin_cap = AdminCap{
    //     id: object::sender(ctx)
    //    };
    //    transfer::public_transfer(admin_cap, id);

    // }

    // public entry fun create(id: u32, city_weather: &weather_oracle::WeatherOracle) {
    //     let wind: String = weather_oracle::city_weather_oracle_name(city_weather, id);
    // }

    public entry fun get_city_weather(city_id: u32, city_weather: &weather_oracle::WeatherOracle) {
        let city_weather = CityWeather {
            id: city_id,
            city_name: weather_oracle::city_weather_oracle_name(city_weather, city_id),
            country: weather_oracle::city_weather_oracle_country(city_weather, city_id),
            temp: weather_oracle::city_weather_oracle_temp(city_weather, city_id),
            visibility: weather_oracle::city_weather_oracle_visibility(city_weather, city_id),
            wind_speed: weather_oracle::city_weather_oracle_wind_speed(city_weather, city_id),
            wind_deg: weather_oracle::city_weather_oracle_wind_deg(city_weather, city_id),
            clouds: weather_oracle::city_weather_oracle_clouds(city_weather, city_id),
            is_rain: weather_oracle::city_weather_oracle_is_rain(city_weather, city_id),
            rain_fall: weather_oracle::city_weather_oracle_rain_fall(city_weather, city_id),
        };
        event::emit(city_weather);
    }
}

