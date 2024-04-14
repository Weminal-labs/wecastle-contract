
module game::kiosk_lock_rule {
    use sui::kiosk::{Self, Kiosk};
    use sui::transfer_policy::{
        Self as policy,
        TransferPolicy,
        TransferPolicyCap,
        TransferRequest
    };

    const ENotInKiosk: u64 = 0;

    public struct Rule has drop {}

    public struct Config has store, drop {}

    public fun add<T>(policy: &mut TransferPolicy<T>, cap: &TransferPolicyCap<T>) {
        policy::add_rule(Rule {}, policy, cap, Config {})
    }

    public fun prove<T>(request: &mut TransferRequest<T>, kiosk: &Kiosk) {
        let item = policy::item(request);
        assert!(kiosk::has_item(kiosk, item) && kiosk::is_locked(kiosk, item), ENotInKiosk);
        policy::add_receipt(Rule {}, request)
    }
}
