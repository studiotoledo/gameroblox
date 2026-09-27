// Verifica a sintaxe de arquivos Luau compilando cada um com o compilador oficial do Luau.
// Uso: luaucheck arquivo1.luau arquivo2.luau ...
use mlua::{Lua, Compiler};
fn main() {
    let lua = Lua::new();
    let mut failed = false;
    for path in std::env::args().skip(1) {
        let src = std::fs::read_to_string(&path).unwrap();
        let bytecode = Compiler::new().compile(&src);
        match bytecode {
            Ok(b) => { if let Err(e) = lua.load(&b[..]).set_name(&path).into_function() { println!("{path}: {e}"); failed = true; } }
            Err(e) => { println!("{path}: {e}"); failed = true; }
        }
    }
    if failed { std::process::exit(1) } else { println!("OK") }
}
