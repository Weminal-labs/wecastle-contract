module game::game {
    use sui::event;
    use std::string::{Self, String};
    use sui::object::{Self, UID, ID};
    use sui::url::{Self, Url};
    use sui::transfer;
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use std::option::{Self, Option};
    use sui::package;
    use sui::dynamic_object_field as dof;
    use game::weather as weather_oracle;
    use std::ascii;
    // use sui::transfer_policy::{
    //         Self as policy,
    //         TransferPolicy,
    //         TransferPolicyCap,
    //         TransferRequest
    //     };
    use game::witness_rule;
    use game::royalty_rule;
    use game::kiosk_lock_rule;
    const NOT_ENOUGH_RESOURCES: u64 = 1;
    const MAX_LEVEL: u64 = 2;
    const NOT_A_CORBA_PLAYER: u64 = 3;
    const INVALID_HERO_TYPE: u64 = 4;

    const WARRIOR: u16 = 0;
    const ACHER: u16 = 1;
    const PAWN: u16 = 2;

    const PLAYER_INIT_GOLD: u32 = 100;
    const PLAYER_INIT_WOOD: u32 = 100;
    const PLAYER_INIT_MEAT: u32 = 100;
    const PLAYER_INIT_MAX_EXP: u32 = 5;

    const WARRIOR_MEAT: u32 = 40;
    const WARRIOR_WOOD: u32 =15;
    const WARRIOR_GOLD: u32 = 20;

    const ACHER_MEAT: u32 = 30;
    const ACHER_WOOD: u32 = 30;
    const ACHER_GOLD: u32 = 30;

    const PAWN_MEAT: u32 = 20;
    const PAWN_WOOD: u32 = 20;
    const PAWN_GOLD: u32 = 15;

    //admin 
    public struct AdminCap has key, store {
        id: UID
    }

    public struct OwnerCap has key, store {
        id: UID
    }

    public struct CorbaGameFi has key {
        id: UID,
        version: String,
        description: String
        //dof players
    }

    public struct CorbaPlayer has key, store {
        id: UID,
        level: u16,
        exp: u32,
        max_exp: u32,
        gold: u32,
        wood: u32,
        meat: u32
    }


    public struct LoadPlayerEvent has copy, drop {
        id: ID,
        level: u16,
        exp: u32,
        max_exp: u32,
        gold: u32,
        wood: u32,
        meat: u32
    }

    public struct Hero has key, store {
        id: UID,
        type_hero: u16,
        health: u16,
        max_health: u16, 
        damage: u16,
        speed: u16,
        level: u16,
        exp: u16,
        max_exp: u16,
        location_x: u16,
        location_y: u16,
        name: String,
        description: String,
        url: Url
    }

    public struct NewHeroEvent has copy, drop {
        id: ID,
        hero_id: ID,
        owner: address
    }

    public struct CityWeatherEvent has drop, copy  {
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
    public struct GAME has drop {}
    public struct Rule has drop {}

    fun init(otw: GAME, ctx: &mut TxContext) 
    {
        //hero policy
        let publisher = package::claim<GAME>(otw, ctx);
        // let (mut transfer_policy, cap) : (policy::TransferPolicy<Hero>, policy::TransferPolicyCap<Hero>) = policy::new<Hero>(&publisher, ctx);
        // royalty_rule::add<Hero>(&mut transfer_policy, &cap, 1000, 1000000);
        // royalty_rule::pay<Hero>(&mut transfer_policy, &cap, 1000, 1000000);
        // witness_rule::add<Hero, Rule>(&mut transfer_policy, &cap);
        //policy::new_request<Hero>(item: object::ID, paid: u64, from: object::ID): transfer_policy::TransferRequest<T>

        let admin_cap = AdminCap {
            id: object::new(ctx)
        };
        transfer::share_object(CorbaGameFi {
            id: object::new(ctx),
            version: string::utf8(b"1.0"),
            description: string::utf8(b"Corba game")
        });
        // dof::add(&mut game_pool.id, string::utf8(b"transfer_policy"), transfer_policy);
        // dof::add(&mut game_pool.id, string::utf8(b"transfer_policy_cap"), cap);
        transfer::public_transfer(admin_cap, @0x8d9f68271c525e6a35d75bc7afb552db1bf2f44bb65e860b356e08187cb9fa3d);
        transfer::public_transfer(publisher, @0x8d9f68271c525e6a35d75bc7afb552db1bf2f44bb65e860b356e08187cb9fa3d);
    }

    public fun new_player(
        corbaGameFi: &mut CorbaGameFi, 
        ctx: &mut TxContext
    ) {
        let owner_cap = OwnerCap {
            id: object::new(ctx)
        };
        let player:  CorbaPlayer = CorbaPlayer {
            id: object::new(ctx),
            level: 1,
            exp: 0,
            max_exp: PLAYER_INIT_MAX_EXP,
            gold: PLAYER_INIT_GOLD,
            wood: PLAYER_INIT_WOOD,
            meat: PLAYER_INIT_MEAT
        };
        event::emit(LoadPlayerEvent {
            id: object::uid_to_inner(&player.id),
            level: 1,
            exp: 0,
            max_exp: PLAYER_INIT_MAX_EXP,
            gold: PLAYER_INIT_GOLD,
            wood: PLAYER_INIT_WOOD,
            meat: PLAYER_INIT_MEAT
        });
        dof::add(
            &mut corbaGameFi.id, 
            object::id_from_address(tx_context::sender(ctx)), 
            player);
        transfer::public_transfer(owner_cap, tx_context::sender(ctx));
    } 

    public entry fun get_player_data(
        corbaGameFi: &mut CorbaGameFi, 
        ctx: &mut TxContext
    ) {
        let is_created = dof::exists_(
            &mut corbaGameFi.id, 
            object::id_from_address(tx_context::sender(ctx))
        );
        
        if(is_created) {
            let player_info = dof::borrow<ID, CorbaPlayer>(
                &mut corbaGameFi.id, 
                object::id_from_address(tx_context::sender(ctx))
            );
            event::emit(LoadPlayerEvent {
                id: object::uid_to_inner(&player_info.id),
                level: player_info.level,
                exp: player_info.exp,
                max_exp: player_info.max_exp,
                gold: player_info.gold,
                wood: player_info.wood,
                meat: player_info.meat
            });
        }else {
            new_player(corbaGameFi, ctx);
        }
    }

    public fun mint_hero(
        _type_hero: u16,
        _max_health: u16, 
        _damage: u16,
        _speed: u16,
        _exp: u16,
        _max_exp: u16,
        _name: String,
        _history: String,
        _url: Url,
        ctx: &mut TxContext 
    ): Hero {
        Hero {
            id: object::new(ctx),
            type_hero: _type_hero,
            health: _max_health,
            max_health: _max_health,
            damage: _damage,
            speed: _speed,
            level: 1,
            exp: 0,
            max_exp: _max_exp,
            location_x: 0,
            location_y: 0,
            name: _name,
            description: _history,
            url: _url
        }
    }

    public entry fun new_herro(
        _type_hero: u16,
        _max_health: u16, 
        _damage: u16,
        _speed: u16,
        _exp: u16,
        _max_exp: u16,
        _name: String,
        _description: String,
        _url: ascii::String,
        corbaGameFi: &mut CorbaGameFi,
        ctx: &mut TxContext 
    ) {
        let is_created = dof::exists_(
            &mut corbaGameFi.id, 
            object::id_from_address(tx_context::sender(ctx))
        );

        assert!(is_created, NOT_A_CORBA_PLAYER);
        let player_info = dof::borrow_mut<ID, CorbaPlayer>(
            &mut corbaGameFi.id, 
            object::id_from_address(tx_context::sender(ctx))
        ); 
        let mut hero_gold: u32 = 0;
        let mut hero_wood: u32 = 0;
        let mut hero_meat: u32 = 0;
        if(_type_hero == WARRIOR) {
            hero_gold = WARRIOR_GOLD;
            hero_meat = WARRIOR_MEAT;
            hero_wood = WARRIOR_WOOD;
        } else if(_type_hero == ACHER){
            hero_gold = ACHER_GOLD;
            hero_meat = ACHER_MEAT;
            hero_wood = ACHER_WOOD;
        } else if(_type_hero == PAWN) {
            hero_gold = PAWN_GOLD;
            hero_meat = PAWN_MEAT;
            hero_wood = PAWN_WOOD;
        } else {
            assert!(false, INVALID_HERO_TYPE);
        };
        assert!(
            player_info.meat >= hero_meat 
            && player_info.gold >= hero_gold 
            && player_info.wood >= hero_wood, 
            NOT_ENOUGH_RESOURCES);

        //update player resources
        player_info.meat = player_info.meat - hero_meat;
        player_info.gold = player_info.gold - hero_gold;
        player_info.wood = player_info.wood - hero_wood;
        let new_hero = mint_hero(
            _type_hero,
            _max_health,
            _damage,
            _speed,
            _exp,
            _max_exp,
            _name,
            _description,
            url::new_unsafe(_url),
            ctx
        );
        let copy_id = object::uid_to_inner(&new_hero.id);
        transfer::public_transfer(new_hero, tx_context::sender(ctx));
        // let mut transfer_policy = dof::borrow_mut(&mut corbaGameFi.id, string::utf8(b"transfer_policy"));
        // let mut request = policy::new_request<Hero>(copy_id, 1000000000, object::id_from_address(tx_context::sender(ctx)));
        // witness_rule::prove<Hero, Rule>(Rule{}, transfer_policy, &mut request);
        // transfer::public_transfer(request, tx_context::sender(ctx));

        event::emit(NewHeroEvent {
            id: copy_id,
            hero_id: copy_id,
            owner: tx_context::sender(ctx)
        });
    }

    public entry fun update_hero(
        _location_x: u16,
        _location_y: u16,
        _health: u16,
        _max_health: u16, 
        _damage: u16,
        _speed: u16,
        _level: u16,
        _exp: u16,
        _max_exp: u16,
        hero: &mut Hero, 
        ctx: &mut TxContext) 
    {
        hero.location_x = _location_x;
        hero.location_y = _location_y;
        hero.max_health = _max_health;
        hero.health = _health;
        hero.damage = _damage;
        hero.speed = _speed;
        hero.level = _level;
        hero.exp = _exp;
        hero.max_exp = _max_exp;
    }

    public entry fun update_player_resources(
        _gold: u32,
        _meat: u32,
        _wood: u32,
        corbaGameFi: &mut CorbaGameFi,
        ctx: &mut TxContext
    ) {
        let player = dof::borrow_mut<ID, CorbaPlayer>(
            &mut corbaGameFi.id, 
            object::id_from_address(tx_context::sender(ctx))
        );
        player.gold = _gold;
        player.meat = _meat;
        player.wood = _wood;
    }

    public entry fun update_player_level(
        _level: u16,
        _exp: u32,
        _max_exp: u32,
        corbaGameFi: &mut CorbaGameFi,
        ctx: &mut TxContext,
    ) {
        let player = dof::borrow_mut<ID, CorbaPlayer>(
            &mut corbaGameFi.id, 
            object::id_from_address(tx_context::sender(ctx))
        );
        player.level = _level;
        player.max_exp = _max_exp;
        player.exp = _exp;
    }

    public fun get_level(hero: &mut Hero): u16 {hero.level}

    public entry fun get_city_weather(city_id: u32, city_weather: &weather_oracle::WeatherOracle) {
        let city_weather = CityWeatherEvent {
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
    //  public fun mint_game(
    //     _version: String,
    //     _description: String,
    //     ctx: &mut TxContext)
    // : CorbaGameFi {
    //         CorbaGameFi {
    //             id: object::new(ctx),
    //             version: _version,
    //             description: _description
    //         }
    // }
    
    #[test_only]
    public fun mint_hero_for_test(
        _type_hero: u16,
        _max_health: u16, 
        _damage: u16,
        _speed: u16,
        _exp: u16,
        _max_exp: u16,
        _name: String,
        _description: String,
        _url: vector<u16>,
        ctx: &mut TxContext 
    ): Hero {
        mint_hero(
            _type_hero,
            _max_health,
            _damage,
            _speed,
            _exp,
            _max_exp,
            _name,
            _description,
            url::new_unsafe_from_bytes(_url),
            ctx
        )
    }

    
}

#[test_only]
module game::hero_for_test {
    use game::game::{Self, Hero, CorbaGameFi, CorbaPlayer};
    use sui::dynamic_object_field as dof;
    use sui::test_scenario as ts;
    use sui::transfer;
    use std::string;
    use std::ascii;
    const WARRIOR: u16 = 0;
    const ACHER: u16 = 1;
    const PAWN: u16 = 2;
    const LEVEL_NOT_VALID: u64 = 5;


    #[test]
    public fun mint_hero_test() {
        let add1 = @0xA;
        let add2 = @0xB;
        let mut scenario = ts::begin(add1);
        {

            
            let mut hero = game::mint_hero_for_test(
                PAWN,
                10,
                10,
                10,
                10,
                10,
                string::utf8(b"pawn pro"),
                string::utf8(b"pawn"),
                b"url",
                ts::ctx(&mut scenario),
            );
            transfer::public_transfer(hero, add1);
        };
        ts::next_tx(&mut scenario, add1);
        {
            let mut hero = ts::take_from_sender(&mut scenario);
            game::update_hero(1, 1, 9, 20, 11, 12, 3, 0, 100,  &mut hero, ts::ctx(&mut scenario));
            assert!(game::get_level(&mut hero) == 3, LEVEL_NOT_VALID);
            ts::return_to_sender(&mut scenario, hero);
        };
        ts::end(scenario);
    }

    #[test]
    public fun game_test() {
        let add1 = @0xA;
        let add2 = @0xB;
        let mut scenario = ts::begin(add1);
        {
        //     let corba_game = game::create_corba_game_test(
        //         string::utf8(b"1.0"), 
        //         string::utf8(b"corba gamefi"), 
        //         ts::ctx(&mut scenario)
        //     );
        //     transfer::share_object(corba_game);
        };
        ts::next_tx(&mut scenario, add1);
        {
            // let corbaGameFi = ts::take_from_sender(&mut scenario);
            // let player = CorbaPlayer{
            //     id: ts::ctx(&mut scenario), 
            //     level: 1, 
            //     exp: 0, 
            //     max_exp: 100, 
            //     gold: 0, 
            //     wood: 0, 
            //     meat: 0
            // };
            // dof::add(
            //     &mut corbaGameFi.id,
            //     object::id_from_address(add1), 
            //     player
            // );
        };
         ts::end(scenario);
    }

}

//sponsered fun: new_herro, get_player_data, upadte_hero, update_player_resources, update_player_level
//the rest funs ins normal call
//opackage 0x73725f6b1262eb85047e735921fea7621be5ac3e149cf66dbe8988e4d0bf9aa8
//suiver 0xe67586f62a2249e6b621cddae2c4a7088222801b0e54432dc26a2022054bea5a