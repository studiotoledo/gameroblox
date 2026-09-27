// Executa um script Luau fora do Roblox. Expõe readfile(path) e loadsource(src, nome)
// para que o script consiga carregar outros módulos (veja tools/export_kaijus.luau).
use mlua::{Lua, Compiler, Function};
fn main() -> mlua::Result<()> {
    let lua = Lua::new();
    let g = lua.globals();
    g.set("readfile", lua.create_function(|_, p: String| Ok(std::fs::read_to_string(p).map_err(mlua::Error::external)?))?)?;
    let l2 = lua.clone();
    g.set("loadsource", lua.create_function(move |_, (src, name): (String, String)| {
        let b = Compiler::new().compile(&src).map_err(mlua::Error::external)?;
        let f: Function = l2.load(&b[..]).set_name(name).into_function()?;
        Ok(f)
    })?)?;
    let path = std::env::args().nth(1).expect("script");
    let src = std::fs::read_to_string(&path).unwrap();
    let b = Compiler::new().compile(&src).map_err(mlua::Error::external)?;
    lua.load(&b[..]).set_name(path).exec()
}
