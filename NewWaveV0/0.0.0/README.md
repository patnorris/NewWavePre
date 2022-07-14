# NewWaveV0
https://doc.rust-lang.org/book/ch03-03-how-functions-work.html
https://rustwasm.github.io/docs/book/game-of-life/introduction.html

https://rustwasm.github.io/docs/wasm-bindgen/
deploy:
https://github.com/dfinity/cdk-rs/tree/main/examples
game of life tutorial (link above)
3d graphics (video)
todo app (https://github.com/rustwasm/wasm-bindgen/tree/master/examples/todomvc)

implement "inheritance":
bottom: https://users.rust-lang.org/t/how-to-implement-inheritance-like-feature-for-rust/31159/21
base entity: https://abadcafe.wordpress.com/2021/01/08/behavior-inheritance-in-rust/

Trait Objects: https://doc.rust-lang.org/book/ch17-02-trait-objects.html#using-trait-objects-that-allow-for-values-of-different-types

## Running the project locally

If you want to test your project locally, you can use the following commands:

```bash
# Starts the replica, running in the background
dfx start --background

# Deploys your canisters to the replica and generates your candid interface
dfx deploy
```

Once the job completes, your application will be available at `http://localhost:8000?canisterId={asset_canister_id}`.

Additionally, if you are making frontend changes, you can start a development server with

```bash
npm start
```

Which will start a server at `http://localhost:8080`, proxying API requests to the replica at port 8000.

### Note on frontend environment variables

If you are hosting frontend code somewhere without using DFX, you may need to make one of the following adjustments to ensure your project does not fetch the root key in production:

- set`NODE_ENV` to `production` if you are using Webpack
- use your own preferred method to replace `process.env.NODE_ENV` in the autogenerated declarations
- Write your own `createActor` constructor


Cargo.toml:
wasm-bindgen = "0.2"
candid = "0.7.0"
uuid = { version = "0.8.2", features = ["v4", "stdweb", "serde"] }
getrandom = { version = "0.2", features = ["js"] }


lib.rs:
use candid::{check_prog, IDLProg, TypeEnv};
use wasm_bindgen::prelude::*;
use uuid::Uuid;

#[wasm_bindgen]
pub fn did_to_js(prog: String) -> Option<String> {
  let ast = prog.parse::<IDLProg>().ok()?;
  let mut env = TypeEnv::new();
  let actor = check_prog(&mut env, &ast).ok()?;
  Some(candid::bindings::javascript::compile(&env, &actor))
}

Testing:
dfx canister call NewWaveV0 createEntity '(record {internalId = ""; externalId = "www.webseite.com"; attachedBridgeIds = vec {}; name = "The Webseite"; description = "my webseite"; keywords = vec {"web3"}; entityType = "webpage" })'

dfx canister call NewWaveV0 getEntityByExternalId '("www.webseite.com")'

dfx canister call NewWaveV0 createEntity '(record {internalId = ""; externalId = "www.website.com"; attachedBridgeIds = vec {}; name = "The Website"; description = "my website"; keywords = vec {"web3"}; entityType = "webpage" })'

dfx canister call NewWaveV0 getEntityByExternalId '("www.website.com")'

dfx canister call NewWaveV0 createBridge '(record {internalId = ""; fromEntityId = "D389F09C87C0E7D7B692F20814DEDD1E5FDF6DA8D7B9CC1E1A0453A896655894"; toEntityId = "258E4D32F1DB62031FFD65A28A552969CE4B86E7E16D8F7E3D4F86E578231CAA"})'

dfx canister call NewWaveV0 getBridgeById '("5FECEB66FFC86F38D952786C6D696C79C2DBC239DD4E91B46729D73A27FB57E9")'

dfx canister call NewWaveV0 getBridgedEntitiesForEntityId '("258E4D32F1DB62031FFD65A28A552969CE4B86E7E16D8F7E3D4F86E578231CAA")'

dfx canister call NewWaveV0 createEntityAndBridge '("258E4D32F1DB62031FFD65A28A552969CE4B86E7E16D8F7E3D4F86E578231CAA", record {internalId = ""; externalId = "www.webpage.com"; attachedBridgeIds = vec {}; name = "The Webpage"; description = "my webpage"; keywords = vec {"web3"}; entityType = "webpage" })'